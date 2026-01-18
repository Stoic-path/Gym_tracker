$Cluster = "gym-tracker-cluster"
$ProjectName = "gym-tracker"

# Mapeo: Nombre del Servicio en ECS -> Sufijo del Repositorio en ECR
# Esto es necesario porque los nombres no son idénticos (ej: user-service vs user-profile-service)
$ServiceRepoMap = @{
    "gym-tracker-web-service"        = "web"
    "gym-tracker-auth-service"       = "auth-service"
    "gym-tracker-user-service"       = "user-profile-service"
    "gym-tracker-sync-service"       = "sync-service"
    "gym-tracker-work-cmd-service"   = "workout-command-service"
    "gym-tracker-work-qry-service"   = "workout-query-service"
    "gym-tracker-routine-service"    = "routine-service"
    "gym-tracker-exercise-service"   = "exercise-library-service"
    "gym-tracker-video-service"      = "video-service"
    "gym-tracker-notify-service"     = "notification-service"
    "gym-tracker-analytics-service"  = "analytics-service"
}

# Lista ordenada de servicios para iterar
$Services = @(
    "gym-tracker-web-service",
    "gym-tracker-auth-service",
    "gym-tracker-user-service",
    "gym-tracker-sync-service",
    "gym-tracker-work-cmd-service",
    "gym-tracker-work-qry-service",
    "gym-tracker-routine-service",
    "gym-tracker-exercise-service",
    "gym-tracker-video-service",
    "gym-tracker-notify-service",
    "gym-tracker-analytics-service"
)

Write-Host "--- VERIFICANDO ESTADO DE IMAGENES EN ECS ---" -ForegroundColor Cyan
Write-Host "Cluster: $Cluster" -ForegroundColor Gray

foreach ($Service in $Services) {
    # Verificar si tenemos mapeo para este servicio
    if (-not $ServiceRepoMap.ContainsKey($Service)) {
        Write-Host " -> $Service : SKIP (No mapeado)" -ForegroundColor Yellow
        continue
    }

    $RepoSuffix = $ServiceRepoMap[$Service]
    $RepoName = "$ProjectName/$RepoSuffix"

    Write-Host " -> $Service..." -NoNewline

    # 1. Obtener Digest de ECR (Imagen :dev)
    # Usamos 2>$null para silenciar errores de AWS CLI si fallan las credenciales o no existe el repo
    $EcrDigest = aws ecr describe-images --repository-name $RepoName --image-ids imageTag=dev --query 'imageDetails[0].imageDigest' --output text 2>$null
    
    if (-not $EcrDigest) {
        Write-Host " SKIP (No se encontró imagen :dev en ECR)" -ForegroundColor Yellow
        continue
    }

    # 2. Obtener Tareas Corriendo
    $TaskArnsJson = aws ecs list-tasks --cluster $Cluster --service-name $Service --desired-status RUNNING --query 'taskArns' --output json 2>$null
    
    # Convertir JSON a Array de PowerShell de forma segura
    $TaskArns = @()
    if ($TaskArnsJson -and $TaskArnsJson -ne "null") {
        $TaskArns = $TaskArnsJson | ConvertFrom-Json
    }

    # Caso A: Servicio detenido (0 tareas) -> Forzar inicio
    if (@($TaskArns).Count -eq 0) {
        Write-Host " UPDATE (Servicio detenido)" -ForegroundColor Magenta
        aws ecs update-service --cluster $Cluster --service $Service --force-new-deployment --no-cli-pager | Out-Null
        continue
    }

    # 3. Obtener Digest de la Tarea en Ejecución
    # Inspeccionamos la primera tarea encontrada
    $TaskArn = $TaskArns[0]
    $RunningDigest = aws ecs describe-tasks --cluster $Cluster --tasks $TaskArn --query 'tasks[0].containers[0].imageDigest' --output text 2>$null

    # 4. Comparar Digests (ECR vs Running)
    if ($EcrDigest -ne $RunningDigest) {
        Write-Host " UPDATE (Imagen desactualizada)" -ForegroundColor Green
        # Forzar despliegue para bajar la nueva imagen
        aws ecs update-service --cluster $Cluster --service $Service --force-new-deployment --no-cli-pager | Out-Null
    } else {
        Write-Host " OK (Actualizado)" -ForegroundColor Gray
    }
}

Write-Host "-----------------------------------------------------"
Write-Host "Chequeo finalizado." -ForegroundColor Cyan
