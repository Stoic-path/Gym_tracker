from django.db import models
import uuid
from django.utils import timezone

class WorkoutCommand(models.Model):
    # ID propio de este registro de entrenamiento
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # REFERENCIA AL USUARIO (Obligatorio, sin default, viene del Token)
    user_id = models.UUIDField(editable=False, db_index=True)
    
    name = models.CharField(max_length=255)
    notes = models.TextField(blank=True)
    
    # Fechas importantes para el historial
    started_at = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Estado del comando (Draft, Completed, Cancelled)
    status = models.CharField(max_length=50, default="completed")

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Command: {self.name} by {self.user_id}"