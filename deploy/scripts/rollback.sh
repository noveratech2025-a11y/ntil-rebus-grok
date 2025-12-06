#!/bin/bash
# NTIL REBUS-GROK Rollback Script

set -e

ENVIRONMENT=$1

echo "⚠️ Rolling back NTIL REBUS-GROK on $ENVIRONMENT..."

case $ENVIRONMENT in
  staging)
    echo "Rolling back Staging..."
    docker compose -f deploy/docker-compose.yml down
    echo "✅ Staging rollback complete - services stopped"
    ;;
    
  production)
    echo "Rolling back Production..."
    
    if ! command -v kubectl &> /dev/null; then
      echo "❌ kubectl not found"
      exit 1
    fi
    
    # Rollback to previous deployment
    kubectl rollout undo deployment/rebus-backend -n rebus
    kubectl rollout undo deployment/rebus-frontend -n rebus
    
    # Wait for rollout
    kubectl rollout status deployment/rebus-backend -n rebus --timeout=5m
    kubectl rollout status deployment/rebus-frontend -n rebus --timeout=5m
    
    echo "✅ Production rollback complete"
    ;;
    
  *)
    echo "❌ Invalid environment"
    exit 1
    ;;
esac
