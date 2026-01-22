# --- 1. NETWORKING (RED) ---

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.project_name}-igw" }
}

# --- SUBNETS ---
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-2" }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.project_name}-private-1" }
}

# --- NAT GATEWAY ---
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags = { Name = "${var.project_name}-nat" }
  depends_on = [aws_internet_gateway.igw]
}

# --- ROUTING ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

# --- SECURITY GROUPS ---

# 1. ALB (Internet -> ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
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

# 2. Bastion
resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
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

# 3. ECS Apps (ALB -> Apps)
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Database Central (Apps -> DB)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  vpc_id      = aws_vpc.main.id
  # Apps access
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  # Bastion access
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  # Auto-referencia para comunicación entre contenedores si usan red host (no en este caso, pero buena practica)
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

# --- INSTANCES ---

# 1. Single Database Server (DOCKERIZED) - REEMPLAZA A LAS 3 INSTANCIAS ANTIGUAS
resource "aws_instance" "database_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1
  instance_type = "t3.medium"             # Necesario para Docker + 3 DBs
  key_name      = var.key_name
  subnet_id     = aws_subnet.public_1.id # Publica para bajar imagenes
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose postgresql-client-common postgresql-client-14
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # Crear red docker
    docker network create gym-network

    # 1. REDIS
    docker run -d --name redis-cache --network gym-network -p 6379:6379 redis:7-alpine

    # 2. MONGO
    docker run -d --name mongo-db --network gym-network -p 27017:27017 mongo:6.0

    # 3. POSTGRES (Con truco para multi-db)
    # Creamos un script SQL de inicio en el host
    mkdir -p /home/ubuntu/pg-init
    cat <<EOSS > /home/ubuntu/pg-init/init_dbs.sql
      CREATE DATABASE auth_db;
      CREATE DATABASE user_profile_db;
      CREATE DATABASE routine_db;
      CREATE DATABASE analytics_db;
      GRANT ALL PRIVILEGES ON DATABASE auth_db TO admin;
      GRANT ALL PRIVILEGES ON DATABASE user_profile_db TO admin;
      GRANT ALL PRIVILEGES ON DATABASE routine_db TO admin;
      GRANT ALL PRIVILEGES ON DATABASE analytics_db TO admin;
    EOSS

    docker run -d \
      --name postgres-db \
      --network gym-network \
      -p 5432:5432 \
      -e POSTGRES_USER=admin \
      -e POSTGRES_PASSWORD=adminpassword \
      -e POSTGRES_DB=gym_tracker_db \
      -v /home/ubuntu/pg-init:/docker-entrypoint-initdb.d \
      postgres:15-alpine

    # Esperar a que arranque para debug logs
    sleep 20
  EOF

  tags = { Name = "${var.project_name}-db-server-docker" }
}

# 2. Bastion Host
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  
  tags = { Name = "${var.project_name}-bastion" }
}

# --- STORAGE ---
resource "random_id" "bucket_suffix" { byte_length = 4 }
resource "aws_s3_bucket" "videos" {
  bucket        = "${var.project_name}-videos-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = { Name = "${var.project_name}-videos" }
}
resource "aws_s3_bucket_cors_configuration" "videos" {
  bucket = aws_s3_bucket.videos.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# --- ALB & TARGET GROUPS ---
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

resource "aws_lb_target_group" "web" {
  name     = "tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

# Dynamic Target Groups
resource "aws_lb_target_group" "access_tgs" {
  for_each = var.tg_access_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path     = "/"
    matcher  = "200-499"
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
  target_type = "ip"
  health_check {
    path     = "/"
    matcher  = "200-499"
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
  target_type = "ip"
  health_check {
    path     = "/"
    matcher  = "200-499"
    timeout  = 10
    interval = 60
  }
}

# --- LISTENER RULES ---
# ... (Repetitive rules mapping - simplified for brevity, logic remains same)
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

# --- ECR & ECS ---

locals {
  service_names = [ "web", "auth-service", "user-profile-service", "routine-service", "analytics-service", "notification-service", "workout-command-service", "workout-query-service", "exercise-library-service", "video-service", "sync-service" ]
}

resource "aws_ecr_repository" "services" {
  count = length(local.service_names)
  name  = "${var.project_name}/${local.service_names[count.index]}"
  force_delete = true
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${var.project_name}"
  retention_in_days = 1
}

# --- ECS TASKS DEFINITIONS (CORRECTED TO POINT TO SINGLE DB SERVER) ---

# WEB
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.project_name}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "web", image = "${aws_ecr_repository.services[0].repository_url}:dev", essential = true,
    portMappings = [{ containerPort = 80 }],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "web" } }
  }])
}

resource "aws_ecs_service" "web" {
  name            = "${var.project_name}-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener.http]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 80
  }
}

# AUTH (Use database_server IP)
resource "aws_ecs_task_definition" "auth" {
  family                   = "${var.project_name}-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "auth", # ESTO ES LO QUE BUSCAMOS EN EL CI.YML (Debe ser "auth")
    image = "${aws_ecr_repository.services[1].repository_url}:dev", 
    essential = true,
    # command = ["sh", "-c", "python -c 'import socket, time; s=socket.socket(); s.settimeout(1); [time.sleep(1) for _ in range(300) if s.connect_ex((\"${aws_instance.database_server.private_ip}\", 5432)) != 0]' && python manage.py migrate && python init_user.py && python seed_data.py && python manage.py runserver 0.0.0.0:8001"],
    portMappings = [{ containerPort = 8001 }],
    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:adminpassword@${aws_instance.database_server.private_ip}:5432/auth_db" },
      { name = "REDIS_HOST", value = aws_instance.database_server.private_ip },
      { name = "REDIS_PORT", value = "6379" },
      { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "auth" } }
  }])
}

resource "aws_ecs_service" "auth" {
  name            = "${var.project_name}-auth-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.auth_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["auth"].arn
    container_name   = "auth"
    container_port   = 8001
  }
}

# USER
resource "aws_ecs_task_definition" "user" {
  family                   = "${var.project_name}-user"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "user", image = "${aws_ecr_repository.services[2].repository_url}:dev", essential = true,
    # command = [
    #   "sh", 
    #   "-c", 
    #   # ESTO ES LO IMPORTANTE: Bucle que intenta conectar al puerto 5432 antes de seguir
    #   "while ! nc -z ${aws_instance.database_server.private_ip} 5432; do echo 'Waiting for DB...'; sleep 3; done; python manage.py migrate && python manage.py runserver 0.0.0.0:8002"
    # ],
    portMappings = [{ containerPort = 8002 }],
    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:adminpassword@${aws_instance.database_server.private_ip}:5432/user_profile_db" },
      { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "user" } }
  }])
}

resource "aws_ecs_service" "user" {
  name            = "${var.project_name}-user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.user_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["user"].arn
    container_name   = "user"
    container_port   = 8002
  }
}

# SYNC
resource "aws_ecs_task_definition" "sync" {
  family                   = "${var.project_name}-sync"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "sync", image = "${aws_ecr_repository.services[10].repository_url}:dev", essential = true,
    portMappings = [{ containerPort = 8009 }],
    environment = [ { name = "REDIS_HOST", value = aws_instance.database_server.private_ip }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key } ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "sync" } }
  }])
}

resource "aws_ecs_service" "sync" {
  name            = "${var.project_name}-sync-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sync.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.sync_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.access_tgs["sync"].arn
    container_name   = "sync"
    container_port   = 8009
  }
}

# WORKOUT COMMAND (MONGO)
resource "aws_ecs_task_definition" "work_cmd" {
  family                   = "${var.project_name}-work-cmd"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "work-cmd", image = "${aws_ecr_repository.services[6].repository_url}:dev", essential = true,
    # command = ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8003"],
    portMappings = [{ containerPort = 8003 }],
    environment = [
      { name = "MONGO_HOST",    value = aws_instance.database_server.private_ip },
      { name = "MONGO_PORT",    value = "27017" },
      { name = "MONGO_DB_NAME", value = "workout_db" }, # Nombre común para Command y Query
      { name = "REDIS_HOST",    value = aws_instance.database_server.private_ip },
      { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
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
  depends_on      = [aws_lb_listener_rule.work_cmd_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["work-cmd"].arn
    container_name   = "work-cmd"
    container_port   = 8003
  }
}

# WORKOUT QUERY
resource "aws_ecs_task_definition" "work_qry" {
  family                   = "${var.project_name}-work-qry"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "work-qry", image = "${aws_ecr_repository.services[7].repository_url}:dev", essential = true,
    # command = ["sh", "-c", "python manage.py migrate && python manage.py seed_mongo && python manage.py runserver 0.0.0.0:8004"],
    portMappings = [{ containerPort = 8004 }],
    environment = [
      { name = "MONGO_HOST",    value = aws_instance.database_server.private_ip },
      { name = "MONGO_PORT",    value = "27017" },
      { name = "MONGO_DB_NAME", value = "workout_db" }, # Nombre común para Command y Query
      { name = "REDIS_HOST",    value = aws_instance.database_server.private_ip }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
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
  depends_on      = [aws_lb_listener_rule.work_qry_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["work-qry"].arn
    container_name   = "work-qry"
    container_port   = 8004
  }
}

# ROUTINE
resource "aws_ecs_task_definition" "routine" {
  family                   = "${var.project_name}-routine"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "routine", image = "${aws_ecr_repository.services[3].repository_url}:dev", essential = true,
    portMappings = [{ containerPort = 8005 }],
    environment = [
      { name = "DATABASE_URL", value = "postgresql://admin:adminpassword@${aws_instance.database_server.private_ip}:5432/routine_db" },
      { name = "REDIS_HOST", value = aws_instance.database_server.private_ip }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
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
  depends_on      = [aws_lb_listener_rule.routine_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["routine"].arn
    container_name   = "routine"
    container_port   = 8005
  }
}

# EXERCISE LIBRARY
resource "aws_ecs_task_definition" "exercise" {
  family                   = "${var.project_name}-exercise"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "exercise", image = "${aws_ecr_repository.services[8].repository_url}:dev", essential = true,
    # command = ["sh", "-c", "python manage.py makemigrations exercises && python manage.py migrate && python manage.py seed_exercises && python manage.py runserver 0.0.0.0:8006"],
    portMappings = [{ containerPort = 8006 }],
    environment = [
      { name = "MONGO_HOST", value = aws_instance.database_server.private_ip }, { name = "MONGO_PORT", value = "27017" },
      { name = "REDIS_HOST", value = aws_instance.database_server.private_ip }, { name = "AWS_STORAGE_BUCKET_NAME", value = aws_s3_bucket.videos.bucket },
      { name = "AWS_REGION", value = var.aws_region }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key }
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
  depends_on      = [aws_lb_listener_rule.exercise_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.core_tgs["exercise"].arn
    container_name   = "exercise"
    container_port   = 8006
  }
}

# NOTIFY, VIDEO, ANALYTICS (OMITIDOS PARA BREVEDAD, SEGUIR PATRÓN DE ARRIBA USANDO aws_instance.database_server.private_ip)
# Video - Port 8007
resource "aws_ecs_task_definition" "video" {
  family                   = "${var.project_name}-video"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "video", image = "${aws_ecr_repository.services[9].repository_url}:dev", essential = true, portMappings = [{ max = 8007, min = 8007, containerPort = 8007 }],
    environment = [ { name = "MONGO_HOST", value = aws_instance.database_server.private_ip }, { name = "REDIS_HOST", value = aws_instance.database_server.private_ip }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key } ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "video" } }
  }])
}

resource "aws_ecs_service" "video" {
  name            = "${var.project_name}-video-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.video.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.video_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["video"].arn
    container_name   = "video"
    container_port   = 8007
  }
}
# Analytics - Port 8010
resource "aws_ecs_task_definition" "analytics" {
  family = "${var.project_name}-analytics"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "analytics",
    image = "${aws_ecr_repository.services[4].repository_url}:dev",
    essential = true,
    
    # --- AGREGAR ESTO: Migrar al iniciar para asegurar tablas ---
    # command = ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8010"],
    
    portMappings = [{ containerPort = 8010 }],
    environment = [ 
      { name = "DATABASE_URL", value = "postgresql://admin:adminpassword@${aws_instance.database_server.private_ip}:5432/analytics_db" }, 
      { name = "DJANGO_SECRET_KEY", value = var.django_secret_key } 
    ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "analytics" } }
  }])
}
resource "aws_ecs_service" "analytics" {
  name            = "${var.project_name}-analytics-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.analytics_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["analytics"].arn
    container_name   = "analytics"
    container_port   = 8010
  }
}

# Notify - Port 8008
resource "aws_ecs_task_definition" "notify" {
  family                   = "${var.project_name}-notify"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name = "notify", image = "${aws_ecr_repository.services[5].repository_url}:dev", essential = true, portMappings = [{ containerPort = 8008 }],
    environment = [ { name = "REDIS_HOST", value = aws_instance.database_server.private_ip }, { name = "DJANGO_SECRET_KEY", value = var.django_secret_key } ],
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.ecs_logs.name, "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = "notify" } }
  }])
}

resource "aws_ecs_service" "notify" {
  name            = "${var.project_name}-notify-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notify.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener_rule.notify_rule]

  network_configuration {
    subnets         = [aws_subnet.private_1.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.heavy_tgs["notify"].arn
    container_name   = "notify"
    container_port   = 8008
  }
}

# --- OUTPUTS ---
output "alb_dns_name" { value = aws_lb.main.dns_name }
output "ecr_repo_urls" { value = aws_ecr_repository.services[*].repository_url }
output "db_server_ip" { value = aws_instance.database_server.public_ip }