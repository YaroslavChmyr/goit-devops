# Terraform AWS Infrastructure Setup

Цей репозиторій містить інфраструктуру AWS, що розгортається за допомогою **Terraform**.

Оскільки бекенд (S3 + DynamoDB) ще не існує на початку, необхідно виконати **двохетапний підхід**.

---

## Попередні вимоги
1. Встановлений [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5).
2. AWS CLI з налаштованими креденшалами:
   ```bash
   aws configure
3. Достатньо прав для створення ресурсів у AWS:
    ```bash
    S3 bucket
    DynamoDB table
# Кроки по розгортанню

## 1. Підготовка
У файлі `backend.tf` визначено бекенд, який вказує на **S3** та **DynamoDB**.  
Але ці ресурси ще не створені, тому потрібно **тимчасово закоментувати** вміст `backend.tf`.

### Приклад (було):
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```
## 👉 Треба закоментувати

```hcl
# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state"
#     key            = "global/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
```
## 2. Створення S3 + DynamoDB

Запусти:

```bash
terraform init
terraform apply
```
Це створить:

- **S3 bucket** для зберігання `tfstate`
- **DynamoDB table** для блокування стану

---

## 3. Активація бекенду

Тепер можна **розкоментувати** `backend.tf`, щоб Terraform використовував віддалений бекенд.

---

## 4. Міграція стану

Виконай:

```bash
terraform init -migrate-state
```
Terraform:

- Знайде локальний `terraform.tfstate`
- Перенесе його в **S3 bucket**
- Увімкне блокування через **DynamoDB**

---

## 5. Подальша робота

Тепер бекенд налаштований. Для наступних змін достатньо:

```bash
terraform plan
terraform apply
```
Стан автоматично зберігається в S3.