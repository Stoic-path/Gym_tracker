from rest_framework import viewsets, permissions
from .models import Routine
from .serializers import RoutineSerializer

class RoutineViewSet(viewsets.ModelViewSet):
    serializer_class = RoutineSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Filtra las rutinas para mostrar solo las del usuario autenticado + las públicas.
        """
        user = self.request.user
        # Si no hay usuario autenticado (aunque permission_classes lo bloquee antes), devolver vacio
        if not user or user.is_anonymous:
            return Routine.objects.none()

        # Convertir user.id a string UUID para evitar problemas de tipo en el ORM
        # Especialmente si user.id viene del JWT como string y el campo es UUIDField
        user_id_val = str(user.id) if user.id else None

        # Retornar rutinas propias O rutinas públicas
        from django.db.models import Q
        return Routine.objects.filter(Q(user_id=user_id_val) | Q(is_public=True))

    def perform_create(self, serializer):
        """
        Asigna automáticamente el ID del usuario al crear la rutina.
        """
        # Si el usuario es staff/admin se podría dejar pasar is_public, 
        # pero por simplicidad permitimos que lo envíen si lo desean.
        serializer.save(user_id=self.request.user.id)
