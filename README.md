# S3 → Lambda → SNS Email Notifier

Serverless AWS infrastructure built with **Terraform** and deployed automatically via **GitHub Actions CI/CD**.

Every time a file is **uploaded** or **deleted** from an S3 bucket, a Lambda function fires and sends an email notification.

---

## Architecture

```
                        ┌─────────────────────────┐
                        │       GitHub Actions     │
                        │  push to main → deploy   │
                        └────────────┬─────────────┘
                                     │ terraform apply
                                     ▼
┌─────────────┐   s3:ObjectCreated   ┌──────────────────┐   sns:Publish   ┌─────────────┐
│  S3 Bucket  │ ──────────────────▶  │  Lambda Function │ ──────────────▶ │  SNS Topic │
│             │   s3:ObjectRemoved   │   (Python 3.12)  │                 │             │
└─────────────┘                      └──────────────────┘                 └──────┬──────┘
                                              │                                  │
                                              ▼                                  ▼
                                     ┌─────────────────┐                 ┌─────────────┐
                                     │ CloudWatch Logs  │                 │    Email     │
                                     └─────────────────┘                 └─────────────┘
```

---

## It works!

Both upload and delete events trigger email notifications in real time:

<img width="1379" height="116" alt="image" src="https://github.com/user-attachments/assets/3042487f-633b-4bbe-b993-ab4406c945f5" />


---

## Features

- **Upload & delete notifications** — triggers on `s3:ObjectCreated:*` and `s3:ObjectRemoved:*`
- **Serverless** — no servers to manage; Lambda scales automatically
- **IaC with Terraform** — fully modular, nothing created by clicking around the console
- **CI/CD via GitHub Actions** — push to `main` = automatic deploy to AWS
- **S3 State Locking** — prevents concurrent Terraform runs from corrupting the state
- **Least-privilege IAM** — Lambda role only allows CloudWatch logs + SNS publish on that specific topic
- **Email as variable** — no hardcoded credentials, passed via GitHub Secrets

---

## Project Structure

```
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Auto-deploy on push + manual trigger
│       └── destroy.yml         # Manual destroy only (requires typing DESTROY)
├── modules/
│   ├── lambda/
│   │   └── lambda.tf           # Lambda + IAM role + S3 trigger
│   └── sns/
│       └── sns.tf              # SNS topic + email subscription
├── main.tf                     # Root module + S3 backend with state locking
├── variables.tf                # Input variables
├── outputs.tf                  # Output values after apply
├── lambdafunc.py               # Lambda handler (Python 3.12)
└── .gitignore
```

---

## CI/CD Pipeline

```
git push origin main
        │
        ▼
GitHub Actions (deploy.yml)
        │
        ├── 1. Checkout code
        ├── 2. Configure AWS credentials (via Secrets)
        ├── 3. terraform init   → connects to S3 backend
        ├── 4. terraform plan   → shows what will change
        └── 5. terraform apply  → deploys to AWS
```

The `destroy.yml` workflow is **manual only** — triggered via `workflow_dispatch` and requires typing `DESTROY` in a confirmation field before running `terraform destroy`. No accidental teardowns.

---

## State Locking

The Terraform state is stored remotely in S3 with **native S3 locking**:

```hcl
backend "s3" {
  bucket       = "your-terraform-state-bucket"
  key          = "terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
}
```

> **Note on DynamoDB locking:** The `dynamodb_table` option for state locking was **deprecated** in recent Terraform versions. The current recommended approach is `use_lockfile = true` directly on the S3 backend — simpler, no extra AWS resources needed.

When a `terraform apply` starts, it writes a `.tflock` file to the S3 bucket. Any concurrent run attempting to acquire the lock will fail immediately with a clear error — protecting the state from corruption.

---

## Email Notification Example

```
Subject: [S3] File added: report.pdf

File added in S3!

Bucket : lambda-sns-terraform
File   : report.pdf
Size   : 245120 bytes

---

Subject: [S3] File deleted: report.pdf

File deleted in S3!

Bucket : lambda-sns-terraform
File   : report.pdf
```

---

## How to Deploy

### Prerequisites

- Terraform >= 1.3.0
- AWS CLI configured
- GitHub repository with the following Secrets configured under **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | Target region (e.g. `us-east-1`) |
| `NOTIFICATION_EMAIL` | Email address to receive notifications |

### Deploy

```bash
# Clone the repository
git clone https://github.com/gustahmalves/lambda-sns-cicd.git
cd lambda-sns-cicd

# Push to main — GitHub Actions handles the rest
git push origin main
```

> ⚠️ After the first deploy, confirm the SNS subscription by clicking **"Confirm subscription"** in the AWS notification email.

### Destroy

Go to **Actions → Destroy Terraform → Run workflow** and type `DESTROY` to confirm.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| AWS Lambda (Python 3.12) | Processes S3 events and publishes to SNS |
| Amazon S3 | Object storage + remote Terraform state |
| Amazon SNS | Pub/sub messaging and email delivery |
| AWS IAM | Least-privilege access control |
| Terraform | Infrastructure as Code (modular) |
| GitHub Actions | CI/CD pipeline (deploy + destroy workflows) |
