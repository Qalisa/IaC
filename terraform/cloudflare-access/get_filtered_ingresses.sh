#!/bin/bash

kubectl get ingress --all-namespaces -o json | \
jq -c '{
  hosts: [
    .items[] | 
    select(.metadata.annotations["cloudflare-access/must-secure"] == "true") | 
    .spec.rules[].host
  ] | unique | join(",")
}'