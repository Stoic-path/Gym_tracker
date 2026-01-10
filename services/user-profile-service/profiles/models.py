from django.db import models

class UserProfile(models.Model):
    user_id = models.CharField(max_length=100, unique=True)  # ID compartido (Auth Service)
    email = models.EmailField()
    full_name = models.CharField(max_length=255)
    bio = models.TextField(blank=True, default="Gym enthusiast ready to crush goals!")
    joined_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email
