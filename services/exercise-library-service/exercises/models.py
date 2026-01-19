from djongo import models
import uuid

class Exercise(models.Model):
    """
    Modelo embebido para el ejercicio.
    Se guarda DENTRO del Subgrupo en MongoDB.
    """
    uid = models.UUIDField(default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # URLs de S3
    short_video_url = models.URLField(blank=True, null=True, help_text="URL del video corto en S3")
    thumbnail_url = models.URLField(blank=True, null=True)
    
    # Reglas
    needs_weight = models.BooleanField(default=True, help_text="¿Requiere peso adicional?")
    
    class Meta:
        abstract = True

class SubGroup(models.Model):
    """
    Modelo embebido para el subgrupo (ej: Pecho, Bíceps).
    Se guarda DENTRO del Grupo Muscular.
    """
    uid = models.UUIDField(default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    
    # Reglas de selección para la rutina
    min_exercises = models.IntegerField(default=2)
    max_exercises = models.IntegerField(default=3)
    
    # Lista de ejercicios embebidos
    exercises = models.ArrayField(
        model_container=Exercise,
        default=list
    )
    
    class Meta:
        abstract = True

class MuscleGroup(models.Model):
    """
    Documento principal en MongoDB (Colección: muscle_groups).
    Contiene toda la jerarquía.
    """
    COLOR_CHOICES = [
        ('PURPLE', 'Púrpura'),
        ('RED', 'Rojo'),
        ('BLUE', 'Azul'),
        ('SKIN', 'Piel'),
    ]
    
    _id = models.ObjectIdField()
    name = models.CharField(max_length=50, unique=True)
    code = models.CharField(max_length=20, choices=COLOR_CHOICES)
    hex_color = models.CharField(max_length=7)
    description = models.TextField(blank=True)
    
    # Lista de subgrupos embebidos
    subgroups = models.ArrayField(
        model_container=SubGroup,
        default=list
    )

    objects = models.DjongoManager()

    def __str__(self):
        return f"{self.name} ({self.code})"

class FullRoutineVideo(models.Model):
    """
    Colección separada para videos largos.
    """
    _id = models.ObjectIdField()
    title = models.CharField(max_length=200)
    video_url = models.URLField()
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    objects = models.DjongoManager()