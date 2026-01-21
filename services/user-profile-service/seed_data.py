import os
import django
import uuid

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()

from profiles.models import UserProfile

# EL MISMO UUID DETERMINISTA
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"

def seed():
    if UserProfile.objects.filter(user_id=ADMIN_UUID).exists():
        print(f"⚠️  UserProfile for {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding UserProfile linked to Admin UUID...")
    
    # Aquí creamos el perfil usando el ID que sabemos que creó Auth Service
    UserProfile.objects.create(
        user_id=ADMIN_UUID, # ENLACE CRÍTICO
        email="admin@gymtracker.com",
        full_name="System Admin",
        bio="I am the root user.",
        weight=70.5
    )
    print("✅ UserProfile seeded successfully.")

if __name__ == "__main__":
    seed()