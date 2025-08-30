# Kubernetes кластер з ECR та Helm

Цей проект розширює попередню інфраструктуру Terraform для створення Kubernetes кластера (EKS) з інтеграцією ECR та Helm чартами для розгортання Django додатку.

## Структура проекту

```
lesson-7/
│
├── main.tf              # Основний файл для підключення модулів
├── backend.tf           # Конфігурація backend для станів (S3 + DynamoDB)
├── outputs.tf           # Загальні виходи ресурсів
│
├── modules/             # Директорія з усіма модулями
│   ├── s3-backend/      # Модуль для S3 та DynamoDB
│   │   ├── s3.tf        # Створення S3 bucket
│   │   ├── dynamodb.tf  # Створення DynamoDB
│   │   ├── variables.tf # Змінні для S3
│   │   └── outputs.tf   # Виходи для S3 та DynamoDB
│   │
│   ├── vpc/             # Модуль для VPC
│   │   ├── vpc.tf       # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf    # Налаштування маршрутизації
│   │   ├── variables.tf # Змінні для VPC
│   │   └── outputs.tf   # Виходи VPC та підмереж
│   │
│   ├── ecr/             # Модуль для ECR
│   │   ├── ecr.tf       # Створення ECR репозиторію
│   │   ├── variables.tf # Змінні для ECR
│   │   └── outputs.tf   # Вивід URL репозиторію
│   │
│   ├── eks/             # Модуль для Kubernetes кластера
│   │   ├── eks.tf       # Створення EKS кластера та групи вузлів
│   │   ├── variables.tf # Змінні для EKS
│   │   └── outputs.tf   # Виходи інформації про кластер
│
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   ├── hpa.yaml
│       │   ├── serviceaccount.yaml
│       │   └── _helpers.tpl
│       ├── Chart.yaml
│       └── values.yaml  # ConfigMap з змінними середовища
```

## Передумови

- AWS CLI налаштований з відповідними обліковими даними
- Terraform встановлений (версія >= 1.0)
- kubectl встановлений
- Helm встановлений (версія >= 3.0)
- Docker встановлений та налаштований

## Компоненти інфраструктури

### 1. VPC Модуль
- Створює VPC з CIDR блоком 10.0.0.0/16
- 3 публічні підмережі по зонах доступності
- 3 приватні підмережі по зонах доступності
- Internet Gateway для публічного доступу
- Таблиці маршрутизації для правильної роботи мережі

### 2. ECR Модуль
- Створює Elastic Container Registry репозиторій
- Включає сканування образів при завантаженні
- Надає URL репозиторію для завантаження Docker образів

### 3. EKS Модуль
- Створює EKS кластер в приватних підмережах
- Налаштовує групу вузлів з екземплярами t3.medium
- Налаштовує IAM ролі та політики
- Конфігурує групи безпеки
- Включає автомасштабування (1-6 вузлів)

### 4. Helm Чарт
- Deployment з Django додатком
- LoadBalancer сервіс для зовнішнього доступу
- Horizontal Pod Autoscaler (2-6 подів, поріг 70% CPU)
- ConfigMap для змінних середовища
- ServiceAccount для дозволів подів

## Кроки розгортання

### Крок 1: Розгортання інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Планування розгортання
terraform plan

# Застосування інфраструктури
terraform apply
```

### Крок 2: Налаштування kubectl

Після успішного розгортання налаштуйте kubectl для доступу до EKS кластера:

```bash
# Отримати команду kubeconfig з виходів
terraform output kubeconfig_command

# Виконати команду (замінити на фактичний вивід)
aws eks update-kubeconfig --region eu-central-1 --name lesson-7-eks

# Перевірити доступ до кластера
kubectl get nodes
```

### Крок 3: Збірка та завантаження Docker образу

```bash
# Отримати URL ECR репозиторію
terraform output ecr_repo_url

# Вхід в ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repo_url)

# Збірка Django образу (припускаючи, що у вас є код Django додатку)
docker build -t django-app .

# Тегування образу
docker tag django-app:latest $(terraform output -raw ecr_repo_url):latest

# Завантаження в ECR
docker push $(terraform output -raw ecr_repo_url):latest
```

### Крок 4: Розгортання Django додатку з Helm

```bash
# Перейти в директорію charts
cd charts/django-app

# Оновити values.yaml з URL ECR репозиторію
# Замінити значення image.repository на ваш ECR URL

# Встановити Helm чарт
helm install django-app . --namespace default --create-namespace

# Перевірити статус розгортання
kubectl get pods
kubectl get services
kubectl get hpa
```

### Крок 5: Перевірка розгортання

```bash
# Перевірити статус подів
kubectl get pods -l app.kubernetes.io/name=django-app

# Перевірити сервіс
kubectl get svc -l app.kubernetes.io/name=django-app

# Перевірити HPA
kubectl get hpa

# Перевірити ConfigMap
kubectl get configmap -l app.kubernetes.io/name=django-app

# Отримати зовнішню IP (LoadBalancer)
kubectl get svc django-app -o wide
```

## Змінні середовища

Додаток використовує ConfigMap для змінних середовища. Ключові змінні включають:

- `DEBUG`: Режим налагодження Django
- `SECRET_KEY`: Секретний ключ Django
- `ALLOWED_HOSTS`: Дозволені імена хоста
- `DATABASE_URL`: Рядок підключення до бази даних
- `CORS_ALLOWED_ORIGINS`: Конфігурація CORS
- `REDIS_URL`: Рядок підключення до Redis
- `EMAIL_BACKEND`: Конфігурація email backend
- `STATIC_URL` та `MEDIA_URL`: URL для статичних/медіа файлів
- `LOG_LEVEL`: Рівень логування

## Конфігурація автомасштабування

- **Автомасштабування подів**: 2-6 реплік на основі використання CPU (поріг 70%)
- **Автомасштабування вузлів**: 1-6 вузлів на основі потреби кластера
- **Ліміти ресурсів**: CPU: 500m, Memory: 512Mi
- **Запити ресурсів**: CPU: 250m, Memory: 256Mi

## Моніторинг та діагностика

### Перевірка статусу кластера
```bash
kubectl cluster-info
kubectl get nodes
kubectl top nodes
```

### Перевірка статусу додатку
```bash
kubectl get pods -l app.kubernetes.io/name=django-app
kubectl logs -l app.kubernetes.io/name=django-app
kubectl describe pod <pod-name>
```

### Перевірка статусу HPA
```bash
kubectl get hpa
kubectl describe hpa django-app
```

### Перевірка сервісу та Load Balancer
```bash
kubectl get svc
kubectl describe svc django-app
```

## Очищення

Для видалення всіх ресурсів:

```bash
# Видалити Helm release
helm uninstall django-app

# Знищити інфраструктуру Terraform
terraform destroy
```