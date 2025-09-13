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