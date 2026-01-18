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
from django.http import JsonResponse
from analytics.views import AnalyticsSummaryView

def health_check(request):
    return JsonResponse({"status": "healthy", "service": "analytics-service"})

def root_view(request):
    return JsonResponse({"message": "Analytics Service API", "endpoints": ["/api/analytics/summary", "/health"]})

urlpatterns = [
    path('', root_view),
    path('health/', health_check),
    path('admin/', admin.site.urls),
    # Ruta específica para el resumen de estadísticas
    path('api/analytics/summary', AnalyticsSummaryView.as_view()),
]
