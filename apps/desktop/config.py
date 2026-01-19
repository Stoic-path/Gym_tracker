# Reemplaza esto con el DNS de tu Load Balancer (ALB) que obtuviste de Terraform
# Ejemplo: "http://gym-tracker-alb-123456789.us-east-1.elb.amazonaws.com"
API_BASE_URL = "http://gym-tracker-alb-51009640.us-east-1.elb.amazonaws.com"

ENDPOINTS = {
    "login": "/api/auth/login",
    "exercises": "/api/exercises/",
    "groups": "/api/exercises/groups/",
}
