# Serverless User Management API (AWS Lambda + API Gateway + DynamoDB)

This project implements a fully serverless user management system using AWS services. It provides endpoints to register users, authenticate them with JWT, and retrieve user information — all secured and scalable using AWS Lambda, API Gateway, and DynamoDB.

---

## ⚙️ Stack

- **AWS Lambda** – Runs the business logic (user registration, login, info retrieval)
- **Amazon API Gateway** – RESTful API for accessing Lambda functions
- **Amazon DynamoDB** – Stores user data
- **JWT Authentication** – Secure access to protected endpoints
- **AWS CloudFormation** – Infrastructure as code (IaC)
- **Postman** – API testing collection included

---

## 📁 Features

- `POST /register` – Register new users with hashed passwords
- `POST /login` – Authenticate and receive JWT token
- `GET /user-info` – Retrieve user data (JWT required)
- Built-in error handling and basic input validation
- One-command deployment with `deploy.sh`

---

## 🚀 Getting Started

### 1. Clone the Repo

```bash
git clone https://github.com/yourname/serverless-user-api.git
cd serverless-user-api
```

### 2. Set Up AWS CLI

Install AWS CLI and configure credentials:

```bash
aws configure
```

### 3. Create S3 Bucket

Create a bucket to store Lambda code zips:

```bash
aws s3 mb s3://your-unique-bucket-name
```

Update `deploy.sh` with your bucket name.

### 4. Deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Zip and upload Lambda functions
- Deploy full infrastructure using CloudFormation
- Print your API Gateway URL

---

## 🔐 JWT Authentication

After a successful login, you'll receive a JWT token:

```json
{
  "token": "<your.jwt.token>"
}
```

Use it in the `Authorization` header for protected requests:

```http
Authorization: Bearer <your.jwt.token>
```

---

## 🧪 Testing with Postman

Import the included Postman collection from:

```
postman/user-management-api.postman_collection.json
```

Or test manually:

```bash
# Register
curl -X POST https://<API_URL>/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"SecurePass9","email":"john@example.com"}'

# Login
curl -X POST https://<API_URL>/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"SecurePass9"}'

# Get User Info
curl -X GET https://<API_URL>/user-info \
  -H "Authorization: Bearer <your.token>"
```

### 🧨 Cleanup Script

To delete all resources created by this project (CloudFormation stack, Lambdas, DynamoDB, API Gateway) and clean up S3 zip files.
Update `destroy.sh` with your bucket name.
 
Run:

```bash
chmod +x destroy.sh
./destroy.sh
```

This will:
- Delete the CloudFormation stack `user-management-api`
- Wait for the deletion to complete
- Remove all Lambda zip files from `s3://your-unique-bucket-name/lambda-code/`

---

## 🔒 Security Notes

- In the current setup, JWT tokens are verified directly inside each Lambda function (e.g., `getUserInfo`).
- For better scalability and separation of concerns, you could use a **Lambda Authorizer** in API Gateway in the future. This would allow centralized token validation and reduce duplicate logic across functions.


- Passwords are hashed using `bcryptjs`
- JWT is signed with a secret stored in environment variables
- In production, use AWS SSM or Secrets Manager for managing secrets like `JWT_SECRET`
