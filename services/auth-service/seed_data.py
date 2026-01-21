import os
import django
import uuid

# Configurar Django fuera del entorno normal
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()

from users.models import CustomUser
from analytics.models import UserAnalytics
from routines.models import Routine


# UUID DETERMINISTA PARA EL ADMIN (La Clave Maestra)
# Este mismo ID se usará en TODOS los otros scripts de seed.
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"


def seed_users():
    if CustomUser.objects.filter(id=ADMIN_UUID).exists():
        print(f"⚠️  Admin user {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding Admin User with fixed UUID: {ADMIN_UUID}...")
    user = CustomUser.objects.create_superuser(
        id=ADMIN_UUID,  # Forzamos el ID
        email="admin@gymtracker.com",
        password="adminpassword",
        first_name="System",
        last_name="Admin",
    )
    print("✅ Admin created successfully.")


def seed_analytics():
    if UserAnalytics.objects.filter(user_id=ADMIN_UUID).exists():
        print(f"⚠️  Analytics for user {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding Analytics for {ADMIN_UUID}...")
    UserAnalytics.objects.create(
        user_id=ADMIN_UUID,
        total_workouts=5,
        total_calories=1500.0
    )
    print("✅ Analytics data created successfully.")


def seed_routines():
    if Routine.objects.filter(user_id=ADMIN_UUID).exists():
        print(f"⚠️  Routine for user {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding Routine for {ADMIN_UUID}...")
    Routine.objects.create(
        user_id=ADMIN_UUID,  # Vinculamos al Admin
        name="Admin Power Routine"
    )
    print("✅ Routine created successfully.")


if __name__ == "__main__":
    seed_users()
    seed_analytics()
    seed_routines()
