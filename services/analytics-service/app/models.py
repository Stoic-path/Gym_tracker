from django.db import models

class UserAnalytics(models.Model):
    # Usamos el mismo UUID que en Auth/Profile/Mongo para integridad lógica
    user_id = models.UUIDField(primary_key=True)
    total_workouts = models.IntegerField(default=0)
    calories_burned = models.IntegerField(default=0)
    current_streak = models.IntegerField(default=0)
    favorite_muscle = models.CharField(max_length=50, default="N/A")
    
    def __str__(self):
        return f"Analytics for {self.user_id}"
