from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MuscleGroupViewSet, FullRoutineVideoViewSet, PresignedURLView

router = DefaultRouter()
router.register(r'groups', MuscleGroupViewSet)
router.register(r'videos', FullRoutineVideoViewSet)

urlpatterns = [
    path('upload-url/', PresignedURLView.as_view(), name='upload-url'),
    path('', include(router.urls)),
]