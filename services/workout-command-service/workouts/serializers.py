from rest_framework import serializers
from .models import WorkoutCommand

class WorkoutCommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkoutCommand
        fields = ['id', 'user_id', 'name', 'notes', 'status', 'started_at', 'completed_at']
        read_only_fields = ['id', 'user_id', 'created_at'] # user_id no se edita, se lee del token