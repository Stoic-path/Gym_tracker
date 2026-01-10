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

# Subnet Privada
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

  # Permitir SSH (Para depuración manual)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. DATABASES (EC2 Instances) ---

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

# --- 3. LOAD BALANCING (ALB) ---

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
  
  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_target_group" "auth" {
  name     = "tg-auth"
  port     = 8001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "user" {
  name     = "tg-user"
  port     = 8002
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "work_cmd" {
  name     = "tg-work-cmd"
  port     = 8003
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "work_qry" {
  name     = "tg-work-qry"
  port     = 8004
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "exercise" {
  name     = "tg-exercise"
  port     = 8005
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "routine" {
  name     = "tg-routine"
  port     = 8006
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "analytics" {
  name     = "tg-analytics"
  port     = 8007
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "notify" {
  name     = "tg-notify"
  port     = 8008
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "video" {
  name     = "tg-video"
  port     = 8009
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "sync" {
  name     = "tg-sync"
  port     = 8010
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

# --- LISTENER RULES (Reglas de Enrutamiento) ---

resource "aws_lb_listener_rule" "auth_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
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
    target_group_arn = aws_lb_target_group.user.arn
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
    target_group_arn = aws_lb_target_group.work_cmd.arn
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
    target_group_arn = aws_lb_target_group.work_qry.arn
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
    target_group_arn = aws_lb_target_group.exercise.arn
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
    target_group_arn = aws_lb_target_group.routine.arn
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
    target_group_arn = aws_lb_target_group.analytics.arn
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
    target_group_arn = aws_lb_target_group.notify.arn
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
    target_group_arn = aws_lb_target_group.video.arn
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
    target_group_arn = aws_lb_target_group.sync.arn
  }
  condition {
    path_pattern {
      values = ["/api/sync*"]
    }
  }
}

# --- 4. COMPUTE (Launch Templates & ASGs) ---

locals {
  services = {
    "web" = {
      port = 80
      image = "web"
      tg_arn = aws_lb_target_group.web.arn
      db_host = ""
    }
    "auth-service" = {
      port = 8001
      image = "auth-service"
      tg_arn = aws_lb_target_group.auth.arn
      db_host = aws_instance.postgres.private_ip
    }
    "user-profile-service" = {
      port = 8002
      image = "user-profile-service"
      tg_arn = aws_lb_target_group.user.arn
      db_host = aws_instance.postgres.private_ip
    }
    "workout-command-service" = {
      port = 8003
      image = "workout-command-service"
      tg_arn = aws_lb_target_group.work_cmd.arn
      db_host = aws_instance.mongo.private_ip
    }
    "workout-query-service" = {
      port = 8004
      image = "workout-query-service"
      tg_arn = aws_lb_target_group.work_qry.arn
      db_host = aws_instance.mongo.private_ip
    }
    "exercise-library-service" = {
      port = 8005
      image = "exercise-library-service"
      tg_arn = aws_lb_target_group.exercise.arn
      db_host = aws_instance.mongo.private_ip
    }
    "routine-service" = {
      port = 8006
      image = "routine-service"
      tg_arn = aws_lb_target_group.routine.arn
      db_host = aws_instance.postgres.private_ip
    }
    "analytics-service" = {
      port = 8007
      image = "analytics-service"
      tg_arn = aws_lb_target_group.analytics.arn
      db_host = aws_instance.postgres.private_ip
    }
    "notification-service" = {
      port = 8008
      image = "notification-service"
      tg_arn = aws_lb_target_group.notify.arn
      db_host = aws_instance.redis.private_ip
    }
    "video-service" = {
      port = 8009
      image = "video-service"
      tg_arn = aws_lb_target_group.video.arn
      db_host = aws_instance.mongo.private_ip
    }
    "sync-service" = {
      port = 8010
      image = "sync-service"
      tg_arn = aws_lb_target_group.sync.arn
      db_host = aws_instance.redis.private_ip
    }
  }
}

resource "aws_launch_template" "microservice_lt" {
  for_each = local.services

  name_prefix   = "${var.project_name}-${each.key}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type_app
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name = var.key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    SERVICE_PORT="${each.value.port}"
    IMAGE_NAME="stoicpath/${each.value.image}"
    DB_HOST="${each.value.db_host}"
    
    docker rm -f $(docker ps -a -q) || true
    docker pull $IMAGE_NAME:latest
    docker run -d --restart always \
      -p $SERVICE_PORT:$SERVICE_PORT \
      -e DB_HOST=$DB_HOST \
      -e DB_PORT=5432 \
      -e REDIS_HOST=${aws_instance.redis.private_ip} \
      -e REDIS_PORT=6379 \
      -e DJANGO_SECRET_KEY='super-secret-key-prod' \
      -e DEBUG='False' \
      $IMAGE_NAME:latest
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${each.key}"
    }
  }
}

resource "aws_autoscaling_group" "microservice_asg" {
  for_each = local.services

  name                = "${var.project_name}-${each.key}-asg"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.private_1.id]

  target_group_arns = [each.value.tg_arn]

  wait_for_capacity_timeout = "0" # Disable timeout

  launch_template {
    id      = aws_launch_template.microservice_lt[each.key].id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${each.key}"
    propagate_at_launch = true
  }
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