"""
URL configuration for app project.
"""
from django.contrib import admin
from django.urls import path
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.conf import settings
import pymongo

class WorkoutHistoryView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            client = pymongo.MongoClient(settings.MONGO_URI)
            db = client["gym_workouts_db"]
            collection = db["workouts"]
            
            # Retrieve data, excluding Mongo internal _id field
            data = list(collection.find({}, {"_id": 0}))
            
            if not data:
                return Response({"message": "Connected to Mongo, but no workouts found!"})

            return Response(data)
        except Exception as e:
            return Response({"error": "Mongo Connection Failed", "details": str(e)}, status=500)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/workouts/query/history", WorkoutHistoryView.as_view()),
]
