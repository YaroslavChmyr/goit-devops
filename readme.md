# AWS Infrastructure as Code з Terraform + EKS + Jenkins + Argo CD

Цей проект реалізує повну інфраструктуру AWS з використанням Terraform для розгортання EKS кластера, Jenkins, Argo CD та Django додатку з моніторингом Prometheus/Grafana.

## Швидкий старт

### Передумови
- AWS CLI налаштований з відповідними правами
- Terraform >= 1.0
- kubectl
- helm

### Розгортання інфраструктури

1. **Клонуйте репозиторій:**
```bash
git clone <repository-url>
cd goit-devops
```

2. **Ініціалізуйте Terraform:**
```bash
terraform init
```

3. **Перегляньте план розгортання:**
```bash
terraform plan
```

4. **Розгорніть інфраструктуру:**
```bash
terraform apply
```

5. **Налаштуйте kubectl:**
```bash
aws eks update-kubeconfig --region eu-central-1 --name lesson-7-eks
```

6. **Встановіть Prometheus та Grafana:**
```bash
# Створіть namespace
kubectl create namespace monitoring

# Встановіть Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
```

7. **Застосуйте ServiceMonitor для Django:**
```bash
kubectl apply -f monitoring/django-servicemonitor.yaml
```

### Доступ до сервісів

- **Jenkins**: `kubectl port-forward svc/jenkins 8080:8080` → http://localhost:8080
- **Argo CD**: `kubectl port-forward svc/argocd-server 8080:80` → http://localhost:8080
- **Grafana**: `kubectl port-forward svc/prometheus-grafana 3000:80` → http://localhost:3000
- **Prometheus**: `kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090` → http://localhost:9090

### Видалення інфраструктури

⚠️ **УВАГА**: Це видалить всю інфраструктуру AWS!

```bash
# Видаліть Prometheus та Grafana
helm uninstall prometheus -n monitoring

# Видаліть namespace моніторингу
kubectl delete namespace monitoring

# Видаліть всю інфраструктуру Terraform
terraform destroy
```

## Структура проекту

```
Project/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf  
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── eks/                 # Модуль для Kubernetes кластера
│   │   ├── eks.tf           # Створення кластера
│   │   ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi drive
│   │   ├── variables.tf     # Змінні для EKS
│   │   └── outputs.tf       # Виведення інформації про кластер
│   │
│   ├── jenkins/             # Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   ├── values.yaml      # Конфігурація jenkins
│   │   └── outputs.tf       # Виводи (URL, пароль адміністратора)
│   │ 
│   ├── rds/                 # Модуль для RDS бази даних
│   │   ├── rds.tf           # Створення RDS бази даних  
│   │   ├── aurora.tf        # Створення aurora кластера бази даних  
│   │   ├── shared.tf        # Спільні ресурси  
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   └── outputs.tf       # Виводи (endpoint, port, engine тощо)
│   │ 
│   └── argo_cd/             # Модуль для Helm-установки Argo CD
│       ├── argo_cd.tf       # Helm release для Argo CD
│       ├── variables.tf     # Змінні (версія чарта, namespace, repo URL тощо)
│       ├── values.yaml      # Кастомна конфігурація Argo CD
│       ├── outputs.tf       # Виводи (hostname, initial admin password)
│       └── charts/          # Helm-чарт для створення app'ів
│           ├── Chart.yaml
│           ├── values.yaml  # Список applications, repositories
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища
│
├── Django/                 # Django додаток
│   ├── app/               # Django додаток з моделями, views, urls
│   ├── django_project/    # Налаштування Django проекту
│   ├── Dockerfile         # Docker образ для Django
│   ├── Jenkinsfile        # CI/CD pipeline для Jenkins
│   └── requirements.txt   # Python залежності
│
└── monitoring/            # Конфігурація моніторингу
    ├── django-servicemonitor.yaml
    ├── grafana-ingress.yaml
    └── prometheus-ingress.yaml
```

## Модуль RDS

Універсальний модуль RDS підтримує як звичайні RDS інстанси, так і Aurora кластери. Модуль автоматично створює всі необхідні ресурси: DB Subnet Group, Security Group, Parameter Group та IAM ролі для моніторингу.

### Приклад використання модуля

#### Звичайний RDS інстанс (PostgreSQL)
```hcl
module "rds" {
  source = "./modules/rds"

  # Базова конфігурація
  use_aurora      = false
  db_name         = "lesson5db"
  master_username = "admin"
  master_password = "SecurePassword123!"

  # Налаштування двигуна
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  # Мережева конфігурація
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Безпека
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  # Високий рівень доступності
  multi_az = false

  # Резервне копіювання
  backup_retention_period = 7
  skip_final_snapshot     = true

  # Захист від видалення
  deletion_protection = false

  tags = {
    Environment = "lesson-5"
    Project     = "goit-devops"
  }

  depends_on = [module.vpc]
}
```

#### Aurora кластер (PostgreSQL)
```hcl
module "rds_aurora" {
  source = "./modules/rds"

  # Базова конфігурація
  use_aurora      = true
  db_name         = "lesson5db-aurora"
  master_username = "admin"
  master_password = "SecurePassword123!"

  # Налаштування двигуна
  engine         = "postgres"
  engine_version = "15.4"
  aurora_instance_class = "db.r5.large"
  aurora_instances_count = 2

  # Мережева конфігурація
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Безпека
  allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  # Резервне копіювання
  backup_retention_period = 7
  skip_final_snapshot     = true

  # Захист від видалення
  deletion_protection = false

  tags = {
    Environment = "lesson-5"
    Project     = "goit-devops"
  }

  depends_on = [module.vpc]
}
```

### Опис змінних модуля

#### Основні змінні

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `use_aurora` | `bool` | `false` | Чи створювати Aurora кластер замість звичайного RDS інстансу |
| `db_name` | `string` | - | Назва бази даних (обов'язково) |
| `master_username` | `string` | - | Майстер-користувач бази даних (обов'язково) |
| `master_password` | `string` | - | Пароль майстер-користувача (обов'язково, sensitive) |

#### Налаштування двигуна

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `engine` | `string` | `"postgres"` | Тип двигуна БД (`postgres`, `mysql`) |
| `engine_version` | `string` | `"15.4"` | Версія двигуна БД |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу для RDS |
| `multi_az` | `bool` | `false` | Чи увімкнути Multi-AZ розгортання |

#### Налаштування Aurora

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `aurora_instance_class` | `string` | `"db.r5.large"` | Клас інстансу для Aurora |
| `aurora_instances_count` | `number` | `2` | Кількість інстансів в Aurora кластері |
| `aurora_cluster_identifier` | `string` | `null` | Ідентифікатор Aurora кластера (автоматично генерується) |

#### Налаштування сховища

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `allocated_storage` | `number` | `20` | Розмір сховища в ГБ (тільки для RDS) |
| `max_allocated_storage` | `number` | `100` | Максимальний розмір сховища в ГБ (тільки для RDS) |
| `storage_type` | `string` | `"gp2"` | Тип сховища (тільки для RDS) |

#### Налаштування резервного копіювання

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `backup_retention_period` | `number` | `7` | Період зберігання резервних копій (дні) |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно для резервного копіювання |
| `maintenance_window` | `string` | `"sun:04:00-sun:05:00"` | Вікно для технічного обслуговування |

#### Налаштування безпеки

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `vpc_id` | `string` | - | ID VPC для створення БД (обов'язково) |
| `subnet_ids` | `list(string)` | - | Список ID підмереж для DB Subnet Group (обов'язково) |
| `allowed_cidr_blocks` | `list(string)` | `[]` | Список CIDR блоків з дозволом доступу до БД |
| `port` | `number` | `5432` | Порт бази даних |

#### Налаштування захисту

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `deletion_protection` | `bool` | `false` | Чи увімкнути захист від видалення |
| `skip_final_snapshot` | `bool` | `false` | Чи пропустити фінальний снапшот при видаленні |
| `final_snapshot_identifier` | `string` | `null` | Ідентифікатор фінального снапшоту |

#### Додаткові налаштування

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `tags` | `map(string)` | `{}` | Додаткові теги для ресурсів |

### Як змінити тип БД, двигун, клас інстансу

#### 1. Зміна типу БД (RDS ↔ Aurora)

**Переключення на Aurora:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = true  # Зміна з false на true
  
  # Aurora-специфічні налаштування
  aurora_instance_class = "db.r5.large"
  aurora_instances_count = 2
  
  # ... інші налаштування
}
```

**Переключення на RDS:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = false  # Зміна з true на false
  
  # RDS-специфічні налаштування
  instance_class = "db.t3.micro"
  allocated_storage = 20
  
  # ... інші налаштування
}
```

#### 2. Зміна двигуна БД

**PostgreSQL:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  engine = "postgres"
  engine_version = "15.4"  # або "14.9", "13.12"
  
  # ... інші налаштування
}
```

**MySQL:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  engine = "mysql"
  engine_version = "8.0.35"  # або "5.7.44"
  
  # ... інші налаштування
}
```

#### 3. Зміна класу інстансу

**Для RDS:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = false
  instance_class = "db.t3.small"  # або "db.t3.medium", "db.m5.large"
  
  # ... інші налаштування
}
```

**Для Aurora:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = true
  aurora_instance_class = "db.r5.xlarge"  # або "db.r6g.large", "db.t4g.medium"
  
  # ... інші налаштування
}
```

#### 4. Налаштування високої доступності

**Multi-AZ для RDS:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = false
  multi_az = true  # Увімкнути Multi-AZ
  
  # ... інші налаштування
}
```

**Кілька інстансів для Aurora:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  use_aurora = true
  aurora_instances_count = 3  # Збільшити кількість інстансів
  
  # ... інші налаштування
}
```

### Виводи модуля

Модуль надає наступні виводи:

| Вивід | Опис |
|-------|------|
| `database_endpoint` | Endpoint бази даних (працює для RDS та Aurora) |
| `database_port` | Порт бази даних |
| `database_engine` | Двигун бази даних |
| `database_name` | Назва бази даних |
| `is_aurora` | Чи це Aurora кластер |
| `db_subnet_group_name` | Назва DB Subnet Group |
| `security_group_id` | ID Security Group |

### Автоматично створювані ресурси

Модуль автоматично створює:

1. **DB Subnet Group** - для розміщення БД в підмережах
2. **Security Group** - з правилами доступу до БД
3. **Parameter Group** - з базовими параметрами:
   - `max_connections = 100`
   - `log_statement = all` (PostgreSQL) / `general_log = 1` (MySQL)
   - `work_mem = 4MB` (PostgreSQL) / `slow_query_log = 1` (MySQL)
4. **IAM Role** - для розширеного моніторингу

## Передумови

1. **AWS CLI** налаштований з відповідними креденшелами
2. **Terraform** (>= 1.0)
3. **kubectl** налаштований для EKS кластера
4. **Helm** (>= 3.0)

## Як застосувати Terraform

### 1. Ініціалізація Terraform
```bash
terraform init
```

### 2. Перевірка конфігурації
```bash
terraform validate
terraform plan
```

### 3. Застосування інфраструктури
```bash
terraform apply
```

### 4. Налаштування kubectl
```bash
aws eks update-kubeconfig --region eu-central-1 --name lesson-7-eks
```

### 5. Перевірка розгортання
```bash
kubectl get nodes
kubectl get pods -A
```

## Як перевірити Jenkins job

### 1. Доступ до Jenkins
```bash
# Отримати LoadBalancer URL
kubectl get svc jenkins -n jenkins

# Або використати port-forward
kubectl port-forward svc/jenkins -n jenkins 8080:8080
```

### 2. Вхід в Jenkins
- **URL**: `http://localhost:8080` (при port-forward) або LoadBalancer URL
- **Користувач**: `admin`
- **Пароль**: `admin123`

### 3. Створення Pipeline Job
1. Натисніть **"New Item"**
2. Виберіть **"Pipeline"**
3. Назвіть job (наприклад, "django-app-pipeline")
4. В розділі **Pipeline**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: ваш репозиторій
   - **Script Path**: Jenkinsfile

### 4. Налаштування Jenkinsfile
```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:latest
                    command: ["/busybox/cat"]
                    tty: true
                    volumeMounts:
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
            """
        }
    }
    
    stages {
        stage('Build and Push') {
            steps {
                container('kaniko') {
                    sh '''
                        /kaniko/executor \
                        --context=. \
                        --dockerfile=Dockerfile \
                        --destination=381492188178.dkr.ecr.eu-central-1.amazonaws.com/lesson-5-ecr:latest
                    '''
                }
            }
        }
        
        stage('Update Helm Chart') {
            steps {
                sh '''
                    # Оновлення values.yaml з новим тегом
                    sed -i 's/tag: .*/tag: latest/' charts/django-app/values.yaml
                    git add charts/django-app/values.yaml
                    git commit -m "Update image tag to latest"
                    git push origin main
                '''
            }
        }
    }
}
```

### 5. Запуск Job
1. Натисніть **"Build Now"** на вашому pipeline
2. Переглядайте логи в **Console Output**
3. Перевірте статус кожного stage

## Як побачити результат в Argo CD

### 1. Доступ до Argo CD
```bash
# Отримати LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Або використати port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 2. Вхід в Argo CD
- **URL**: `https://localhost:8080` (при port-forward) або LoadBalancer URL
- **Користувач**: `admin`
- **Пароль**: `admin123`

### 3. Створення Application в Argo CD
1. Натисніть **"+ NEW APP"**
2. Заповніть форму:
   - **Application Name**: `django-app`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Repository URL**: ваш Git репозиторій
   - **Path**: `charts/django-app`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `default`

### 4. Перевірка синхронізації
1. Після створення application, Argo CD автоматично синхронізує
2. Переглядайте статус в колонці **SYNC STATUS**
3. Натисніть на application для деталей
4. В розділі **TREE** побачите всі ресурси Kubernetes

### 5. Моніторинг змін
- Argo CD автоматично відстежує зміни в Git репозиторії
- При push нових змін в Helm chart, Argo CD автоматично синхронізує
- Переглядайте історію синхронізації в **HISTORY**

### 6. Перевірка розгорнутого додатку
```bash
# Перевірити под'и
kubectl get pods -l app=django-app

# Перевірити сервіси
kubectl get svc -l app=django-app

# Перевірити логи
kubectl logs -l app=django-app
```

## CI/CD Pipeline Flow

1. **Code Push** → Jenkins збирає Docker образ
2. **Build & Push** → Образ пушиться в ECR
3. **Update Chart** → Helm chart values оновлюються
4. **Git Commit** → Зміни комітяться в репозиторій
5. **Argo CD Sync** → Автоматично розгортає в EKS

## Конфігурація

- **Jenkins**: Налаштований з Kaniko для збірки контейнерів
- **Argo CD**: Моніторить Git репозиторій на зміни
- **EKS**: Kubernetes кластер для розгортання додатків
- **ECR**: Реєстр контейнерів для Docker образів

## Моніторинг з Prometheus та Grafana

### Встановлення Prometheus

1. **Додайте Prometheus Helm репозиторій:**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

2. **Створіть namespace для моніторингу:**
```bash
kubectl create namespace monitoring
```

3. **Встановіть Prometheus:**
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
```

4. **Перевірте статус:**
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Доступ до Grafana

1. **Port-forward для локального доступу:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

2. **Або отримайте LoadBalancer URL:**
```bash
kubectl get svc -n monitoring prometheus-grafana
```

3. **Доступ до Grafana:**
- **URL**: `http://localhost:3000` (при port-forward) або LoadBalancer URL
- **Користувач**: `admin`
- **Пароль**: `admin123`

### Доступ до Prometheus

1. **Port-forward для локального доступу:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

2. **Доступ до Prometheus:**
- **URL**: `http://localhost:9090`

### Налаштування ServiceMonitor для Django додатку

1. **Створіть ServiceMonitor для Django:**
```yaml
# monitoring/django-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: django-app-monitor
  namespace: monitoring
  labels:
    app: django-app
spec:
  selector:
    matchLabels:
      app: django-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

2. **Застосуйте ServiceMonitor:**
```bash
kubectl apply -f monitoring/django-servicemonitor.yaml
```

### Додавання метрик до Django додатку

Django додаток вже налаштований з метриками Prometheus. Файли містять:

1. **Метрики в Django views:**
```python
# Django/app/views.py
from django.http import JsonResponse
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
```

3. **Додайте URL для метрик:**
```python
# Django/app/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('health/', views.health, name='health'),
    path('metrics/', views.metrics, name='metrics'),
]
```

4. **Оновіть Service для Django:**
```yaml
# charts/django-app/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: django-app
  labels:
    app: django-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/path: "/metrics"
spec:
  selector:
    app: django-app
  ports:
  - name: http
    port: 8000
    targetPort: 8000
  type: ClusterIP
```

### Налаштування AlertManager

1. **Перевірте AlertManager:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

2. **Доступ до AlertManager:**
- **URL**: `http://localhost:9093`

### Корисні Grafana Dashboard'и

1. **Kubernetes Cluster Dashboard:**
   - ID: `7249` (Kubernetes Cluster Monitoring)
   - Автоматично встановлюється з kube-prometheus-stack

2. **Node Exporter Dashboard:**
   - ID: `1860` (Node Exporter Full)
   - Автоматично встановлюється з kube-prometheus-stack

3. **Django App Dashboard (створіть власний):**
   - Використовуйте метрики `django_requests_total` та `django_request_duration_seconds`
   - Додайте графіки для response time, request rate, error rate

### Команди для моніторингу

```bash
# Перевірити всі метрики
kubectl get servicemonitors -n monitoring

# Перевірити логи Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Перевірити логи Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Перевірити статус AlertManager
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# Тестування метрик Django (після розгортання в EKS)
kubectl port-forward svc/django-app 8000:8000
curl http://localhost:8000/metrics
```

### Налаштування зовнішнього доступу

1. **Ingress для Grafana:**
```yaml
# monitoring/grafana-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
```

2. **Ingress для Prometheus:**
```yaml
# monitoring/prometheus-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: prometheus.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
```