# verify_seed.ps1
$LogGroup = "/ecs/gym-tracker"
$Region = "us-east-1"
$ALB_DNS = "gym-tracker-alb-51009640.us-east-1.elb.amazonaws.com" # Tu DNS del output

Write-Host "--- 1. VERIFICANDO LOGS DE SEED ---" -ForegroundColor Cyan
# Buscamos la frase exacta que pusimos en el script seed_exercises.py
$Pattern = "poblada exitosamente"

try {
    # Filtramos los logs buscando el mensaje de éxito
    $Events = aws logs filter-log-events --log-group-name $LogGroup --filter-pattern $Pattern --region $Region --output json | ConvertFrom-Json
    
    if ($Events.events.Count -gt 0) {
        Write-Host "[OK] SEED CONFIRMADO: Se encontro el mensaje de exito en los logs." -ForegroundColor Green
        $LastEvent = $Events.events | Select-Object -Last 1
        Write-Host "   Mensaje: $($LastEvent.message.Trim())" -ForegroundColor Gray 
    } else {
        Write-Host "[WARN] NO SE ENCONTRO EL MENSAJE AUN." -ForegroundColor Yellow
        Write-Host "   El contenedor puede estar iniciando. Espera 1 minuto y reintenta."
    }
} catch {
    Write-Error "Error leyendo logs: $_"
}

Write-Host "`n--- 2. VERIFICANDO CONECTIVIDAD API ---" -ForegroundColor Cyan
try {
    # Hacemos una petición simple. Esperamos un 401 (Unauthorized) o 200.
    # Si da error de conexión, el servicio no está corriendo.
    $Uri = "http://$ALB_DNS/api/exercises/groups/"
    Write-Host "Peticion a: $Uri"
    
    try {
        $Response = Invoke-RestMethod -Uri $Uri -Method Get -ErrorAction Stop
        Write-Host "[OK] API RESPONDIO 200 OK (Publica)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq "Unauthorized") {
            Write-Host "[OK] API RESPONDIO 401 UNAUTHORIZED" -ForegroundColor Green
            Write-Host "   (Esto es correcto, el servicio esta vivo y protegido)" -ForegroundColor Gray
        } else {
            Write-Host "[ERROR] ERROR INESPERADO: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Error de conexion con el ALB: $_"
}
