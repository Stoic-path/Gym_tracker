import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()

from analytics.models import UserAnalytics

# UUID DETERMINISTA PARA EL ADMIN (La Clave Maestra)
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"

def seed():
    if UserAnalytics.objects.filter(user_id=ADMIN_UUID).exists():
        print(f"⚠️  Analytics for user {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding Analytics for {ADMIN_UUID}...")
    UserAnalytics.objects.create(
        user_id=ADMIN_UUID,
        total_workouts=15,
        total_calories=4500.0,
        current_streak=3,
        favorite_muscle="Chest",
        average_technique_score=8.5,
        exercises_improved=12,
        exercises_plateau=2,
        exercises_atrophy=0
    )
    print("✅ Analytics data created successfully.")

if __name__ == "__main__":
    seed()
