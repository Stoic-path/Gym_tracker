"""
URL configuration for app project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

class AnalyticsSummaryView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        return Response({
            "total_workouts": 142,
            "calories_burned": 35000,
            "current_streak": 5,
            "favorite_muscle": "Chest",
            "source": "Analytics Service (Instance #7)"
        })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/analytics/summary', AnalyticsSummaryView.as_view()),
]
