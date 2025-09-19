from django.http import JsonResponse, HttpResponse
from django.shortcuts import render
from prometheus_client import Counter, Histogram, generate_latest
import time

# Метрики
REQUEST_COUNT = Counter('django_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('django_request_duration_seconds', 'Request duration')


def index(request):
    start_time = time.time()
    
    # Логіка обробки запиту
    response_data = {
        'message': 'Hello from Django app!',
        'status': 'success'
    }
    
    # Запис метрик
    REQUEST_COUNT.labels(method=request.method, endpoint='/').inc()
    REQUEST_DURATION.observe(time.time() - start_time)
    
    return JsonResponse(response_data)


def health(request):
    start_time = time.time()
    
    response_data = {
        'status': 'healthy',
        'service': 'django-app'
    }
    
    # Запис метрик
    REQUEST_COUNT.labels(method=request.method, endpoint='/health/').inc()
    REQUEST_DURATION.observe(time.time() - start_time)
    
    return JsonResponse(response_data)


def metrics(request):
    """Endpoint для Prometheus метрик"""
    return HttpResponse(generate_latest(), content_type='text/plain')
