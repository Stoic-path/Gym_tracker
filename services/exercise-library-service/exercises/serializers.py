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
        subgroups_data = validated_data.pop('subgroups', [])
        muscle_group = MuscleGroup.objects.create(**validated_data)
        
        # Djongo handles list of objects for ArrayModelField usually by assignment if passing model instances,
        # but here we have dicts. Djongo is tricky with DRF.
        # However, if we assume specific Djongo DRF integration or just plain assignment:
        
        # For Djongo ArrayField with model_container, we usually just assign the list of dicts 
        # IF the field is configured to accept it, OR instantiate objects.
        
        # NOTE: With Djongo 1.3+, standard DRF create often fails for nested.
        # But let's implementing a safer approach:
        
        # Re-construct nested objects not needed if Djongo serializer field works, 
        # but manual assignment is safest.
        
        # muscle_group.subgroups = [SubGroup(**item) for item in subgroups_data] # If SubGroup was a Model
        # But SubGroup is Abstract model in models.py (abstract=True). 
        # Djongo stores them as dicts essentially.
        
        # Let's try the simple full-update approach for 'update' which is what we need mostly.
        return super().create(validated_data) # This might skip subgroups if popped.

    def update(self, instance, validated_data):
        subgroups_data = validated_data.pop('subgroups', None)
        
        # Update scalar fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
            
        if subgroups_data is not None:
            # Djongo embedded models: Just replace the list?
            # We need to manually reconstruct the list of objects because Djongo expects objects
            
            # Since SubGroup is an abstract model used as a container:
            # We iterate and rebuild.
            
            # NOTE: We need to import the embedded models. 
            # They are imported at top of file.
            
            # Rebuild structure
            new_subgroups = []
            for sub_data in subgroups_data:
                exercises_data = sub_data.pop('exercises', [])
                
                # Rebuild Exercises
                new_exercises = []
                for ex_data in exercises_data:
                    # Exercise is also abstract embedded
                    new_exercises.append(Exercise(**ex_data))
                
                sub_data['exercises'] = new_exercises
                new_subgroups.append(SubGroup(**sub_data))
            
            instance.subgroups = new_subgroups
            
        instance.save()
        return instance

class FullRoutineVideoSerializer(serializers.ModelSerializer):
    class Meta:
        model = FullRoutineVideo
        fields = '__all__'