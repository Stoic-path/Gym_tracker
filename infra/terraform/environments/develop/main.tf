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

resource "aws_lb_target_group" "access_tgs" {
  for_each = var.tg_access_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "core_tgs" {
  for_each = var.tg_core_group
  name     = "tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path    = "/"
    matcher = "200-499"
  }
}

resource "aws_lb_target_group" "heavy_tgs" {
  for_each = var.tg_heavy_group
  name     = "tg-${each.key}"
  port     = each.value.port
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


# --- 4. COMPUTE (Launch Templates & ASGs) ---

# --- EC2 #4: FRONTEND ---
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "${var.project_name}-frontend-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    docker run -d --restart always -p 80:80 --name web stoicpath/web:latest
  EOF
  )
}

resource "aws_autoscaling_group" "frontend_asg" {
  name                = "${var.project_name}-frontend-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.private_1.id]
  target_group_arns   = [aws_lb_target_group.web.arn]
  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend"
    propagate_at_launch = true
  }
}

# --- EC2 #5: GRUPO ACCESO (Auth, User, Sync) ---
resource "aws_launch_template" "access_lt" {
  name_prefix   = "${var.project_name}-access-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.medium"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data = base64encode(templatefile("${path.module}/../../../scripts/setup_backend_access.sh", {
    postgres_ip = aws_instance.postgres.private_ip
    redis_ip    = aws_instance.redis.private_ip
  }))
}

resource "aws_autoscaling_group" "access_asg" {
  name                = "${var.project_name}-access-asg"
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.private_1.id]
  target_group_arns   = [for tg in aws_lb_target_group.access_tgs : tg.arn]
  launch_template {
    id      = aws_launch_template.access_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-access-node"
    propagate_at_launch = true
  }
}

# --- EC2 #6: GRUPO CORE (Cmd, Qry, Routine, Lib) ---
resource "aws_launch_template" "core_lt" {
  name_prefix   = "${var.project_name}-core-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.medium"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data = base64encode(templatefile("${path.module}/../../../scripts/setup_backend_core.sh", {
    postgres_ip = aws_instance.postgres.private_ip
    mongo_ip    = aws_instance.mongo.private_ip
  }))
}

resource "aws_autoscaling_group" "core_asg" {
  name                = "${var.project_name}-core-asg"
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.private_1.id]
  target_group_arns   = [for tg in aws_lb_target_group.core_tgs : tg.arn]
  launch_template {
    id      = aws_launch_template.core_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-core-node"
    propagate_at_launch = true
  }
}

# --- EC2 #7: GRUPO HEAVY (Video, Notif, Analytics) ---
resource "aws_launch_template" "heavy_lt" {
  name_prefix   = "${var.project_name}-heavy-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.medium"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  user_data = base64encode(templatefile("${path.module}/../../../scripts/setup_backend_heavy.sh", {
    postgres_ip = aws_instance.postgres.private_ip
    mongo_ip    = aws_instance.mongo.private_ip
    redis_ip    = aws_instance.redis.private_ip
  }))
}

resource "aws_autoscaling_group" "heavy_asg" {
  name                = "${var.project_name}-heavy-asg"
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.private_1.id]
  target_group_arns   = [for tg in aws_lb_target_group.heavy_tgs : tg.arn]
  launch_template {
    id      = aws_launch_template.heavy_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-heavy-node"
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