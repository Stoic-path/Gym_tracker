# deploy_routine_service.ps1
# Script especifico para construir, subir y desplegar el Routine Service

$ErrorActionPreference = "Stop"
$AWS_REGION = "us-east-1"
$RepoName = "gym-tracker/routine-service"
$ServiceName = "gym-tracker-routine-service"
$ClusterName = "gym-tracker-cluster"
$ImageTag = "dev"

# 1. Determinar la raiz del proyecto
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
$ServicePath = "$ProjectRoot\services\routine-service"

Write-Host "--- DESPLIEGUE DE ROUTINE SERVICE (PostgreSQL) ---" -ForegroundColor Cyan

# 2. Verificar Docker
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "Docker Desktop no esta corriendo."; exit 1 }

# 3. Autenticación ECR
Write-Host "1. Autenticando con ECR..." -ForegroundColor Yellow
try {
    $CallerIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    $AccountId = $CallerIdentity.Account
} catch { Write-Error "Ejecuta switch_account.ps1 primero."; exit 1 }

$EcrUrl = "$AccountId.dkr.ecr.$AWS_REGION.amazonaws.com"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $EcrUrl

# 4. Construir Imagen
Write-Host "2. Construyendo imagen Docker..." -ForegroundColor Yellow
docker build --no-cache -t "$RepoName`:$ImageTag" "$ServicePath"

# 5. Subir a ECR
Write-Host "3. Subiendo imagen a ECR..." -ForegroundColor Yellow
docker tag "$RepoName`:$ImageTag" "$EcrUrl/$RepoName`:$ImageTag"
docker push "$EcrUrl/$RepoName`:$ImageTag"

# 6. Forzar Despliegue en ECS
Write-Host "4. Forzando actualización en ECS Fargate..." -ForegroundColor Yellow
aws ecs update-service --cluster $ClusterName --service $ServiceName --force-new-deployment --no-cli-pager | Out-Null

Write-Host "-----------------------------------------------------" -ForegroundColor Green
Write-Host "DESPLIEGUE INICIADO." -ForegroundColor Green
Write-Host "El servicio aplicará migraciones automáticamente al iniciar." -ForegroundColor Gray