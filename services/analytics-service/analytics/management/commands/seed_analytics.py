﻿from django.core.management.base import BaseCommand
from analytics.models import UserAnalytics
import uuid
import random

class Command(BaseCommand):
    help = 'Seeds the analytics database with deterministic sample data'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding Analytics Data...')
        
        # Generar datos para los 100 usuarios deterministas
        for i in range(100):
            email = f"user_{i}@gymtracker.com"
            # Generamos el MISMO UUID que en los otros microservicios
            user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, email))
            
            UserAnalytics.objects.get_or_create(
                user_id=user_id,
                defaults={
                    'total_workouts': random.randint(5, 100),
                    'calories_burned': random.randint(2000, 50000),
                    'current_streak': random.randint(0, 30),
                    'favorite_muscle': random.choice(["Pecho", "Espalda", "Bíceps", "Hombro"]),
                    'exercises_improved': random.randint(5, 20),
                    'exercises_plateau': random.randint(0, 5),
                    'exercises_atrophy': random.randint(0, 2),
                    'average_technique_score': round(random.uniform(2.5, 4.0), 1)
                }
            )
        
        self.stdout.write(self.style.SUCCESS('Successfully seeded Analytics Data!'))
