import os
import random
import string
import uuid

import django

# Configurar entorno Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
django.setup()

from django.contrib.auth import get_user_model  # noqa: E402,F401
from users.models import User  # noqa: E402


def generate_random_string(length=8):
    return "".join(random.choices(string.ascii_letters, k=length))


def seed():
    print("🌱 [Seed] Auth Service: Creando usuarios deterministas...")

    print("🌱 [Seed] Auth Service: Asegurando 100 usuarios deterministas...")
    for i in range(100):
        email = f"user_{i}@gymtracker.com"
        # Generar UUID determinista basado en el email
        user_id = uuid.uuid5(uuid.NAMESPACE_DNS, email)
        password = "password123"

        if not User.objects.filter(email=email).exists():
            User.objects.create_user(id=user_id, email=email, password=password)
        else:
            pass  # El usuario ya existe, no hacemos nada (Idempotencia)

    print("✅ [Seed] Auth Service: Carga completa.")


if __name__ == "__main__":
    seed()
