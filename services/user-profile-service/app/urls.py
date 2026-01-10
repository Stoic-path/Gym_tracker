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

from profiles.models import UserProfile

class UserProfileView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            profile = UserProfile.objects.first()
            if not profile:
                 return Response({"username": "No DB Data", "email": "seed@me.pls"}, status=200)
            
            return Response({
                "id": profile.user_id,
                "username": profile.full_name,
                "email": profile.email,
                "bio": profile.bio,
                "source": "PostgreSQL Database"
            })
        except Exception as e:
            return Response({"error": str(e)}, status=500)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/me', UserProfileView.as_view()),
]
