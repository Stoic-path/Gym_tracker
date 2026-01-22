# update_config.ps1
# Script para actualizar automáticamente la configuración de Apps (Web, Mobile, Desktop)
# con el DNS del ALB generado por Terraform.

$ErrorActionPreference = "Stop"

Write-Host "🔍 Obteniendo DNS del ALB desde Terraform..." -ForegroundColor Cyan

# 1. Obtener Output de Terraform
# Ajusta esta ruta si tu carpeta main.tf está en otro lado
$TerraformDir = "infra/terraform/environments/develop" 

if (-not (Test-Path $TerraformDir)) {
    Write-Error "❌ No se encuentra el directorio de Terraform: $TerraformDir"
}

Push-Location $TerraformDir
try {
    $AlbDns = terraform output -raw alb_dns_name
}
catch {
    Write-Warning "⚠️ No se pudo obtener el output. Asegúrate de haber hecho 'terraform apply' primero."
    Pop-Location
    exit 1
}
Pop-Location

if ([string]::IsNullOrWhiteSpace($AlbDns)) {
    Write-Error "❌ Terraform devolvió un DNS vacío."
}

$FullUrl = "http://$AlbDns"
Write-Host "✅ DNS encontrado: $FullUrl" -ForegroundColor Green

# ---------------------------------------------------------
# 2. Actualizar Mobile (.env)
# ---------------------------------------------------------
$MobileEnv = "apps/mobile/.env"
$MobileContent = "EXPO_PUBLIC_API_URL=$FullUrl"
Set-Content -Path $MobileEnv -Value $MobileContent
Write-Host "📱 Mobile actualizado: $MobileEnv"

# ---------------------------------------------------------
# 3. Actualizar Desktop (config.py)
# ---------------------------------------------------------
$DesktopConfig = "apps/desktop/config.py"
if (Test-Path $DesktopConfig) {
    $Content = Get-Content $DesktopConfig -Raw
    # Reemplaza la línea que empieza con API_BASE_URL = "..."
    $NewContent = $Content -replace 'API_BASE_URL = ".*"', "API_BASE_URL = ""$FullUrl"""
    Set-Content -Path $DesktopConfig -Value $NewContent
    Write-Host "💻 Desktop actualizado: $DesktopConfig"
} else {
    Write-Warning "⚠️ No se encontró $DesktopConfig"
}

# ---------------------------------------------------------
# 4. Actualizar Web (.env.production)
# ---------------------------------------------------------
$WebEnv = "apps/web/.env.production"
$WebContent = "VITE_API_URL=$FullUrl"
Set-Content -Path $WebEnv -Value $WebContent
Write-Host "🌐 Web actualizado: $WebEnv"

Write-Host "✨ ¡Configuración actualizada correctamente!" -ForegroundColor Green
Write-Host "⚠️ Nota: Para Web y Mobile, recuerda reconstruir (build) para que tomen los cambios." -ForegroundColor Yellow
