import os
import django

# Configurar Django fuera del entorno normal
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()

from users.models import CustomUser  # noqa: E402


# UUID DETERMINISTA PARA EL ADMIN (La Clave Maestra)
# Este mismo ID se usará en TODOS los otros scripts de seed.
ADMIN_UUID = "00000000-0000-0000-0000-000000000001"


def seed_users():
    if CustomUser.objects.filter(id=ADMIN_UUID).exists():
        print(f"⚠️  Admin user {ADMIN_UUID} already exists.")
        return

    print(f"🌱 Seeding Admin User with fixed UUID: {ADMIN_UUID}...")
    CustomUser.objects.create_superuser(
        id=ADMIN_UUID,  # Forzamos el ID
        email="admin@gymtracker.com",
        password="adminpassword",
        first_name="System",
        last_name="Admin",
    )
    print("✅ Admin created successfully.")


if __name__ == "__main__":
    seed_users()
