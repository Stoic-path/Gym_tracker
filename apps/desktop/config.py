# Reemplaza esto con el DNS de tu Load Balancer (ALB) que obtuviste de Terraform
# Ejemplo: "http://gym-tracker-alb-123456789.us-east-1.elb.amazonaws.com"
API_BASE_URL = "http://[33mÔòÀ[0m[0m [33mÔöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mÔöé[0m [0m [33mÔöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define [33mÔöé[0m [0man output in your configuration with the `output` keyword and run `terraform refresh` for it to [33mÔöé[0m [0mbecome available. If you are using interpolation, please verify the interpolated value is not [33mÔöé[0m [0mempty. You can use the `terraform console` command to assist. [33mÔòÁ[0m[0m"

# ConfiguraciÃ³n de AWS S3
AWS_REGION = "us-east-1"
S3_BUCKET_NAME = "[33mÔòÀ[0m[0m [33mÔöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mÔöé[0m [0m [33mÔöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define [33mÔöé[0m [0man output in your configuration with the `output` keyword and run `terraform refresh` for it to [33mÔöé[0m [0mbecome available. If you are using interpolation, please verify the interpolated value is not [33mÔöé[0m [0mempty. You can use the `terraform console` command to assist. [33mÔòÁ[0m[0m"

ENDPOINTS = {
    "login": "/api/auth/login",
    "exercises": "/api/exercises/",
    "groups": "/api/exercises/groups/",
}
