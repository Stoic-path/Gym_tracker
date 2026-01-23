from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import AccessToken
from analytics.models import UserAnalytics

class AnalyticsSummaryView(APIView):
    # Desactivamos la autenticación automática para validar el token manualmente
    # ya que este servicio no tiene la tabla de usuarios de Auth.
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        # 1. Extraer token manualmente
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({"error": "Token no proporcionado"}, status=401)
        
        try:
            token_str = auth_header.split(' ')[1]
            token = AccessToken(token_str)
            user_id = token['user_id']
        except Exception:
            return Response({"error": "Token inválido"}, status=401)

        # 2. Consultar DB Real
        try:
            stats = UserAnalytics.objects.get(user_id=user_id)
            return Response({
                "total_workouts": stats.total_workouts,
                "calories_burned": stats.total_calories,  # Mapped from total_calories
                "current_streak": 0,                      # Default/Placeholder
                "favorite_muscle": "N/A",                 # Default/Placeholder
                "progress_metrics": {
                    "improved": 0,
                    "plateau": 0,
                    "atrophy": 0
                },
                "technique_score": 0.0,                   # Default/Placeholder
                "source": "Analytics Service (DB Real)"
            })
        except UserAnalytics.DoesNotExist:
            # Si no hay datos, devolvemos ceros en lugar de error 404
            return Response({"total_workouts": 0, "calories_burned": 0, "current_streak": 0, "favorite_muscle": "N/A", "progress_metrics": {"improved": 0, "plateau": 0, "atrophy": 0}, "technique_score": 0.0})