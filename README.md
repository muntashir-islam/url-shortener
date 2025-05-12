# 🔗 AWS URL Shortener

A serverless URL shortener built on AWS using:

- **AWS Lambda** (Python)
- **Amazon API Gateway**
- **Amazon DynamoDB**
- **Terraform** for IaC

---

## 🚀 Features

- Generate short URLs using a `/shorten` endpoint.
- Redirect users using `/short_code` endpoint.
- Serverless and cost-efficient (Pay-per-request).
- Fully managed with Terraform.
- Environment-configurable.

---

## 🧱 Architecture
Client --> API Gateway --> Lambda --> DynamoDB


---
## 📁 Project Structure
```bash
.
├── lambda/
│ └── url_shortener.py # Lambda function in Python
├── main.tf # Terraform AWS infra (Lambda, API Gateway, IAM, etc.)
├── variables.tf # Terraform variables
├── outputs.tf # Useful output values
├── README.md # Project documentation
```
---

## 📦 Requirements

- Terraform v1.3+
- AWS CLI configured with credentials
- Python 3.9+
- AWS Account

---

## ⚙️ Deployment

1. **Clone the Repo**

   ```bash
   git clone https://github.com/your-username/aws-url-shortener.git
   cd aws-url-shortener
   ```
2. **Create a Virtual Environment**

```bash
python3 -m venv .venv
source .venv/bin/activate

```
3. **Prepare Lambda Function Zip**

    Terraform will package lambda/url_shortener.py using the archive_file data source.

4. **Deploy with Terraform**

```bash
terraform init
terraform apply
```

5. **Test the API**

Get the API endpoint from Terraform output and test it:

```bash
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.facebook.com"}'
```

## 📥 API Endpoints

**POST /shorten**

Shortens a given URL.

Request:
```bash
{
  "url": "https://example.com"
}
```
Response:

```json
{
  "short_url": "https://<api-url>/<short_code>"
}
```
Here is overall example request
```bash
 curl -X POST https://xxxxxxx.execute-api.us-east-2.amazonaws.com/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com"}'
```
Here is outcome
```bash 
{"short_url": "https://example.com/Rv2e6B"}%
```






**GET /{short_code}**

Redirects to the original URL.

## 🔐 IAM & Permissions
Lambda is granted permission to:

```bash
dynamodb:PutItem
dynamodb:GetItem
```
CloudWatch Logs enabled via `AWSLambdaBasicExecutionRole`.

## 🛠️ Future Work ##
### 🌐 Custom Domain Integration with Namecheap ###

- You can map your own domain (e.g., api.example.com) to this API Gateway:
- Request ACM Certificate for `api.example.com` in `us-east-2`
- Validate with DNS via Namecheap’s DNS panel
- Create API Gateway Custom Domain
- Add CNAME `record` in Namecheap
- This enables branded short links like: `https://api.example.com/x1y2z3`

## 🙋‍♂️ Author ##
Muntashir Islam

Senior DevOps / SRE | AWS & Kubernetes Certified | CNCF Enthusiast

GitHub: `@muntashir-islam`