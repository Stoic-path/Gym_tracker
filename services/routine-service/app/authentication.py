import jwt
from django.conf import settings
from rest_framework import authentication, exceptions
from django.contrib.auth import get_user_model

class StatelessUser:
    """
    A User-like object that takes data from the JWT payload
    without hitting the database.
    """
    def __init__(self, payload):
        self.id = payload.get('user_id')
        self.username = payload.get('email', '')  # Adjust based on your JWT claims
        self.email = payload.get('email', '')
        self.is_authenticated = True
        self.is_anonymous = False
        self.is_staff = False  # Or derive from roles in payload
        self.is_superuser = False

    def __str__(self):
        return f"StatelessUser(id={self.id}, email={self.email})"

class StatelessJWTAuthentication(authentication.BaseAuthentication):
    """
    Authentication class that validates the JWT signature
    but avoids database lookup for the User.
    Important: Requires SIMPLE_JWT settings to be configured (SIGNING_KEY).
    """

    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return None

        try:
            # Bearer <token>
            prefix, token = auth_header.split()
            if prefix.lower() != 'bearer':
                return None
        except ValueError:
            return None

        from rest_framework_simplejwt.settings import api_settings
        from rest_framework_simplejwt.tokens import UntypedToken
        from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

        try:
            # Validate token structure and signature using SimpleJWT logic
            UntypedToken(token)
            
            # Decode payload manually (since we skip the database check)
            # SimpleJWT's UntypedToken already verified signature against settings.SECRET_KEY (or SIGNING_KEY)
            decoded_data = jwt.decode(
                token, 
                settings.SECRET_KEY, 
                algorithms=[settings.SIMPLE_JWT.get('ALGORITHM', 'HS256')] if hasattr(settings, 'SIMPLE_JWT') else ['HS256']
            )

        except (InvalidToken, TokenError, jwt.DecodeError) as e:
            raise exceptions.AuthenticationFailed(f'Invalid token: {str(e)}')

        return (StatelessUser(decoded_data), token)
