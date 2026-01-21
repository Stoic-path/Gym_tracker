# switch_account_v3.ps1
Clear-Host
Write-Host "--- PROTOCOLO DE MIGRACION DE CUENTA AWS (PRODUCTION/MAIN) ---" -ForegroundColor Cyan

# 1. Solicitar Credenciales
$AccessKey = Read-Host "Paso 1: Pega tu nuevo AWS_ACCESS_KEY_ID"
$SecretKey = Read-Host "Paso 2: Pega tu nuevo AWS_SECRET_ACCESS_KEY"
$SessionToken = Read-Host "Paso 3: Pega tu nuevo AWS_SESSION_TOKEN"

if ([string]::IsNullOrWhiteSpace($AccessKey) -or [string]::IsNullOrWhiteSpace($SessionToken)) {
    Write-Error "ERROR: Faltan credenciales."
    exit
}

# 2. Configurar Entorno Local (Para Terraform)
$env:AWS_ACCESS_KEY_ID = $AccessKey
$env:AWS_SECRET_ACCESS_KEY = $SecretKey
$env:AWS_SESSION_TOKEN = $SessionToken
$env:AWS_DEFAULT_REGION = "us-east-1"

Write-Host "-----------------------------------------------------"
Write-Host " Actualizando secretos en aws configure .." -ForegroundColor Yellow
aws configure set aws_access_key_id $AccessKey
aws configure set aws_secret_access_key $SecretKey
aws configure set aws_session_token $SessionToken
aws configure set default.region "us-east-1"

# 4. Borrar Estado Anterior de Terraform
Write-Host " Limpiando estado corrupto de Terraform en Main..."
if (Test-Path .terraform) { Remove-Item -Recurse -Force .terraform }
if (Test-Path .terraform.lock.hcl) { Remove-Item -Force .terraform.lock.hcl }
if (Test-Path terraform.tfstate) { Remove-Item -Force terraform.tfstate }
if (Test-Path terraform.tfstate.backup) { Remove-Item -Force terraform.tfstate.backup }

# 5. Terraform Init y Apply
Write-Host " Ejecutando Terraform Init..." -ForegroundColor Blue
terraform init

Write-Host " Ejecutando Terraform Apply..." -ForegroundColor Purple
terraform apply -auto-approve -input=false

Write-Host "-----------------------------------------------------"
Write-Host " TODO LISTO: Infraestructura creada." -ForegroundColor Green
Write-Host " NUEVO DNS:" -ForegroundColor Yellow
terraform output alb_dns_name
Write-Host "-----------------------------------------------------"
Write-Host " TIP:   En caso de ser necesario, actualiza los secrets en el repo de la aplicacion en GitHub." -ForegroundColor Cyan

Write-Host "-----------------------------------------------------"
Write-Host " ATENCION: Al ser una cuenta nueva, los repositorios ECR estan VACIOS." -ForegroundColor Red
$Build = Read-Host " Deseas construir y subir las imagenes Docker ahora? (S/N)"
if ($Build -eq "S" -or $Build -eq "s") {
    & "$PSScriptRoot\build_and_push.ps1"
}