# n8n Grafana Dashboard Setup Guide

n8n has two official Grafana dashboards available for monitoring:

## Available Dashboards

### 1. n8n Workflow & Execution Analytics (Dashboard ID: 24475)
- **Purpose**: Monitor workflow execution performance, track success rates, identify bottlenecks
- **Data Source**: PostgreSQL (connects to n8n's database)
- **URL**: https://grafana.com/grafana/dashboards/24475

### 2. n8n System Health Overview (Dashboard ID: 24474)
- **Purpose**: Monitor Node.js runtime, system resources, CPU, memory, event loop performance
- **Data Source**: Prometheus (requires n8n metrics endpoint)
- **URL**: https://grafana.com/grafana/dashboards/24474

## Setup Instructions

### Dashboard 1: Workflow & Execution Analytics (PostgreSQL)

This dashboard uses your n8n PostgreSQL database directly.

#### Prerequisites
- n8n must be using PostgreSQL as its database (not SQLite)
- PostgreSQL must be accessible from Grafana
- PostgreSQL credentials must be available

#### Steps

1. **Add PostgreSQL Data Source in Grafana** (if not already added):
   - Go to Grafana → Configuration → Data Sources
   - Click "Add data source"
   - Select "PostgreSQL"
   - Configure:
     - **Host**: Your PostgreSQL service (e.g., `postgres.carimbo-vip.svc.cluster.local:5432`)
     - **Database**: Your n8n database name
     - **User**: PostgreSQL username
     - **Password**: PostgreSQL password
     - **SSL Mode**: Disable (or configure as needed)
   - Click "Save & Test"

2. **Import the Dashboard**:
   - Go to Grafana → Dashboards → Import
   - Enter Dashboard ID: `24475`
   - Click "Load"
   - Select the PostgreSQL data source you just created
   - Click "Import"

3. **Verify**:
   - The dashboard should show workflow execution metrics
   - Check that data is appearing (may take a few minutes if workflows are running)

### Dashboard 2: System Health Overview (Prometheus)

This dashboard uses Prometheus metrics from n8n.

#### Prerequisites
- n8n must expose Prometheus metrics (enabled via environment variable)
- Prometheus must be scraping n8n metrics
- ServiceMonitor must be configured (if using Prometheus Operator)

#### Steps

1. **Enable Metrics in n8n**:
   - n8n exposes metrics at `/metrics` endpoint when enabled
   - Add environment variable: `N8N_METRICS=true` (or `METRICS=true` depending on n8n version)
   - The n8n module should be configured to expose metrics

2. **Verify Metrics Endpoint**:
   ```bash
   # Port-forward to n8n service
   kubectl port-forward -n carimbo-vip svc/n8n 5678:5678
   
   # Check metrics endpoint
   curl http://localhost:5678/metrics
   ```
   You should see Prometheus-formatted metrics.

3. **Configure Prometheus Scraping**:
   - If using Prometheus Operator, ensure ServiceMonitor is configured
   - Metrics should be available in Prometheus at: `http://prometheus:9090`
   - Query: `n8n_up` or `process_cpu_user_seconds_total{job="n8n"}`

4. **Import the Dashboard**:
   - Go to Grafana → Dashboards → Import
   - Enter Dashboard ID: `24474`
   - Click "Load"
   - Select Prometheus as the data source
   - Click "Import"

5. **Update Dashboard Variables** (if needed):
   - Go to Dashboard Settings → Variables
   - Check the `job` variable - it should be `n8n` (or update if different)
   - Check the `instance` variable - should match your n8n instance

6. **Verify**:
   - The dashboard should show system health metrics
   - Check CPU, memory, event loop, and other Node.js metrics

## Troubleshooting

### Dashboard 1 (PostgreSQL) - No Data

1. **Check PostgreSQL Connection**:
   ```bash
   # Test connection from Grafana pod
   kubectl exec -n monitoring -it <grafana-pod> -- \
     psql -h postgres.carimbo-vip.svc.cluster.local -U postgres -d <database>
   ```

2. **Verify Database Tables**:
   - Ensure n8n has created its tables
   - Check if workflows exist: `SELECT COUNT(*) FROM execution_entity;`

3. **Check Data Source**:
   - Verify credentials in Grafana data source configuration
   - Test the connection in Grafana

### Dashboard 2 (Prometheus) - No Data

1. **Check Metrics Endpoint**:
   ```bash
   kubectl port-forward -n carimbo-vip svc/n8n 5678:5678
   curl http://localhost:5678/metrics | head -20
   ```

2. **Check Prometheus Targets**:
   - Go to Prometheus → Status → Targets
   - Look for n8n target
   - Verify it's "UP" and scraping successfully

3. **Check ServiceMonitor**:
   ```bash
   kubectl get servicemonitor -n carimbo-vip n8n -o yaml
   ```

4. **Verify Metrics in Prometheus**:
   ```bash
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
   # Then visit http://localhost:9090
   # Query: n8n_up or up{job="n8n"}
   ```

5. **Check Dashboard Variables**:
   - Ensure `job` variable is set to `n8n`
   - Ensure `instance` variable matches your n8n instance

## Current Configuration

- **n8n Namespace**: `carimbo-vip`
- **n8n Service**: `n8n`
- **n8n Port**: `5678`
- **Metrics Endpoint**: `/metrics` (when enabled)
- **PostgreSQL**: Available in `carimbo-vip` namespace

## Additional Resources

- [n8n Workflow & Execution Analytics Dashboard](https://grafana.com/grafana/dashboards/24475)
- [n8n System Health Overview Dashboard](https://grafana.com/grafana/dashboards/24474)
- [n8n Documentation](https://docs.n8n.io/)
- [Grafana Dashboard Documentation](https://grafana.com/docs/grafana/latest/dashboards/)

