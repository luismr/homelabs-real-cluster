#!/bin/bash
set -e
kubectl get configmap -n monitoring loki-loki-stack -o yaml
