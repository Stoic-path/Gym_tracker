# connect_ssh.ps1
# Script para conectar automaticamente a la instancia frontend

param (
    [string]$KeyFile = "labsuser.pem", # Nombre por defecto en AWS Academy
    [string]$User = "ec2-user",        # Usuario por defecto en Amazon Linux
    [string]$InstanceName = "gym-tracker-bastion"
)

$ErrorActionPreference = "Stop"

Write-Host "--- CONECTANDO A $InstanceName ---" -ForegroundColor Cyan

# 1. Obtener Informacion de la instancia
Write-Host "Buscando instancia..."
try {
    $JsonResult = aws ec2 describe-instances `
        --filters "Name=tag:Name,Values=$InstanceName" "Name=instance-state-name,Values=running,pending" `
        --query "Reservations[*].Instances[*].{Id:InstanceId, PublicIp:PublicIpAddress, State:State.Name}" `
        --output json
    
    if ([string]::IsNullOrWhiteSpace($JsonResult) -or $JsonResult -eq "[]") {
        $Instances = @()
    } else {
        $Instances = $JsonResult | ConvertFrom-Json
        if ($Instances -isnot [Array]) { $Instances = @($Instances) }
    }
}
catch {
    Write-Error "Error al ejecutar AWS CLI. Asegurate de haber ejecutado switch_account.ps1 primero."
    exit
}

if ($Instances.Count -eq 0) {
    Write-Error "No se encontro ninguna instancia con el nombre '$InstanceName' (running o pending)."
    exit
}

$Instance = $Instances[0]
$IpAddress = $Instance.PublicIp

if ([string]::IsNullOrWhiteSpace($IpAddress)) {
    Write-Error "La instancia $($Instance.Id) existe pero NO tiene IP Publica."
    Write-Host "CAUSA: Probablemente es una instancia antigua en la subnet privada." -ForegroundColor Yellow
    Write-Host "SOLUCION: Ejecuta: aws ec2 terminate-instances --instance-ids $($Instance.Id)" -ForegroundColor White
    exit
}

Write-Host "Instancia encontrada: $IpAddress ($($Instance.Id))" -ForegroundColor Green
Write-Host "Ejecutando SSH..." -ForegroundColor Yellow

# 2. Ejecutar SSH
# Nota: Asegurate de que el archivo .pem este en esta carpeta o pasa la ruta completa
if (-not (Test-Path $KeyFile)) {
    Write-Warning "El archivo '$KeyFile' no existe en el directorio actual."
    Write-Warning "Por favor descarga tu llave de AWS Academy y guardala aqui."
}

ssh -i "$KeyFile" -o StrictHostKeyChecking=no "$User@$IpAddress"