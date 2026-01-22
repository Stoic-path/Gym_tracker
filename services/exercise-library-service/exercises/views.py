import boto3
from django.conf import settings
from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import MuscleGroup, FullRoutineVideo
from .serializers import MuscleGroupSerializer, FullRoutineVideoSerializer

class MuscleGroupViewSet(viewsets.ModelViewSet):
    queryset = MuscleGroup.objects.all()
    serializer_class = MuscleGroupSerializer

class FullRoutineVideoViewSet(viewsets.ModelViewSet):
    queryset = FullRoutineVideo.objects.all()
    serializer_class = FullRoutineVideoSerializer

class PresignedURLView(APIView):
    """
    Genera una URL temporal para subir archivos directamente a S3.
    Uso: POST /api/exercises/upload-url/
    Body: { "file_name": "press_banca.mp4", "file_type": "video/mp4" }
    """
    def post(self, request):
        file_name = request.data.get('file_name')
        file_type = request.data.get('file_type')
        
        if not file_name or not file_type:
            return Response({"error": "Faltan parámetros"}, status=status.HTTP_400_BAD_REQUEST)

        s3_client = boto3.client('s3', region_name=settings.AWS_REGION_NAME)
        bucket_name = settings.AWS_STORAGE_BUCKET_NAME

        try:
            # Generar la URL prefirmada para PUT (subida)
            presigned_url = s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': f"videos/{file_name}",
                    'ContentType': file_type
                },
                ExpiresIn=3600  # 60 minutos (para archivos grandes de 1.5GB)
            )
            
            # URL pública final (para guardar en la DB)
            public_url = f"https://{bucket_name}.s3.amazonaws.com/videos/{file_name}"
            
            return Response({
                "upload_url": presigned_url,
                "public_url": public_url
            })
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)