# Configuración
$DockerUser = "stoicpath"
$Version = "latest"

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
    
    $ImageName = "$DockerUser/$Service`:$Version"
    $Path = ".\services\$Service"

    # Build
    Write-Host "Construyendo imagen: $ImageName..."
    docker build -t $ImageName $Path
    
    if ($LASTEXITCODE -eq 0) {
        # Push
        Write-Host "Subiendo imagen a DockerHub..."
        docker push $ImageName
    } else {
        Write-Host "ERROR: Falló el build de $Service" -ForegroundColor Red
        exit 1
    }
}

# --- 2. CONSTRUIR Y SUBIR FRONTEND (WEB) ---
Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Procesando Frontend: Web" -ForegroundColor Yellow

$WebImageName = "$DockerUser/web:$Version"
$WebPath = ".\apps\web"

# Build Web
Write-Host "Construyendo imagen: $WebImageName..."
docker build -t $WebImageName $WebPath

if ($LASTEXITCODE -eq 0) {
    # Push Web
    Write-Host "Subiendo imagen a DockerHub..."
    docker push $WebImageName
} else {
    Write-Host "ERROR: Falló el build del Frontend" -ForegroundColor Red
}

Write-Host "--------------------------------------------------" -ForegroundColor Green
Write-Host "¡Proceso finalizado! Verifica tus repositorios en DockerHub." -ForegroundColor Green