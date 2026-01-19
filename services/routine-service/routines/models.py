from django.db import models
import uuid

class Routine(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # El ID del usuario viene del token JWT (Auth Service)
    user_id = models.UUIDField(help_text="ID del usuario propietario")
    name = models.CharField(max_length=100, default="Mi Rutina")
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} - {self.user_id}"

class RoutineGroup(models.Model):
    """
    Representa un grupo muscular mayor seleccionado (ej: Púrpura, Rojo).
    """
    routine = models.ForeignKey(Routine, related_name='groups', on_delete=models.CASCADE)
    name = models.CharField(max_length=50) # ej: Púrpura
    code = models.CharField(max_length=20) # ej: PURPLE

    def __str__(self):
        return f"{self.name} en {self.routine.name}"

class RoutineExercise(models.Model):
    """
    El ejercicio específico seleccionado por el usuario.
    """
    group = models.ForeignKey(RoutineGroup, related_name='exercises', on_delete=models.CASCADE)
    subgroup_name = models.CharField(max_length=100) # ej: Pecho
    exercise_name = models.CharField(max_length=200) # ej: Press Banca
    exercise_id = models.CharField(max_length=100)   # ID original de MongoDB (string)
    
    # Metas personalizadas
    target_sets = models.IntegerField(default=4)
    target_reps = models.IntegerField(default=12)

    class Meta:
        ordering = ['subgroup_name', 'exercise_name']
