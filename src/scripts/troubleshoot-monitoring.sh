#!/bin/bash
# Script to troubleshoot monitoring setup

set -euo pipefail

echo "🔍 Monitoring Troubleshooting"
echo "================================"

# Check if Minikube is running
echo "1. Checking Minikube status..."
if ! minikube status &>/dev/null; then
  echo "❌ Minikube is not running. Please start it:"
  echo "   minikube start"
  exit 1
fi
echo "✅ Minikube is running"

# Check monitoring namespace
echo -e "\n2. Checking monitoring namespace..."
if kubectl get namespace monitoring &>/dev/null; then
  echo "✅ Monitoring namespace exists"
else
  echo "❌ Monitoring namespace does not exist. Deploy monitoring stack first:"
  echo "   npm run monitoring:deploy"
  exit 1
fi

# Check monitoring pods
echo -e "\n3. Checking monitoring pods..."
kubectl get pods -n monitoring

# Check if Grafana pod is running
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$GRAFANA_POD" ]; then
  echo -e "\n4. Grafana pod status:"
  kubectl get pod "$GRAFANA_POD" -n monitoring

  # Check if pod is ready
  if kubectl get pod "$GRAFANA_POD" -n monitoring -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
    echo "✅ Grafana pod is ready"
  else
    echo "❌ Grafana pod is not ready. Check logs:"
    echo "   kubectl logs -n monitoring $GRAFANA_POD"
  fi
else
  echo "❌ Grafana pod not found. Deploy monitoring stack first:"
  echo "   npm run monitoring:deploy"
  exit 1
fi

# Check Grafana service
echo -e "\n5. Checking Grafana service..."
kubectl get service -n monitoring | grep grafana

# Check ingress
echo -e "\n6. Checking ingress..."
kubectl get ingress -n monitoring

# Check /etc/hosts
echo -e "\n7. Checking /etc/hosts..."
if grep -q "grafana.local" /etc/hosts; then
  echo "✅ grafana.local found in /etc/hosts"
else
  echo "❌ grafana.local not found in /etc/hosts. Add it:"
  echo "   echo '127.0.0.1 grafana.local' | sudo tee -a /etc/hosts"
fi

# Instructions
echo -e "\n📋 Next Steps:"
echo "1. Start port-forwarding:"
echo "   kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 80:80"
echo "2. Open: http://grafana.local"
echo "3. Login: admin / admin123"

echo -e "\n🔍 Debug Commands:"
echo "   kubectl logs -n monitoring $GRAFANA_POD"
echo "   kubectl describe pod -n monitoring $GRAFANA_POD"
echo "   kubectl get events -n monitoring"
