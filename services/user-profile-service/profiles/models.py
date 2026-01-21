from django.db import models
import uuid

class UserProfile(models.Model):
    # CORRECCIÓN CRÍTICA:
    # Quitamos 'default=uuid.uuid4'.
    # El ID *debe* ser provisto explícitamente (viniendo del Auth Service o del Seed).
    # Si intentamos crear un perfil sin pasarle ID, debe fallar.
    user_id = models.UUIDField(primary_key=True, editable=False) 
    
    email = models.EmailField()
    full_name = models.CharField(max_length=255)
    bio = models.TextField(blank=True, default="Gym enthusiast ready to crush goals!")
    weight = models.FloatField(default=0.0)
    joined_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email

class NotificationSettings(models.Model):
    # ID provisto externamente. Es PK.
    user_id = models.UUIDField(primary_key=True, editable=False)
    
    email_enabled = models.BooleanField(default=True)
    push_enabled = models.BooleanField(default=True)
    marketing_enabled = models.BooleanField(default=False)
