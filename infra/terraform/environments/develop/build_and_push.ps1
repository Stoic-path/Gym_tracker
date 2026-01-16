# Configuración
$AWS_REGION = "us-east-1"
$ProjectName = "gym-tracker"
$Version = "dev"

# Determinar la raiz del proyecto (4 niveles arriba: develop -> environments -> terraform -> infra -> root)
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

# Verificar si Docker esta corriendo antes de continuar
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR CRITICO: Docker Desktop no esta ejecutandose o no esta listo. Por favor inicialo y reintenta."
    exit 1
}

# Obtener Account ID y Login ECR
Write-Host "Obteniendo credenciales de ECR..." -ForegroundColor Cyan
$AccountId = aws sts get-caller-identity --query Account --output text
if (-not $AccountId) { Write-Error "No se pudo obtener el AWS Account ID. Ejecuta switch_account.ps1 primero."; exit }

$EcrUrl = "$AccountId.dkr.ecr.$AWS_REGION.amazonaws.com"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $EcrUrl

$RepoPrefix = "$EcrUrl/$ProjectName"

# Lista de microservicios (Nombres de carpetas en /services)
$BackendServices = @(
    "analytics-service",
    "auth-service",
    "exercise-library-service",
    "notification-service",
    "routine-service",
    "sync-service",
    "user-profile-service",
    "video-service",
    "workout-command-service",
    "workout-query-service"
)

# --- 1. CONSTRUIR Y SUBIR BACKEND ---
foreach ($Service in $BackendServices) {
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Procesando Backend: $Service" -ForegroundColor Yellow
    
    $ImageName = "$RepoPrefix/$Service`:$Version"
    $ImageNameLatest = "$RepoPrefix/$Service`:latest"
    $Path = "$ProjectRoot\services\$Service"

    # Build
    Write-Host "Construyendo imagen: $ImageName..."
    # Etiquetamos como :dev Y como :latest
    docker build -t $ImageName -t $ImageNameLatest $Path
    
    if ($LASTEXITCODE -eq 0) {
        # Push
        Write-Host "Subiendo imagen a ECR..."
        docker push $ImageName
        docker push $ImageNameLatest
    } else {
        Write-Host "ERROR: Falló el build de $Service" -ForegroundColor Red
        exit 1
    }
}

# --- 2. CONSTRUIR Y SUBIR FRONTEND (WEB) ---
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Procesando Frontend: Web" -ForegroundColor Yellow

$WebImageName = "$RepoPrefix/web:$Version"
$WebImageNameLatest = "$RepoPrefix/web:latest"
$WebPath = "$ProjectRoot\apps\web"

# Build Web
Write-Host "Construyendo imagen: $WebImageName..."
docker build -t $WebImageName -t $WebImageNameLatest $WebPath

if ($LASTEXITCODE -eq 0) {
    # Push Web
    Write-Host "Subiendo imagen a ECR..."
    docker push $WebImageName
    docker push $WebImageNameLatest
} else {
    Write-Host "ERROR: Falló el build del Frontend" -ForegroundColor Red
}

Write-Host "--------------------------------------------------" -ForegroundColor Green
Write-Host "¡Proceso finalizado! Verifica tus repositorios en DockerHub." -ForegroundColor Green