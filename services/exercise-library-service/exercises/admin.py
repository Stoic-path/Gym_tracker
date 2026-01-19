from django.contrib import admin
from .models import MuscleGroup, FullRoutineVideo

# Djongo intenta renderizar los campos anidados como JSON o formularios simples
admin.site.register(MuscleGroup)
admin.site.register(FullRoutineVideo)