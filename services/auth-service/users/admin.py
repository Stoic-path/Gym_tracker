from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    """
    Admin View Configuration for CustomUser.
    Orders by email and controls which fields are displayed in the list.
    """

    ordering = ("email",)
    list_display = ("email", "first_name", "user_type", "is_staff", "is_active", "id")
    search_fields = ("email", "first_name", "last_name")

    # Configuration to avoid errors with 'username' field which no longer exists
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("first_name", "last_name", "user_type")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )

    # Configuration for the "Add User" page
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "email",
                    "password",
                    "first_name",
                    "last_name",
                    "user_type",
                    "is_staff",
                    "is_superuser",
                    "is_active",
                ),
            },
        ),
    )
