# PostgreSQL Grafana Dashboard Setup

This guide explains how to set up PostgreSQL monitoring in Grafana with pre-built dashboards.

## Overview

The PostgreSQL module includes:
- **PostgreSQL Exporter** - A sidecar container that exposes PostgreSQL metrics to Prometheus
- **ServiceMonitor** - Automatically configures Prometheus to scrape PostgreSQL metrics
- **Grafana Dashboards** - Import community dashboards for visualization

## Components

### 1. PostgreSQL Exporter

The PostgreSQL deployment includes a `postgres-exporter` sidecar container that:
- Exposes metrics on port `9187`
- Connects to PostgreSQL using the same credentials
- Provides metrics about database performance, connections, queries, etc.

### 2. ServiceMonitor

A ServiceMonitor resource tells Prometheus to scrape the PostgreSQL exporter:
- Automatically discovered by Prometheus Operator
- Scrapes metrics every 30 seconds
- Metrics available at `/metrics` endpoint

### 3. Grafana Dashboards

Import these community dashboards for PostgreSQL monitoring:

#### Recommended Dashboards

1. **PostgreSQL Database Dashboard** (ID: `9628`)
   - URL: https://grafana.com/grafana/dashboards/9628
   - Comprehensive overview of PostgreSQL performance
   - Includes connection stats, query performance, replication, etc.

2. **PostgreSQL Overview** (ID: `14114`)
   - URL: https://grafana.com/grafana/dashboards/14114
   - Quick overview dashboard
   - Good for high-level monitoring

3. **PostgreSQL Database Dashboard v2** (ID: `22056`)
   - URL: https://grafana.com/grafana/dashboards/22056
   - Modern dashboard with graph, stat, and timeseries panels
   - Works with postgres_exporter

## Setup Instructions

### Step 1: Verify PostgreSQL Exporter is Running

```bash
# Check if the exporter pod is running
kubectl get pods -n carimbo-vip -l app=postgres

# Check exporter logs
kubectl logs -n carimbo-vip <postgres-pod-name> -c postgres-exporter

# Test metrics endpoint
kubectl port-forward -n carimbo-vip svc/postgres 9187:9187
curl http://localhost:9187/metrics
```

### Step 2: Verify ServiceMonitor is Created

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n carimbo-vip

# Check if Prometheus is scraping
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090 and search for "postgres"
```

### Step 3: Access Grafana

```bash
# Get Grafana URL
MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Grafana: http://${MASTER_IP}:30080"
echo "Username: admin"
echo "Password: admin"  # or check your terraform variables
```

### Step 4: Import Dashboard

1. **Login to Grafana** at `http://<MASTER_IP>:30080`

2. **Go to Dashboards → Import**

3. **Enter Dashboard ID**: `9628` (or `14114`, `22056`)

4. **Select Data Source**: Choose "Prometheus" (should be default)

5. **Click Import**

6. **View Dashboard**: The dashboard will show PostgreSQL metrics

### Step 5: Configure Dashboard (if needed)

If metrics don't appear:
1. Check that Prometheus is scraping: Go to Prometheus UI → Status → Targets
2. Verify the `postgres` target is UP
3. Check dashboard variables match your PostgreSQL instance name

## Available Metrics

The PostgreSQL exporter provides metrics like:
- `pg_up` - PostgreSQL is up (1) or down (0)
- `pg_stat_database_*` - Database statistics
- `pg_stat_activity_*` - Active connections and queries
- `pg_stat_bgwriter_*` - Background writer statistics
- `pg_stat_replication_*` - Replication statistics
- `pg_stat_user_tables_*` - Table statistics
- `pg_stat_user_indexes_*` - Index statistics

## Troubleshooting

### Metrics Not Appearing

1. **Check exporter is running**:
   ```bash
   kubectl get pods -n carimbo-vip -l app=postgres -o jsonpath='{.items[0].spec.containers[*].name}'
   ```

2. **Check exporter logs**:
   ```bash
   kubectl logs -n carimbo-vip <pod-name> -c postgres-exporter
   ```

3. **Check ServiceMonitor**:
   ```bash
   kubectl get servicemonitor -n carimbo-vip postgres -o yaml
   ```

4. **Check Prometheus targets**:
   - Access Prometheus UI: `http://<MASTER_IP>:30090`
   - Go to Status → Targets
   - Look for `postgres` target

### Dashboard Shows "No Data"

1. **Verify Prometheus is scraping**: Check Prometheus targets
2. **Check time range**: Make sure you're looking at the right time period
3. **Verify metric names**: Some dashboards use different metric names
4. **Check data source**: Ensure dashboard uses "Prometheus" data source

## Additional Resources

- [PostgreSQL Exporter Documentation](https://github.com/prometheus-community/postgres_exporter)
- [Grafana Dashboard Gallery](https://grafana.com/grafana/dashboards/)
- [Prometheus PostgreSQL Metrics](https://github.com/prometheus-community/postgres_exporter#metrics)

