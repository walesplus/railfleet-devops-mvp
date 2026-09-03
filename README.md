# RailFleet DevOps MVP

A containerized Spring Boot locomotive telemetry API deployed to AWS EC2 with PostgreSQL, Prometheus, Grafana, Terraform, ECR, GitHub Actions, Trivy, and AWS Systems Manager (SSM).

## Architecture

GitHub -> GitHub Actions -> tests/SAST -> Docker build -> Trivy -> ECR -> AWS SSM -> EC2 -> Docker Compose -> Spring Boot + PostgreSQL + Prometheus + Grafana

## Quick start

1. Install Java 21, Maven, Docker, Terraform, AWS CLI.
2. Create the GitHub repository and push this project.
3. Configure AWS OIDC for GitHub Actions using the Terraform bootstrap instructions in `docs/IMPLEMENTATION_GUIDE.md`.
4. Run Terraform to create the network, EC2, ECR, IAM, and SSM resources.
5. Add the resulting GitHub variables.
6. Push to `main`. GitHub Actions builds, scans, pushes to ECR, and deploys through SSM.
7. Open the application URL and verify `/actuator/health`.
8. Open Grafana and import/build a dashboard using Prometheus.

## API

POST `/api/telemetry`
```json
{
  "locomotiveId": "L-1001",
  "engineTemperature": 87.5,
  "fuelLevel": 72.0,
  "batteryVoltage": 26.4,
  "speed": 48.2,
  "engineHours": 12450.5
}
```

GET `/api/telemetry`
GET `/api/telemetry/{id}`
GET `/api/telemetry/locomotive/{locomotiveId}`
GET `/actuator/health`
GET `/actuator/prometheus`

The MVP intentionally keeps authentication out of scope so the participant can focus on DevOps. For production, add an API gateway/authentication layer and move PostgreSQL to Amazon RDS.