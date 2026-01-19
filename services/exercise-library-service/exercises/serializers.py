from rest_framework import serializers
from .models import MuscleGroup, SubGroup, Exercise, FullRoutineVideo
import uuid

class ExerciseSerializer(serializers.Serializer):
    uid = serializers.UUIDField(default=uuid.uuid4)
    name = serializers.CharField(max_length=200)
    description = serializers.CharField(allow_blank=True, required=False)
    short_video_url = serializers.URLField(allow_blank=True, required=False)
    thumbnail_url = serializers.URLField(allow_blank=True, required=False)
    needs_weight = serializers.BooleanField(default=True)

class SubGroupSerializer(serializers.Serializer):
    uid = serializers.UUIDField(default=uuid.uuid4)
    name = serializers.CharField(max_length=100)
    min_exercises = serializers.IntegerField(default=2)
    max_exercises = serializers.IntegerField(default=3)
    exercises = ExerciseSerializer(many=True)

class MuscleGroupSerializer(serializers.ModelSerializer):
    subgroups = SubGroupSerializer(many=True)
    
    class Meta:
        model = MuscleGroup
        fields = '__all__'
        
    def create(self, validated_data):
        # Djongo maneja la creación anidada automáticamente si los datos coinciden
        return super().create(validated_data)

class FullRoutineVideoSerializer(serializers.ModelSerializer):
    class Meta:
        model = FullRoutineVideo
        fields = '__all__'