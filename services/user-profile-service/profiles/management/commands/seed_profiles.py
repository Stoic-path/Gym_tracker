from django.core.management.base import BaseCommand
from profiles.models import UserProfile

class Command(BaseCommand):
    help = 'Seeds the database with initial user profiles'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding User Profiles...')
        
        # Eliminar datos viejos para evitar duplicados en pruebas
        UserProfile.objects.all().delete()
        
        # Crear perfil de prueba
        UserProfile.objects.create(
            user_id="u-seed-123",
            email="admin@gymtracker.com",
            full_name="Admin Musculoso",
            bio="Entrenando desde 2026 para el Mr. Olympia Distributed Systems Edition."
        )
        UserProfile.objects.create(
            user_id="u-seed-456",
            email="client@gymtracker.com",
            full_name="Cliente Fitness",
            bio="Corriendo en Docker Containers."
        )
        
        self.stdout.write(self.style.SUCCESS('Successfully seeded User Profiles!'))
