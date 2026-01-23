"""
URL configuration for app project.
"""
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.conf import settings
from django.conf import settings

class WorkoutHistoryView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            # Usamos la conexión ya establecida en settings
            db = settings.mongo_db
            if db is None:
                return Response({"error": "MongoDB connection not initialized"}, status=500)

            collection = db["workouts"]
            
            # Retrieve data, excluding Mongo internal _id field
            data = list(collection.find({}, {"_id": 0}))
            
            if not data:
                return Response({"message": "Connected to Mongo, but no workouts found!"})

            return Response(data)
        except Exception as e:
            return Response({"error": "Mongo Query Error", "details": str(e)}, status=500)

def health_check(request):
    return HttpResponse("OK", status=200)

urlpatterns = [
    path('', health_check),
    path("admin/", admin.site.urls),
    path("api/workouts/query/history", WorkoutHistoryView.as_view()),
]
