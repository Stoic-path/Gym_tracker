from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WorkoutCommandViewSet

router = DefaultRouter()
router.register(r'commands', WorkoutCommandViewSet, basename='workout-command')

urlpatterns = [
    path('', include(router.urls)),
]