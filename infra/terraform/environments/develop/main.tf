# --- 1. NETWORKING (RED) ---

# VPC Principal
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- SUBNETS ---

# Subnet Pública 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1"
  }
}

# Subnet Pública 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-2"
  }
}

# Subnet Privada (Microservicios y DBs - Sin acceso directo a Internet)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-private-1"
  }
}

# --- NAT GATEWAY ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- TABLAS DE RUTAS ---

# Ruta Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Ruta Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

# --- SECURITY GROUPS ---

# 1. ALB SG
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from Internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 1.5 Bastion SG
resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security Group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. App SG
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security Group for Microservices"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Permitir SSH desde Bastion
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Database SG
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group for Databases"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  # Permitir SSH desde Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Permitir conexión directa a Postgres desde Bastion (para depuración)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Permitir conexión directa a Mongo desde Bastion (para depuración)
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Permitir conexión directa a Redis desde Bastion (para depuración)
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # --- 1. Herramientas Base ---
    curl -L --output cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
    yum localinstall -y cloudflared.rpm

    # --- 2. Instalar Clientes de Base de Datos ---
    # PostgreSQL Client
    dnf install -y postgresql15
    
    # Redis Client
    dnf install -y redis6
    if ! command -v redis-cli &> /dev/null && command -v redis6-cli &> /dev/null; then
        ln -s /usr/bin/redis6-cli /usr/bin/redis-cli
    fi
    
    # MongoDB Client (Mongosh)
    echo "[mongodb-org-7.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc" | tee /etc/yum.repos.d/mongodb-org-7.0.repo
    dnf install -y mongodb-mongosh

    # --- 3. Generar Script de Verificación Automática ---
    # Terraform reemplazará las variables con las IPs reales al crear la instancia
    cat <<'SCRIPT' > /home/ec2-user/verify_dbs.sh
    #!/bin/bash
    echo "🐘 [PostgreSQL] Diagnóstico de Tablas (Auth DB)..."
    # Listar tablas para verificar si las migraciones corrieron
    PGPASSWORD='gym_password_123' psql -h ${aws_instance.postgres.private_ip} -U gym_user -d auth_db -c "\dt"
    
    echo "🔍 [PostgreSQL] Verificando tablas públicas..."
    PGPASSWORD='gym_password_123' psql -h ${aws_instance.postgres.private_ip} -U gym_user -d auth_db -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';"

    echo -e "\n👤 [PostgreSQL] Diagnóstico de Tablas (User Profile DB)..."
    PGPASSWORD='gym_password_123' psql -h ${aws_instance.postgres.private_ip} -U gym_user -d user_profile_db -c "\dt" || echo "⚠️ No se pudo conectar a user_profile_db"

    echo -e "\n📊 [PostgreSQL] Diagnóstico de Tablas (Analytics DB)..."
    PGPASSWORD='gym_password_123' psql -h ${aws_instance.postgres.private_ip} -U gym_user -d analytics_db -c "\dt" || echo "⚠️ No se pudo conectar a analytics_db"

    echo -e "\n🍃 [MongoDB] Verificando Workouts..."
    mongosh "mongodb://${aws_instance.mongo.private_ip}:27017/workout_query_db" --quiet --eval "print('Total Docs: ' + db.workouts.countDocuments({}));"

    echo -e "\n🔴 [Redis] Verificando Cache..."
    redis-cli -h ${aws_instance.redis.private_ip} -p 6379 PING
    SCRIPT
    
    chmod +x /home/ec2-user/verify_dbs.sh
    chown ec2-user:ec2-user /home/ec2-user/verify_dbs.sh
  EOF

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

resource "aws_instance" "postgres" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name
  user_data              = file("../../scripts/setup_postgres.sh")

  tags = {
    Name = "${var.project_name}-db-postgres"
  }
}

resource "aws_instance" "mongo" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name
  user_data              = file("../../scripts/setup_mongo.sh")

  tags = {
    Name = "${var.project_name}-db-mongo"
  }
}

resource "aws_instance" "redis" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name
  user_data              = file("../../scripts/setup_redis.sh")

  tags = {
    Name = "${var.project_name}-db-redis"
  }
}

# --- 3. LOAD BALANCING (ALB - API GATEWAY) ---
# Implementacion de API Gateway nativo usando ALB con Path-Based Routing.
# Enruta trafico de frontend y microservicios sin servidores intermedios.

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# --- TARGET GROUPS ---

resource "aws_lb_target_group" "web" {
  name     = "tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip" # Requerido para Fargate
  
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "access_tgs" {
  for_each = var.tg_access_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip" # Requerido para Fargate
  health_check {
    path    = "/"
    matcher = "200-499"
    timeout  = 10
    interval = 60
  }
}

resource "aws_lb_target_group" "core_tgs" {
  for_each = var.tg_core_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip" # Requerido para Fargate
  health_check {
    path    = "/"
    matcher = "200-499"
    timeout  = 10
    interval = 60
  }
}

resource "aws_lb_target_group" "heavy_tgs" {
  for_each = var.tg_heavy_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip" # Requerido para Fargate
  health_check {
    path    = "/"
    matcher = "200-499"
    timeout  = 10
    interval = 60
  }
}

# --- LISTENER RULES (Path-Based Routing) ---
# Enrutamiento basado en URL para dirigir peticiones a los microservicios correctos.

resource "aws_lb_listener_rule" "auth_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.access_tgs["auth"].arn
  }
  condition {
    path_pattern {
      values = ["/api/auth*"]
    }
  }
}

resource "aws_lb_listener_rule" "user_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.access_tgs["user"].arn
  }
  condition {
    path_pattern {
      values = ["/api/users*"]
    }
  }
}

resource "aws_lb_listener_rule" "work_cmd_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_tgs["work-cmd"].arn
  }
  condition {
    path_pattern {
      values = ["/api/workouts/command*"]
    }
  }
}

resource "aws_lb_listener_rule" "work_qry_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_tgs["work-qry"].arn
  }
  condition {
    path_pattern {
      values = ["/api/workouts/query*"]
    }
  }
}

resource "aws_lb_listener_rule" "exercise_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_tgs["exercise"].arn
  }
  condition {
    path_pattern {
      values = ["/api/exercises*"]
    }
  }
}

resource "aws_lb_listener_rule" "routine_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 60
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_tgs["routine"].arn
  }
  condition {
    path_pattern {
      values = ["/api/routines*"]
    }
  }
}

resource "aws_lb_listener_rule" "analytics_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 70
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.heavy_tgs["analytics"].arn
  }
  condition {
    path_pattern {
      values = ["/api/analytics*"]
    }
  }
}

resource "aws_lb_listener_rule" "notify_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 80
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.heavy_tgs["notify"].arn
  }
  condition {
    path_pattern {
      values = ["/api/notifications*"]
    }
  }
}

resource "aws_lb_listener_rule" "video_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 90
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.heavy_tgs["video"].arn
  }
  condition {
    path_pattern {
      values = ["/api/videos*"]
    }
  }
}

resource "aws_lb_listener_rule" "sync_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.access_tgs["sync"].arn
  }
  condition {
    path_pattern {
      values = ["/api/sync*"]
    }
  }
}

# --- 3.6 ECR REPOSITORIES (PRIVATE) ---
# Aquí se subirán tus imágenes Docker en lugar de Docker Hub
resource "aws_ecr_repository" "repos" {
  for_each = toset([
    "web", "auth-service", "user-profile-service", "sync-service",
    "workout-command-service", "workout-query-service", "routine-service",
    "exercise-library-service", "analytics-service", "notification-service", "video-service"
  ])
  
  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Permite destruir el repo aunque tenga imágenes (útil en labs)

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- 3.7 ECS CLUSTER ---
# El cerebro que orquestará tus contenedores
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 1 # Ahorro de costos en Academy
}

# --- 4. ECS TASKS & SERVICES (FARGATE) ---

# --- 4.1 FRONTEND ---
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project_name}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = "${aws_ecr_repository.repos["web"].repository_url}:dev"
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "web"
      }
    }
  }])
}

resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = [aws_subnet.private_1.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

# --- 4.2 ACCESS GROUP (Auth, User, Sync) ---
# Separamos los servicios para evitar que el fallo de uno reinicie a los demás.

# --- Auth Service ---
resource "aws_ecs_task_definition" "auth" {
  family                   = "${var.project_name}-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "auth"
    image     = "${aws_ecr_repository.repos["auth-service"].repository_url}:dev"
    essential = true
    command   = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.postgres.private_ip}\", 5432)) != 0]' && python manage.py migrate && python init_user.py && python seed_data.py && python manage.py runserver 0.0.0.0:8001"]
    portMappings = [{ containerPort = 8001 }]
    environment = [
      { name = "DATABASE_URL", value = "postgresql://gym_user:gym_password_123@${aws_instance.postgres.private_ip}:5432/auth_db" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip },
      { name = "REDIS_PORT", value = "6379" }
    ]
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "auth" } }
  }])
}

resource "aws_ecs_service" "auth" {
  name            = "${var.project_name}-auth-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["auth"].arn
    container_name   = "auth"
    container_port   = 8001
  }

  depends_on = [aws_lb_listener.http]
}

# --- User Profile Service ---
resource "aws_ecs_task_definition" "user" {
  family                   = "${var.project_name}-user"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "user"
    image     = "${aws_ecr_repository.repos["user-profile-service"].repository_url}:dev"
    essential = true
    command   = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.postgres.private_ip}\", 5432)) != 0]' && python manage.py migrate && (python manage.py seed_profiles || true) && python manage.py runserver 0.0.0.0:8002"]
    portMappings = [{ containerPort = 8002 }]
    environment = [{ name = "DATABASE_URL", value = "postgresql://gym_user:gym_password_123@${aws_instance.postgres.private_ip}:5432/user_profile_db" }]
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "user" } }
  }])
}

resource "aws_ecs_service" "user" {
  name            = "${var.project_name}-user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["user"].arn
    container_name   = "user"
    container_port   = 8002
  }

  depends_on = [aws_lb_listener.http]
}

# --- Sync Service ---
resource "aws_ecs_task_definition" "sync" {
  family                   = "${var.project_name}-sync"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "sync"
    image     = "${aws_ecr_repository.repos["sync-service"].repository_url}:dev"
    essential = true
    command   = ["python", "manage.py", "runserver", "0.0.0.0:8009"]
    portMappings = [{ containerPort = 8009 }]
    environment = [{ name = "REDIS_HOST", value = aws_instance.redis.private_ip }, { name = "REDIS_PORT", value = "6379" }]
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "sync" } }
  }])
}

resource "aws_ecs_service" "sync" {
  name            = "${var.project_name}-sync-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sync.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["sync"].arn
    container_name   = "sync"
    container_port   = 8009
  }

  depends_on = [aws_lb_listener.http]
}

# --- 4.3 CORE GROUP (Cmd, Qry, Routine, Exercise) ---

# --- Workout Command ---
resource "aws_ecs_task_definition" "work_cmd" {
  family                   = "${var.project_name}-work-cmd"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "work-cmd", image = "${aws_ecr_repository.repos["workout-command-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.mongo.private_ip}\", 27017)) != 0]' && python manage.py migrate && python manage.py runserver 0.0.0.0:8003"], portMappings = [{ containerPort = 8003 }],
    environment = [
      { name = "MONGO_HOST", value = aws_instance.mongo.private_ip },
      { name = "MONGO_PORT", value = "27017" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip },
      { name = "REDIS_PORT", value = "6379" }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "work-cmd" } }
  }])
}

resource "aws_ecs_service" "work_cmd" {
  name            = "${var.project_name}-work-cmd-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.work_cmd.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["work-cmd"].arn
    container_name   = "work-cmd"
    container_port   = 8003
  }

  depends_on = [aws_lb_listener.http]
}

# --- Workout Query ---
resource "aws_ecs_task_definition" "work_qry" {
  family                   = "${var.project_name}-work-qry"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "work-qry", image = "${aws_ecr_repository.repos["workout-query-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python manage.py migrate && python manage.py seed_mongo && python manage.py runserver 0.0.0.0:8004"], portMappings = [{ containerPort = 8004 }],
    environment = [
      { name = "MONGO_HOST", value = aws_instance.mongo.private_ip },
      { name = "MONGO_PORT", value = "27017" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip },
      { name = "REDIS_PORT", value = "6379" }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "work-qry" } }
  }])
}

resource "aws_ecs_service" "work_qry" {
  name            = "${var.project_name}-work-qry-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.work_qry.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["work-qry"].arn
    container_name   = "work-qry"
    container_port   = 8004
  }

  depends_on = [aws_lb_listener.http]
}

# --- Routine ---
resource "aws_ecs_task_definition" "routine" {
  family                   = "${var.project_name}-routine"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "routine", image = "${aws_ecr_repository.repos["routine-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.postgres.private_ip}\", 5432)) != 0]' && python manage.py migrate && python manage.py runserver 0.0.0.0:8005"], portMappings = [{ containerPort = 8005 }],
    environment = [
      { name = "DATABASE_URL", value = "postgresql://gym_user:gym_password_123@${aws_instance.postgres.private_ip}:5432/routine_db" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "routine" } }
  }])
}

resource "aws_ecs_service" "routine" {
  name            = "${var.project_name}-routine-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.routine.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["routine"].arn
    container_name   = "routine"
    container_port   = 8005
  }

  depends_on = [aws_lb_listener.http]
}

# --- Exercise Library ---
resource "aws_ecs_task_definition" "exercise" {
  family                   = "${var.project_name}-exercise"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "exercise", image = "${aws_ecr_repository.repos["exercise-library-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8006"], portMappings = [{ containerPort = 8006 }],
    environment = [
      { name = "MONGO_HOST", value = aws_instance.mongo.private_ip },
      { name = "MONGO_PORT", value = "27017" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip },
      { name = "REDIS_PORT", value = "6379" }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "exercise" } }
  }])
}

resource "aws_ecs_service" "exercise" {
  name            = "${var.project_name}-exercise-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.exercise.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["exercise"].arn
    container_name   = "exercise"
    container_port   = 8006
  }

  depends_on = [aws_lb_listener.http]
}

# --- 4.4 HEAVY GROUP (Video, Notify, Analytics) ---

# --- Video ---
resource "aws_ecs_task_definition" "video" {
  family                   = "${var.project_name}-video"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "video", image = "${aws_ecr_repository.repos["video-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8007"], portMappings = [{ containerPort = 8007 }],
    environment = [
      { name = "MONGO_HOST", value = aws_instance.mongo.private_ip },
      { name = "MONGO_PORT", value = "27017" },
      { name = "REDIS_HOST", value = aws_instance.redis.private_ip },
      { name = "REDIS_PORT", value = "6379" }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "video" } }
  }])
}

resource "aws_ecs_service" "video" {
  name            = "${var.project_name}-video-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.video.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["video"].arn
    container_name   = "video"
    container_port   = 8007
  }

  depends_on = [aws_lb_listener.http]
}

# --- Notify ---
resource "aws_ecs_task_definition" "notify" {
  family                   = "${var.project_name}-notify"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "notify", image = "${aws_ecr_repository.repos["notification-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python manage.py migrate && python seed_data.py && python manage.py runserver 0.0.0.0:8008"], portMappings = [{ containerPort = 8008 }],
    environment = [{ name = "REDIS_HOST", value = aws_instance.redis.private_ip }, { name = "REDIS_PORT", value = "6379" }],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "notify" } }
  }])
}

resource "aws_ecs_service" "notify" {
  name            = "${var.project_name}-notify-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notify.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["notify"].arn
    container_name   = "notify"
    container_port   = 8008
  }

  depends_on = [aws_lb_listener.http]
}

# --- Analytics ---
resource "aws_ecs_task_definition" "analytics" {
  family                   = "${var.project_name}-analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "analytics", image = "${aws_ecr_repository.repos["analytics-service"].repository_url}:dev", essential = true,
    command = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.postgres.private_ip}\", 5432)) != 0]' && python manage.py makemigrations analytics && python manage.py migrate && (python manage.py seed_analytics || true) && python manage.py runserver 0.0.0.0:8010"], portMappings = [{ containerPort = 8010 }],
    environment = [{ name = "DATABASE_URL", value = "postgresql://gym_user:gym_password_123@${aws_instance.postgres.private_ip}:5432/analytics_db" }],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "analytics" } }
  }])
}

resource "aws_ecs_service" "analytics" {
  name            = "${var.project_name}-analytics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["analytics"].arn
    container_name   = "analytics"
    container_port   = 8010
  }

  depends_on = [aws_lb_listener.http]
}


# --- OUTPUTS ---

output "alb_dns_name" {
  description = "DNS Publico del Load Balancer"
  value       = aws_lb.main.dns_name
}

output "database_ips" {
  description = "IPs Privadas de las Bases de Datos"
  value = {
    postgres = aws_instance.postgres.private_ip
    mongo    = aws_instance.mongo.private_ip
    redis    = aws_instance.redis.private_ip
  }
}

output "bastion_public_ip" {
  description = "IP Publica del Bastion Host"
  value       = aws_instance.bastion.public_ip
}