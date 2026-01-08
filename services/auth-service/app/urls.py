from django.contrib import admin
from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # JWT Auth Endpoints
    # POST /api/token/ -> Login (Send email/password, receive tokens)
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # POST /api/token/refresh/ -> Refresh access token using refresh token
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # POST /api/token/verify/ -> Check if a token is valid
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]