# switch_account_v3.ps1
Clear-Host
Write-Host "--- PROTOCOLO DE MIGRACION DE CUENTA AWS (V3 - FULL AUTO) ---" -ForegroundColor Cyan

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

# 3. Actualizar GitHub Secrets (¡LA MAGIA!) 
Write-Host "-----------------------------------------------------"
Write-Host " Actualizando secretos en aws configure .." -ForegroundColor Yellow

# Usamos --clobber para sobrescribir sin preguntar
gh secret set AWS_ACCESS_KEY_ID --body "$AccessKey" --clobber
gh secret set AWS_SECRET_ACCESS_KEY --body "$SecretKey" --clobber
gh secret set AWS_SESSION_TOKEN --body "$SessionToken" --clobber

Write-Host " Secretos de GitHub actualizados." -ForegroundColor Green
Write-Host "-----------------------------------------------------"

# 4. Borrar Estado Anterior de Terraform
Write-Host " Limpiando estado corrupto de Terraform..."
if (Test-Path .terraform) { Remove-Item -Recurse -Force .terraform }
if (Test-Path .terraform.lock.hcl) { Remove-Item -Force .terraform.lock.hcl }
if (Test-Path terraform.tfstate) { Remove-Item -Force terraform.tfstate }
if (Test-Path terraform.tfstate.backup) { Remove-Item -Force terraform.tfstate.backup }

# 5. Terraform Init y Apply
Write-Host " Ejecutando Terraform Init..."
terraform init

Write-Host " Ejecutando Terraform Apply..."
terraform apply -auto-approve -input=false

Write-Host "-----------------------------------------------------"
Write-Host " TODO LISTO: Infraestructura creada." -ForegroundColor Green
Write-Host " NUEVO DNS:" -ForegroundColor Yellow
terraform output alb_dns_name
Write-Host "-----------------------------------------------------"
Write-Host " TIP: Ahora  ve a GitHub y actualiza los secrets en el repo de la aplicacion." -ForegroundColor Cyan