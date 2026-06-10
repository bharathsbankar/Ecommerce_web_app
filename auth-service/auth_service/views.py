import os
import jwt
import json
from datetime import datetime, timedelta
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import get_user_model

User = get_user_model()
JWT_SECRET = os.environ.get('JWT_SECRET', 'fallback_secret_key_change_in_production')

@csrf_exempt
def register_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        email = data.get('email')
        username = data.get('username')
        password = data.get('password')
        role = data.get('role', 'customer')
        
        if not email or not username or not password:
            return JsonResponse({'error': 'Email, username, and password are required'}, status=400)
            
        if role not in ['customer', 'admin']:
            return JsonResponse({'error': 'Invalid role'}, status=400)
            
        if User.objects.filter(email=email).exists():
            return JsonResponse({'error': 'Email already registered'}, status=400)
            
        if User.objects.filter(username=username).exists():
            return JsonResponse({'error': 'Username already taken'}, status=400)
            
        user = User.objects.create_user(email=email, username=username, password=password, role=role)
        return JsonResponse({
            'message': 'Registration successful',
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'role': user.role
            }
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Malformed JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def login_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
        
    try:
        data = json.loads(request.body)
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return JsonResponse({'error': 'Email and password are required'}, status=400)
            
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return JsonResponse({'error': 'Invalid credentials'}, status=401)
            
        if not user.check_password(password):
            return JsonResponse({'error': 'Invalid credentials'}, status=401)
            
        # Sign JWT with user details and expiration timestamp
        payload = {
            'user_id': user.id,
            'email': user.email,
            'role': user.role,
            'exp': datetime.utcnow() + timedelta(hours=24)
        }
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256', headers={'kid': 'flashsale-key-id'})
        
        # Decodes bytes token to string if using older PyJWT
        if isinstance(token, bytes):
            token = token.decode('utf-8')
            
        return JsonResponse({
            'token': token,
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'role': user.role
            }
        }, status=200)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Malformed JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
