# deploy_exercise_service.ps1
# Script especifico para construir, subir y desplegar el Exercise Service con Seed

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"
$RepoName = "gym-tracker/exercise-library-service"
$ImageTag = "dev"

# 1. Determinar la raiz del proyecto (4 niveles arriba desde este script)
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
$ServicePath = "$ProjectRoot\services\exercise-library-service"

Write-Host "--- DESPLIEGUE DE EXERCISE SERVICE (CON SEED) ---" -ForegroundColor Cyan

# 2. Verificar Docker
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker Desktop no esta corriendo."
    exit 1
}

# 3. Obtener Account ID y Login ECR
Write-Host "1. Autenticando con ECR..." -ForegroundColor Yellow
try {
    $CallerIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    $AccountId = $CallerIdentity.Account
} catch {
    Write-Error "No se pudo obtener la identidad de AWS. Ejecuta switch_account.ps1 primero."
    exit 1
}

$EcrUrl = "$AccountId.dkr.ecr.$AWS_REGION.amazonaws.com"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $EcrUrl

# 4. Construir Imagen
Write-Host "2. Construyendo imagen Docker..." -ForegroundColor Yellow
Write-Host "   Contexto: $ServicePath"
docker build --no-cache -t "$RepoName`:$ImageTag" -f "$ServicePath\Dockerfile" "$ServicePath"

# 5. Etiquetar y Subir
Write-Host "3. Subiendo imagen a ECR..." -ForegroundColor Yellow
docker tag "$RepoName`:$ImageTag" "$EcrUrl/$RepoName`:$ImageTag"
docker push "$EcrUrl/$RepoName`:$ImageTag"

# 6. Aplicar Terraform (Esto fuerza la actualizacion de la tarea en ECS)
Write-Host "4. Aplicando cambios en Terraform..." -ForegroundColor Yellow
# Nos aseguramos de estar en el directorio del script para correr terraform
Set-Location $PSScriptRoot
terraform apply -auto-approve

# 7. FORZAR NUEVO DESPLIEGUE (Crucial cuando Terraform no detecta cambios en código)
Write-Host "5. Forzando reinicio de tareas en ECS..." -ForegroundColor Yellow
aws ecs update-service --cluster "gym-tracker-cluster" --service "gym-tracker-exercise-service" --force-new-deployment --no-cli-pager | Out-Null

Write-Host "-----------------------------------------------------" -ForegroundColor Green
Write-Host "DESPLIEGUE FINALIZADO. El servicio se reiniciara y ejecutara el seed." -ForegroundColor Green