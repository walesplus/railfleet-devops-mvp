#!/bin/bash
set -eux

apt-get update
apt-get install -y docker.io docker-compose-v2 awscli
systemctl enable --now docker
usermod -aG docker ubuntu

mkdir -p /opt/railfleet/monitoring/grafana/provisioning/datasources
chown -R ubuntu:ubuntu /opt/railfleet

cat > /opt/railfleet/.env <<'EOF'
ECR_REGISTRY=${ecr_registry}
ECR_REPOSITORY=railfleet-api
IMAGE_TAG=latest
POSTGRES_USER=railfleet
POSTGRES_PASSWORD=CHANGE_ME_BEFORE_DEPLOY
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=CHANGE_ME_BEFORE_DEPLOY
EOF

cat > /opt/railfleet/docker-compose.yml <<'EOF'
services:
  api:
    image: ${ECR_REGISTRY}:${IMAGE_TAG}
    restart: unless-stopped
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/railfleet
      SPRING_DATASOURCE_USERNAME: ${POSTGRES_USER}
      SPRING_DATASOURCE_PASSWORD: ${POSTGRES_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
    ports: ["8080:8080"]
    networks: [railfleet]
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: railfleet
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes: [postgres_data:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d railfleet"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks: [railfleet]
  prometheus:
    image: prom/prometheus:v3.5.0
    restart: unless-stopped
    volumes: ["./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro"]
    ports: ["9090:9090"]
    networks: [railfleet]
  grafana:
    image: grafana/grafana:12.1.1
    restart: unless-stopped
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
    ports: ["3000:3000"]
    networks: [railfleet]
volumes:
  postgres_data:
  grafana_data:
networks:
  railfleet:
EOF

cat > /opt/railfleet/monitoring/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: railfleet-api
    metrics_path: /actuator/prometheus
    static_configs:
      - targets: ["api:8080"]
EOF

cat > /opt/railfleet/monitoring/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

chown -R ubuntu:ubuntu /opt/railfleet
