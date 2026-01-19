from rest_framework import serializers
from .models import Routine, RoutineGroup, RoutineExercise

class RoutineExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoutineExercise
        fields = ['id', 'subgroup_name', 'exercise_name', 'exercise_id', 'target_sets', 'target_reps']

class RoutineGroupSerializer(serializers.ModelSerializer):
    exercises = RoutineExerciseSerializer(many=True)

    class Meta:
        model = RoutineGroup
        fields = ['id', 'name', 'code', 'exercises']

class RoutineSerializer(serializers.ModelSerializer):
    groups = RoutineGroupSerializer(many=True)

    class Meta:
        model = Routine
        fields = ['id', 'user_id', 'name', 'created_at', 'is_active', 'groups']
        read_only_fields = ['user_id', 'created_at']

    def validate(self, data):
        """
        Valida reglas de negocio: 2 min, 3 max ejercicios por subgrupo.
        """
        groups = data.get('groups', [])
        for group in groups:
            exercises = group.get('exercises', [])
            
            # Agrupar ejercicios por subgrupo para contarlos
            subgroup_counts = {}
            for ex in exercises:
                subg = ex.get('subgroup_name')
                subgroup_counts[subg] = subgroup_counts.get(subg, 0) + 1
            
            # Verificar conteos
            for subg, count in subgroup_counts.items():
                if count < 2:
                    raise serializers.ValidationError(
                        f"El subgrupo '{subg}' debe tener al menos 2 ejercicios (tienes {count})."
                    )
                if count > 3:
                    raise serializers.ValidationError(
                        f"El subgrupo '{subg}' no puede tener más de 3 ejercicios (tienes {count})."
                    )
        return data

    def create(self, validated_data):
        """
        Creación anidada manual (Routine -> Groups -> Exercises)
        """
        groups_data = validated_data.pop('groups')
        routine = Routine.objects.create(**validated_data)
        
        for group_data in groups_data:
            exercises_data = group_data.pop('exercises')
            group = RoutineGroup.objects.create(routine=routine, **group_data)
            
            for exercise_data in exercises_data:
                RoutineExercise.objects.create(group=group, **exercise_data)
                
        return routine
