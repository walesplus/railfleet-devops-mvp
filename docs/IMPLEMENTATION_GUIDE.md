# RailFleet DevOps MVP — Implementation Guide

## 1. Objective

Build a small but realistic locomotive telemetry platform. The participant is responsible for the engineering system around the application: infrastructure, containerization, CI/CD, security, deployment, monitoring, and troubleshooting.

## 2. Target architecture

GitHub
  -> GitHub Actions
  -> Maven tests + Semgrep SAST
  -> Docker build
  -> Trivy vulnerability scan
  -> Amazon ECR
  -> AWS Systems Manager Run Command
  -> EC2 Ubuntu
  -> Docker Compose
     -> Spring Boot API
     -> PostgreSQL
     -> Prometheus
     -> Grafana

The GitHub workflow uses OIDC rather than long-lived AWS access keys. GitHub's current documentation recommends OIDC so workflows can receive short-lived AWS credentials, with trust restricted by repository/branch conditions.

## 3. Prerequisites

Participant machine:
- Git
- GitHub account
- AWS account
- AWS CLI configured for initial Terraform bootstrap
- Terraform >= 1.6
- Java 21
- Maven (or use the Maven wrapper after generating one)
- Docker
- An editor such as VS Code

Important: never commit `.env`, AWS credentials, private keys, database passwords, or tokens.

## 4. Create the application locally

```bash
git clone <your-repo-url>
cd railfleet-devops-mvp
```

If Maven wrapper files are not present, create them:

```bash
mvn wrapper:wrapper
```

Then:

```bash
./mvnw test
```

On Windows PowerShell:

```powershell
.\mvnw.cmd test
```

Build:

```bash
./mvnw -DskipTests package
```

## 5. Run the API locally

Create `.env` from `.env.example` and set non-production development passwords.

Start PostgreSQL and the full stack:

```bash
docker compose --env-file .env up -d postgres prometheus grafana
```

Run the Spring Boot application locally:

```bash
./mvnw spring-boot:run
```

Health:

```bash
curl http://localhost:8080/actuator/health
```

Create telemetry:

```bash
curl -X POST http://localhost:8080/api/telemetry   -H "Content-Type: application/json"   -d '{
    "locomotiveId":"L-1001",
    "engineTemperature":87.5,
    "fuelLevel":72,
    "batteryVoltage":26.4,
    "speed":48.2,
    "engineHours":12450.5
  }'
```

Metrics:

```bash
curl http://localhost:8080/actuator/prometheus
```

Spring Boot exposes Prometheus-formatted metrics through `/actuator/prometheus` when the Prometheus registry is included and the endpoint is exposed.

## 6. Containerize

Build:

```bash
./mvnw -DskipTests package
docker build -t railfleet-api:local .
```

Run:

```bash
docker run --rm -p 8080:8080   -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/railfleet   -e SPRING_DATASOURCE_USERNAME=railfleet   -e SPRING_DATASOURCE_PASSWORD=CHANGE_ME   railfleet-api:local
```

For the full environment, prefer Docker Compose.

## 7. Terraform infrastructure

The Terraform configuration creates:
- VPC
- public subnet
- Internet Gateway and route table
- security group
- encrypted 30 GB gp3 EC2 root volume
- Ubuntu 24.04 EC2
- ECR repository with scan-on-push
- EC2 IAM role
- SSM managed-instance permissions
- ECR pull permissions
- GitHub Actions OIDC provider
- GitHub Actions deployment role

Edit `terraform/variables.tf` or create `terraform/terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
project_name     = "railfleet"
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
allowed_web_cidr = "0.0.0.0/0"
instance_type    = "t3.small"

github_org  = "YOUR_GITHUB_USERNAME_OR_ORG"
github_repo = "railfleet-devops-mvp"
```

Initialize and review:

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Apply:

```bash
terraform apply
```

Save outputs:

```bash
terraform output
```

## 8. Verify the EC2 host

Use SSM Session Manager or the AWS Console. Do not make SSH the normal deployment path.

Check:

```bash
sudo systemctl status docker
sudo docker ps
ls -la /opt/railfleet
```

The EC2 instance should have an IAM role containing:
- AmazonSSMManagedInstanceCore
- ECR pull permissions

## 9. Configure GitHub Actions

Create repository variables:

- `AWS_REGION` = your AWS region
- `ECR_REPOSITORY` = `railfleet-api`
- `AWS_ROLE_ARN` = Terraform output `github_actions_role_arn`

The workflow has `id-token: write` and uses `aws-actions/configure-aws-credentials`. GitHub documents this as the OIDC pattern for exchanging a workflow token for short-lived AWS credentials.

Push:

```bash
git add .
git commit -m "feat: implement RailFleet DevOps MVP"
git push origin main
```

Pipeline stages:
1. Checkout
2. Java setup
3. Maven tests
4. Semgrep SAST
5. Maven package
6. AWS OIDC authentication
7. ECR login
8. Docker build
9. Trivy scan
10. Push immutable SHA-tagged image
11. Discover the EC2 instance
12. SSM deployment
13. Docker Compose pull/up
14. Old image cleanup

## 10. Security controls

### IAM
Use separate roles for EC2 and GitHub Actions. Restrict GitHub OIDC to the exact repository and main branch.

### Network
PostgreSQL has no public listener. It is reachable only inside the Docker network.

SSH is restricted to the participant's IP. For normal administration, use SSM.

### Secrets
For the teaching MVP, `.env` exists only on the server and is excluded from Git. **Before the first deployment, change the placeholder passwords created by cloud-init.** For a stronger production version, move database/Grafana credentials to AWS Secrets Manager and retrieve them at deployment/startup.

### SAST
Semgrep checks source code for common security patterns.

### Container scanning
Trivy blocks the pipeline for HIGH/CRITICAL vulnerabilities that are fixable.

### DAST
After deployment, run a basic HTTP security scan against the application. Example:

```bash
docker run --rm -t owasp/zap2docker-stable zap-baseline.py   -t http://YOUR_EC2_PUBLIC_IP:8080
```

For a real production implementation, run DAST in a controlled staging environment rather than directly against production.

## 11. Monitoring

Prometheus scrapes:

```text
http://api:8080/actuator/prometheus
```

Grafana uses Prometheus as its default data source.

Open:
- API: `http://EC2_PUBLIC_IP:8080`
- Prometheus: `http://EC2_PUBLIC_IP:9090`
- Grafana: `http://EC2_PUBLIC_IP:3000`

For a safer setup, restrict Grafana to a trusted CIDR or put it behind an authenticated reverse proxy/VPN.

Useful Prometheus queries:
```promql
up
process_cpu_usage
jvm_memory_used_bytes
http_server_requests_seconds_count
```

Create alerts for:
- API down
- high CPU
- low available memory
- high request latency
- PostgreSQL unavailable
- disk usage > 80%

## 12. Troubleshooting runbook

### Application is down

```bash
cd /opt/railfleet
sudo docker compose --env-file .env ps
sudo docker compose --env-file .env logs --tail=100 api
curl http://localhost:8080/actuator/health
```

Restart:

```bash
sudo docker compose --env-file .env restart api
```

### Database connection failure

```bash
sudo docker compose --env-file .env ps postgres
sudo docker compose --env-file .env logs --tail=100 postgres
sudo docker exec -it railfleet-postgres-1 pg_isready -U railfleet -d railfleet
```

If the container name differs:

```bash
sudo docker ps
```

Check API environment:

```bash
sudo docker compose --env-file .env config
```

### High CPU

```bash
top
docker stats
sudo docker stats
```

Identify the process/container, inspect logs, and scale/optimize rather than blindly restarting.

### Disk full

```bash
df -h
docker system df
sudo du -sh /var/lib/docker
```

Clean unused images only after confirming they are not needed:

```bash
sudo docker image prune -af
```

### Deployment failed

Check GitHub Actions first, then SSM:

```bash
aws ssm list-command-invocations --details
```

On EC2:

```bash
cd /opt/railfleet
sudo docker compose --env-file .env pull
sudo docker compose --env-file .env up -d
sudo docker compose --env-file .env logs --tail=100
```

### Rollback

Because images use Git SHA tags, rollback is deterministic:

```bash
sudo sed -i 's|^IMAGE_TAG=.*|IMAGE_TAG=PREVIOUS_GOOD_SHA|' /opt/railfleet/.env
cd /opt/railfleet
sudo docker compose --env-file .env pull api
sudo docker compose --env-file .env up -d api
```

## 13. Acceptance test

The project is complete when the participant can demonstrate:

- `terraform validate` passes
- AWS infrastructure exists from Terraform
- EC2 is managed by SSM
- ECR contains the application image
- GitHub Actions tests the code
- SAST runs
- Trivy scans the container
- Deployment happens automatically after a push to main
- API health returns UP
- Telemetry can be POSTed and retrieved
- PostgreSQL persists telemetry
- Prometheus scrapes the API
- Grafana reads Prometheus
- PostgreSQL is not publicly exposed
- No AWS keys/passwords are committed
- Participant can diagnose a simulated outage and perform a rollback

## 14. Suggested participant exercises

1. Add a `GET /api/telemetry/latest/{locomotiveId}` endpoint.
2. Add a database index on `locomotive_id`.
3. Add an alert for engine temperature > 110.
4. Add a Grafana dashboard.
5. Add a staging branch/environment.
6. Add blue/green or canary deployment as an advanced exercise.
7. Replace PostgreSQL on EC2 with Amazon RDS.
8. Replace the public API port with an Application Load Balancer and HTTPS.
9. Move secrets to AWS Secrets Manager.
10. Add CloudWatch logs and alarms.

## 15. Instructor note

The MVP deliberately balances realism and teaching speed. EC2 + Docker Compose is easy to observe and troubleshoot. The next production evolution is:

ALB + HTTPS -> private EC2/ECS -> RDS PostgreSQL -> Secrets Manager -> CloudWatch -> centralized Grafana/Prometheus or Amazon Managed Service for Prometheus.

Do not treat this MVP as a final production architecture.