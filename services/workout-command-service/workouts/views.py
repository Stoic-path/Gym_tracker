from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import WorkoutCommand
from .serializers import WorkoutCommandSerializer

class WorkoutCommandViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutCommandSerializer
    permission_classes = [IsAuthenticated]

    # 1. Solo mostrar workouts del usuario logueado
    def get_queryset(self):
        return WorkoutCommand.objects.filter(user_id=self.request.user.id)

    # 2. Al guardar, inyectar el user_id del Token automáticamente
    def perform_create(self, serializer):
        serializer.save(user_id=self.request.user.id)