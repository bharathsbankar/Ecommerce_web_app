from django.urls import path
from auth_service.views import register_view, login_view

urlpatterns = [
    path('api/auth/register', register_view, name='register'),
    path('api/auth/login', login_view, name='login'),
]
