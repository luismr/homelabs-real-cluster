# Redis Grafana Dashboard Setup

This guide explains how to set up Redis monitoring in Grafana with pre-built dashboards.

## Overview

The Redis module includes:
- **Redis Exporter** - A sidecar container that exposes Redis metrics to Prometheus
- **ServiceMonitor** - Automatically configures Prometheus to scrape Redis metrics
- **Grafana Dashboards** - Import community dashboards for visualization

## Components

### 1. Redis Exporter

The Redis deployment includes a `redis-exporter` sidecar container that:
- Exposes metrics on port `9121`
- Connects to Redis using the same credentials
- Provides metrics about Redis performance, memory, commands, etc.

### 2. ServiceMonitor

A ServiceMonitor resource tells Prometheus to scrape the Redis exporter:
- Automatically discovered by Prometheus Operator
- Scrapes metrics every 30 seconds
- Metrics available at `/metrics` endpoint

### 3. Grafana Dashboards

Import these community dashboards for Redis monitoring:

#### Recommended Dashboards

1. **Redis Dashboard for Prometheus Redis Exporter** (ID: `11835`)
   - URL: https://grafana.com/grafana/dashboards/11835
   - Comprehensive Redis monitoring dashboard
   - Works with redis_exporter
   - Includes memory, commands, clients, keyspace, replication metrics

2. **Redis Dashboard** (ID: `12776`)
   - URL: https://grafana.com/grafana/dashboards/12776
   - Modern Redis dashboard
   - Requires Redis Data Source plugin (alternative to Prometheus)

3. **Redis Server Performance Monitoring** (ID: `12497`)
   - URL: https://grafana.com/grafana/dashboards/12497
   - Performance-focused dashboard
   - Uses Telegraf with Redis input plugin

4. **Redis Exporter Overview** (ID: `763`)
   - URL: https://grafana.com/grafana/dashboards/763
   - Classic Redis exporter dashboard
   - Good for quick overview

## Setup Instructions

### Step 1: Verify Redis Exporter is Running

```bash
# Check if the exporter pod is running
kubectl get pods -n carimbo-vip -l app=redis

# Check exporter logs
kubectl logs -n carimbo-vip <redis-pod-name> -c redis-exporter

# Test metrics endpoint
kubectl port-forward -n carimbo-vip svc/redis 9121:9121
curl http://localhost:9121/metrics
```

### Step 2: Verify ServiceMonitor is Created

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n carimbo-vip

# Check if Prometheus is scraping
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090 and search for "redis"
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

3. **Enter Dashboard ID**: `11835` (Redis Dashboard for Prometheus Redis Exporter)

4. **Select Data Source**: Choose "Prometheus" (should be default)

5. **Click Import**

6. **View Dashboard**: The dashboard will show Redis metrics

### Step 5: Configure Dashboard (if needed)

If metrics don't appear:
1. Check that Prometheus is scraping: Go to Prometheus UI → Status → Targets
2. Verify the `redis` target is UP
3. Check dashboard variables match your Redis instance name

## Available Metrics

The Redis exporter provides metrics like:
- `redis_up` - Redis is up (1) or down (0)
- `redis_connected_clients` - Number of connected clients
- `redis_commands_processed_total` - Total commands processed
- `redis_keyspace_keys` - Number of keys per database
- `redis_memory_used_bytes` - Memory used by Redis
- `redis_memory_max_bytes` - Maximum memory configured
- `redis_cpu_sys_seconds_total` - CPU time used by Redis
- `redis_rejected_connections_total` - Rejected connections
- `redis_expired_keys_total` - Expired keys
- `redis_evicted_keys_total` - Evicted keys
- `redis_slowlog_length` - Slow log entries

## Troubleshooting

### Metrics Not Appearing

1. **Check exporter is running**:
   ```bash
   kubectl get pods -n carimbo-vip -l app=redis -o jsonpath='{.items[0].spec.containers[*].name}'
   ```

2. **Check exporter logs**:
   ```bash
   kubectl logs -n carimbo-vip <pod-name> -c redis-exporter
   ```

3. **Check ServiceMonitor**:
   ```bash
   kubectl get servicemonitor -n carimbo-vip redis -o yaml
   ```

4. **Check Prometheus targets**:
   - Access Prometheus UI: `http://<MASTER_IP>:30090`
   - Go to Status → Targets
   - Look for `redis` target

### Dashboard Shows "No Data"

1. **Verify Prometheus is scraping**: Check Prometheus targets
2. **Check time range**: Make sure you're looking at the right time period
3. **Verify metric names**: Some dashboards use different metric names
4. **Check data source**: Ensure dashboard uses "Prometheus" data source

### Redis Exporter Connection Issues

If the exporter can't connect to Redis:
1. **Check Redis password**: If Redis has a password, ensure `REDIS_PASSWORD` env var is set
2. **Check Redis address**: Verify `REDIS_ADDR` points to correct Redis instance
3. **Check network**: Ensure exporter can reach Redis on localhost:6379

## Additional Resources

- [Redis Exporter Documentation](https://github.com/oliver006/redis_exporter)
- [Grafana Dashboard Gallery](https://grafana.com/grafana/dashboards/)
- [Prometheus Redis Metrics](https://github.com/oliver006/redis_exporter#metrics)

