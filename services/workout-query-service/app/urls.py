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

from pymongo import MongoClient
import os

def get_mongo_db():
    conn_str = getattr(settings, 'MONGO_URI', None)
    if not conn_str:
        # Fallback manual construction if settings.MONGO_URI is missing
        host = os.environ.get('MONGO_HOST', 'localhost')
        port = os.environ.get('MONGO_PORT', '27017')
        user = os.environ.get('MONGO_USER', 'gym_mongo_user')
        password = os.environ.get('MONGO_PASS', 'gym_mongo_pass_dev')
        auth_src = os.environ.get('MONGO_AUTH_SOURCE', 'admin')
        if user and password:
            conn_str = f"mongodb://{user}:{password}@{host}:{port}/?authSource={auth_src}"
        else:
            conn_str = f"mongodb://{host}:{port}/"
            
    client = MongoClient(conn_str, serverSelectionTimeoutMS=5000)
    db_name = getattr(settings, 'MONGO_DB_NAME', 'workout_query_db')
    return client[db_name]

class WorkoutHistoryView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            # Connect explicitly to avoid "settings.mongo_db" ambiguity
            db = get_mongo_db()
            
            collection = db["workouts"]
            
            # Retrieve data, excluding Mongo internal _id field
            data = list(collection.find({}, {"_id": 0}))
            
            # Allow empty list (200 OK) instead of just message
            return Response(data if data else [])
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({"error": "Mongo Query Error", "details": str(e)}, status=500)


def health_check(request):
    return HttpResponse("OK", status=200)

urlpatterns = [
    path('', health_check),
    path("admin/", admin.site.urls),
    path("api/workouts/query/history", WorkoutHistoryView.as_view()),
]
