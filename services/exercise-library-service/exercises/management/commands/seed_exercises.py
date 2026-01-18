import uuid
from django.core.management.base import BaseCommand
from exercises.models import MuscleGroup

class Command(BaseCommand):
    help = 'Pobla la base de datos con la estructura de ejercicios inicial'

    def handle(self, *args, **kwargs):
        self.stdout.write('Eliminando datos antiguos...')
        MuscleGroup.objects.all().delete()

        # --- FUNCIONES HELPER PARA GENERAR DICCIONARIOS COMPLETOS ---
        # Djongo requiere que todos los campos del modelo embebido estén presentes en el diccionario,
        # incluso si tienen valores por defecto o son nulos en el modelo.
        
        def make_exercise(name, description="", needs_weight=True):
            return {
                "uid": uuid.uuid4(),
                "name": name,
                "description": description,
                "needs_weight": needs_weight,
                "short_video_url": None,
                "thumbnail_url": None
            }

        def make_subgroup(name, exercises_list, min_exercises=2, max_exercises=3):
            return {
                "uid": uuid.uuid4(),
                "name": name,
                "min_exercises": min_exercises,
                "max_exercises": max_exercises,
                "exercises": exercises_list
            }

        # --- DEFINICIÓN DE DATOS ---
        
        # 1. GRUPO PÚRPURA (Pecho, Bíceps, Glúteo-Lumbar)
        purple = MuscleGroup(
            name="Púrpura",
            code="PURPLE",
            hex_color="#800080",
            description="Enfoque en Pectorales, Bíceps y Glúteo/Lumbar",
            subgroups=[
                make_subgroup("Pectorales", [
                    make_exercise("Press de Banca Plano", "Barra o mancuernas"),
                    make_exercise("Aperturas (Flyes)", "Mancuernas o máquina"),
                    make_exercise("Flexiones (Push-ups)", "Peso corporal", needs_weight=False),
                    make_exercise("Press Inclinado", "Enfoque clavicular")
                ]),
                make_subgroup("Bíceps", [
                    make_exercise("Curl con Barra", "De pie"),
                    make_exercise("Curl Martillo", "Mancuernas"),
                    make_exercise("Curl Predicador", "Banco Scott")
                ]),
                make_subgroup("Glúteo-Lumbar", [
                    make_exercise("Hip Thrust", "Empuje de cadera"),
                    make_exercise("Peso Muerto Rumano", "Enfoque femoral/glúteo"),
                    make_exercise("Extensiones Lumbares", "Banco o máquina")
                ])
            ]
        )
        purple.save()

        # 2. GRUPO ROJO (Tríceps, Dorsal, Trapecio)
        red = MuscleGroup(
            name="Rojo",
            code="RED",
            hex_color="#FF0000",
            description="Enfoque en Tríceps, Espalda (Dorsal) y Trapecio",
            subgroups=[
                make_subgroup("Tríceps", [
                    make_exercise("Extensiones en Polea", "Cuerda o barra"),
                    make_exercise("Press Francés", "Barra Z"),
                    make_exercise("Fondos en Paralelas", "Peso corporal o lastre")
                ]),
                make_subgroup("Dorsales", [
                    make_exercise("Jalón al Pecho", "Polea alta"),
                    make_exercise("Remo con Barra", "Inclinado"),
                    make_exercise("Dominadas", "Peso corporal o asistidas", needs_weight=False)
                ]),
                make_subgroup("Trapecio", [
                    make_exercise("Encogimientos", "Mancuernas o barra"),
                    make_exercise("Remo al Mentón", "Cuidado con los hombros")
                ])
            ]
        )
        red.save()

        # 3. GRUPO AZUL (Abdominales, Deltoides)
        blue = MuscleGroup(
            name="Azul",
            code="BLUE",
            hex_color="#0000FF",
            description="Enfoque en Hombros y Core",
            subgroups=[
                make_subgroup("Abdominales", [
                    make_exercise("Crunch", needs_weight=False),
                    make_exercise("Elevación de Piernas", needs_weight=False),
                    make_exercise("Plancha", needs_weight=False)
                ]),
                make_subgroup("Deltoides Posterior", [
                    make_exercise("Pájaros (Vuelos posteriores)", "Mancuernas")
                ]),
                make_subgroup("Deltoides Frontal/Lateral", [
                    make_exercise("Elevaciones Laterales", "Mancuernas"),
                    make_exercise("Elevaciones Frontales", "Disco o mancuernas")
                ]),
                make_subgroup("Press de Hombro", [
                    make_exercise("Press Militar", "Barra o mancuernas de pie/sentado"),
                    make_exercise("Press Arnold", "Mancuernas con giro")
                ])
            ]
        )
        blue.save()

        # 4. GRUPO PIEL (Pierna General)
        skin = MuscleGroup(
            name="Piel",
            code="SKIN",
            hex_color="#D2B48C",
            description="Enfoque en Tren Inferior Completo",
            subgroups=[
                make_subgroup("General Pierna", [
                    make_exercise("Sentadilla Libre", "Barra trasera"),
                    make_exercise("Prensa de Piernas", "Máquina inclinada")
                ]),
                make_subgroup("Cuádriceps", [
                    make_exercise("Extensiones de Cuádriceps", "Máquina"),
                    make_exercise("Zancadas (Lunges)", "Caminando o estáticas")
                ]),
                make_subgroup("Isquiotibiales", [
                    make_exercise("Curl Femoral Tumbado", "Máquina"),
                    make_exercise("Curl Femoral Sentado", "Máquina")
                ]),
                make_subgroup("Gemelos", [
                    make_exercise("Elevación de Talones de Pie", "Máquina o multipower"),
                    make_exercise("Elevación de Talones Sentado", "Máquina sóleo")
                ])
            ]
        )
        skin.save()

        self.stdout.write(self.style.SUCCESS('¡Base de datos poblada exitosamente con 4 grupos y sus ejercicios!'))