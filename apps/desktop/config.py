# Reemplaza esto con el DNS de tu Load Balancer (ALB) que obtuviste de Terraform
# Ejemplo: "http://gym-tracker-alb-123456789.us-east-1.elb.amazonaws.com"
API_BASE_URL = "http://gym-tracker-alb-1287502065.us-east-1.elb.amazonaws.com"

# Configuración de AWS S3
AWS_REGION = "us-east-1"
S3_BUCKET_NAME = "gym-tracker-videos-76dcf3b6"

ENDPOINTS = {
    "login": "/api/auth/login",
    "exercises": "/api/exercises/",
    "groups": "/api/exercises/groups/",
}
