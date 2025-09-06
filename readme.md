# CI/CD Pipeline з Jenkins + Helm + Terraform + Argo CD

Цей проект реалізує повний процес CI/CD з використанням Jenkins + Helm + Terraform + Argo CD для Django додатку, розгорнутого на AWS EKS.

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
```

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