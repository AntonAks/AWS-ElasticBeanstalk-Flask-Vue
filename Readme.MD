# Deploying Flask App on AWS Elastic Beanstalk with Terraform

## Overview
This project uses **Terraform** to deploy a **Flask** application to **AWS Elastic Beanstalk**. It provisions the necessary infrastructure, including:

✅ **VPC, Subnet, Internet Gateway**  
✅ **Security Group for Beanstalk**  
✅ **S3 Bucket for Flask app ZIP**  
✅ **IAM Role & Instance Profile for Beanstalk**  
✅ **Elastic Beanstalk Application & Environment**  
✅ **Application Version linked to S3 ZIP**  

## Architecture

- A **Flask app** is packaged into a `.zip` file and uploaded to an **S3 bucket**.
- Terraform provisions an **Elastic Beanstalk** environment to deploy the Flask app.
- The app is accessible via an **auto-generated AWS Beanstalk URL**.

## Prerequisites

Ensure you have the following installed:

- **Terraform**
- **AWS CLI** (configured with credentials)
- **Python 3+**
- **Flask** (if you want to test locally)

## Setup & Deployment

### 1️⃣ Clone the Repository
### 2️⃣ Package the Flask App
Ensure `flask-app.zip` is present in your working directory:
```sh
zip -r flask-app.zip .ebextensions/ static/ requirements.txt application.py
```

### 3️⃣ Initialize Terraform
```sh
terraform init
```

### 4️⃣ Apply Terraform Configuration
This will provision AWS resources and deploy the Flask app:
```sh
terraform apply -auto-approve
```

### 5️⃣ Get the Beanstalk URL
Once deployment is complete, navigate to **AWS Console → Elastic Beanstalk → flask-app-env** and find the **Application URL**.

### 6️⃣ Visit the App 🎉
Open your browser and go to:
```
http://<your-beanstalk-url>
```

## Cleanup
To remove all resources:
```sh
terraform destroy -auto-approve
```
⚠️ This **permanently deletes** all AWS resources.

## Files Structure
```
├── main.tf            # Terraform configuration
├── flask-app.zip      # Flask app archive (uploaded to S3)
├── app.py             # Flask application
├── static/
│   └── index.html     # Vue.js frontend
├── .ebextensions/
│   └── python.config  # Elastic Beanstalk configuration
├── README.md          # Documentation (this file)
├── requirements.txt   # required modules
```

## Author
💡 Created by **[Your Name]** - Feel free to contribute and improve!

---
Happy coding! 🚀

