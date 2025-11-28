# Redis Dashboard Troubleshooting

## Status: ✅ Redis Metrics Are Working

Prometheus is successfully scraping Redis metrics. The issue is likely with the dashboard configuration.

## Verification

### 1. Check Prometheus is Scraping Redis

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Query Redis metrics
curl "http://localhost:9090/api/v1/query?query=redis_up"
# Should return: {"status":"success","data":{"resultType":"vector","result":[{"metric":{...},"value":[...,"1"]}]}}
```

### 2. Available Redis Metrics

Key metrics available:
- `redis_up` - Redis is up (1) or down (0)
- `redis_connected_clients` - Number of connected clients
- `redis_memory_used_bytes` - Memory used
- `redis_commands_processed_total` - Commands processed
- `redis_keyspace_keys` - Number of keys per database
- `redis_cpu_sys_seconds_total` - CPU usage

### 3. Dashboard Configuration Issues

Common issues when dashboards show "No Data":

#### Issue 1: Wrong Job Label

Some dashboards expect `job="redis-exporter"` but our setup uses `job="redis"`.

**Solution**: Update dashboard variables:
1. Go to Dashboard Settings → Variables
2. Find the `job` variable
3. Change it to `redis` or add `redis` as an option

#### Issue 2: Wrong Instance Label

Some dashboards use `instance` label differently.

**Solution**: Check the dashboard's query and update if needed:
- Our instance format: `10.42.0.89:9121`
- Job label: `redis`
- Namespace label: `carimbo-vip`

#### Issue 3: Time Range

Make sure you're looking at the right time range (last 5-15 minutes).

### 4. Test Queries in Grafana

Go to Grafana → Explore → Prometheus and test these queries:

```promql
# Redis is up
redis_up{job="redis"}

# Connected clients
redis_connected_clients{job="redis"}

# Memory used
redis_memory_used_bytes{job="redis"}

# Commands per second
rate(redis_commands_processed_total{job="redis"}[5m])

# Keyspace keys
redis_keyspace_keys{job="redis"}
```

### 5. Recommended Dashboard IDs

Try these dashboards (they work with `job="redis"`):

1. **Dashboard ID: 11835** - Redis Dashboard for Prometheus Redis Exporter
   - URL: https://grafana.com/grafana/dashboards/11835
   - **Important**: After importing, go to Variables and set `job` to `redis`

2. **Dashboard ID: 763** - Redis Exporter Overview
   - URL: https://grafana.com/grafana/dashboards/763
   - May need variable updates

3. **Dashboard ID: 14086** - Redis Dashboard
   - URL: https://grafana.com/grafana/dashboards/14086
   - Modern dashboard, may need job variable update

### 6. Quick Fix: Update Dashboard Variables

After importing a dashboard:

1. Click the dashboard settings (gear icon)
2. Go to "Variables"
3. Find the `job` or `instance` variable
4. Update it to match:
   - `job`: `redis`
   - `namespace`: `carimbo-vip` (if used)
5. Save the dashboard

### 7. Create a Simple Test Dashboard

If dashboards don't work, create a simple test:

1. Create new dashboard in Grafana
2. Add panel
3. Use query: `redis_up{job="redis"}`
4. If this shows data, the issue is with the imported dashboard variables

## Current Configuration

- **Job Label**: `redis`
- **Namespace**: `carimbo-vip`
- **Service**: `redis`
- **Metrics Port**: `9121`
- **Exporter**: `redis-exporter` container
- **Target Status**: UP ✅

## Verification Commands

```bash
# Check if Prometheus is scraping
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Then visit http://localhost:9090/targets and look for "redis"

# Check metrics directly
kubectl port-forward -n carimbo-vip svc/redis 9121:9121
curl http://localhost:9121/metrics | grep redis_up

# Query Prometheus
curl "http://localhost:9090/api/v1/query?query=redis_up"
```

