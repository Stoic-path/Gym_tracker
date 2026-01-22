from django.db import models
import uuid

class UserAnalytics(models.Model):
    # ID provisto externamente (Auth). Es PK.
    user_id = models.UUIDField(primary_key=True, editable=False)
    
    total_workouts = models.IntegerField(default=0)
    total_calories = models.FloatField(default=0.0)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Stats for {self.user_id}"
