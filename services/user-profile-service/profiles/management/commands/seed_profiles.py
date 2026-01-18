from django.core.management.base import BaseCommand
from profiles.models import UserProfile
import uuid

class Command(BaseCommand):
    help = 'Seeds the database with initial user profiles'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding User Profiles...')
        
        # Generar perfiles para los 100 usuarios deterministas
        for i in range(100):
            email = f"user_{i}@gymtracker.com"
            user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            
            UserProfile.objects.get_or_create(
                user_id=user_id,
                defaults={
                    'email': email,
                    'full_name': f"Usuario de Prueba {i}",
                    'bio': "Generado automáticamente por seed determinista."
                }
            )
        
        self.stdout.write(self.style.SUCCESS('Successfully seeded User Profiles!'))
