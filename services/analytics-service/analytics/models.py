from django.db import models

class UserAnalytics(models.Model):
    # Usamos el mismo UUID que en Auth/Profile/Mongo para integridad lógica
    user_id = models.UUIDField(primary_key=True)
    total_workouts = models.IntegerField(default=0)
    calories_burned = models.IntegerField(default=0)
    current_streak = models.IntegerField(default=0)
    favorite_muscle = models.CharField(max_length=50, default="N/A")
    
    # Métricas avanzadas (Req 1.7: Progress Measurement)
    exercises_improved = models.IntegerField(default=0, help_text="Ejercicios con mejora de carga/reps")
    exercises_plateau = models.IntegerField(default=0, help_text="Ejercicios estancados")
    exercises_atrophy = models.IntegerField(default=0, help_text="Ejercicios con regresión")
    average_technique_score = models.FloatField(default=0.0, help_text="Calidad técnica promedio (1-4)")
    
    def __str__(self):
        return f"Analytics for {self.user_id}"
