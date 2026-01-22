from rest_framework import viewsets, permissions
from .models import Routine
from .serializers import RoutineSerializer

class RoutineViewSet(viewsets.ModelViewSet):
    serializer_class = RoutineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Filtra las rutinas para mostrar solo las del usuario autenticado.
        """
        # Asumimos que el ID del usuario viene en el token JWT decodificado en request.user
        return Routine.objects.filter(user_id=self.request.user.id)

    def perform_create(self, serializer):
        """
        Asigna automáticamente el ID del usuario al crear la rutina.
        """
        serializer.save(user_id=self.request.user.id)
