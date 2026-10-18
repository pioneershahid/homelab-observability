cd /opt/monitoring

echo "=== Alert rules file ==="
ls -l prometheus/rules/
cat prometheus/rules/homelab.yml

echo "=== Prometheus rule configuration ==="
grep -n -A2 'rule_files:' prometheus/prometheus.yml

echo "=== Compose rule mount ==="
grep -n -A12 'prometheus:' compose.yaml
