#!/bin/bash
kubectl port-forward -n monitoring service/prometheus-grafana 3000:80 &
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-prometheus 9091:9090 &
kubectl port-forward -n monitoring service/prometheus-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward -n cicd service/argocd-server 9090:443 &
kubectl port-forward -n logging service/kibana-kb-http 5601:5601 &
kubectl port-forward -n kubeview service/kubeview 8888:8000 &
kubectl port-forward -n logging service/elasticsearch-master 9200:9200 &

GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d)
ARGO_PASSWORD=$(kubectl -n cicd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
KIBANA_PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -n logging -o jsonpath='{.data.elastic}' | base64 -d)

echo "============================================="
echo "Grafana:        http://127.0.0.1:3000"
echo "Password:       $GRAFANA_PASSWORD"
echo ""
echo "ArgoCD:         https://127.0.0.1:9090"
echo "Password:       $ARGO_PASSWORD"
echo ""
echo "Prometheus:     http://127.0.0.1:9091"
echo "Alertmanager:   http://127.0.0.1:9093"
echo ""
echo "Kibana:         http://127.0.0.1:5601"
echo "Password:       $KIBANA_PASSWORD"
echo "Elasticsearch:  https://127.0.0.1:9200"
echo "Elasticsearch:  https://127.0.0.1:8888"
echo "============================================="
echo "Press Ctrl+C to stop all port-forwards"
wait