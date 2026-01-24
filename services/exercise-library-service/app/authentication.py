import jwt
from django.conf import settings
from rest_framework import authentication, exceptions


class StatelessUser:
    """
    A User-like object that takes data from the JWT payload
    without hitting the database.
    """
    def __init__(self, payload):
        self.id = payload.get('user_id')
        self.username = payload.get('email', '')
        self.email = payload.get('email', '')
        self.is_authenticated = True
        self.is_anonymous = False
        self.is_active = True
        self.is_staff = False
        self.is_superuser = False

    @property
    def pk(self):
        return self.id

    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser

    @property
    def groups(self):
        class MockManager:
            def all(self):
                return []
        return MockManager()

    @property
    def user_permissions(self):
        class MockManager:
            def all(self):
                return []
        return MockManager()

    def __str__(self):
        return f"StatelessUser(id={self.id}, email={self.email})"


class StatelessJWTAuthentication(authentication.BaseAuthentication):
    """
    Authentication class that validates the JWT signature
    but avoids database lookup for the User.
    """

    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return None

        try:
            prefix, token = auth_header.split()
            if prefix.lower() != 'bearer':
                return None
        except ValueError:
            return None

        from rest_framework_simplejwt.tokens import UntypedToken
        from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

        try:
            UntypedToken(token)
            decoded_data = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.SIMPLE_JWT.get('ALGORITHM', 'HS256')]
                if hasattr(settings, 'SIMPLE_JWT') else ['HS256'],
            )
        except (InvalidToken, TokenError, jwt.DecodeError) as e:
            raise exceptions.AuthenticationFailed(f'Invalid token: {str(e)}')

        return (StatelessUser(decoded_data), token)
