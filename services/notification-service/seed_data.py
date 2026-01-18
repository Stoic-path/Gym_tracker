import os
import redis
import random

REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))

def seed():
    try:
        # Conectar a Redis (DB 0 por defecto)
        r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True)
        
        # Idempotencia aproximada
        if r.dbsize() >= 100:
            print("✅ [Seed] Notification: Ya existen datos en Redis. Saltando.")
            return

        print("🌱 [Seed] Notification: Creando 100 claves en Redis...")
        pipe = r.pipeline()
        for i in range(100):
            pipe.setex(f"notify:seed:{i}", 3600, f"Notification content {i}")
        pipe.execute()
        
        print("✅ [Seed] Notification: Carga completa.")
    except Exception as e:
        print(f"❌ [Seed] Error conectando a Redis: {e}")

if __name__ == '__main__':
    seed()