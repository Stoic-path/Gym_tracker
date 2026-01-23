from django.db import models
import uuid

class Routine(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False) # ID de la rutina (propio)
    
    # REFERENCIA AL USUARIO (NO es PK, NO tiene default)
    user_id = models.UUIDField(editable=False, db_index=True)
    
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    is_public = models.BooleanField(default=False)  # Rutinas globales/plantillas

    def __str__(self):
        return f"{self.name} by {self.user_id}"

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
