# Create the Kubernetes Secret from local files.
#
# Run this ONCE (and whenever the key or config changes). It reads the
# private key + config.json from your laptop and pushes them into the
# cluster as a single opaque Secret named "paymentalerts-secrets".
#
# Prereq: kubectl is configured for your target cluster  (kubectl get ns).

param(
  [string] $Namespace = "paymentalerts",
  [string] $KeyPem    = "C:\Users\scoop\paymentalerts\backend\keys\backdoor-priv.pem",
  [string] $ConfigJson = "C:\Users\scoop\Downloads\paymentalerts-k8s\k8s\config.example.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $KeyPem))     { throw "private key not found: $KeyPem" }
if (-not (Test-Path $ConfigJson)) { throw "config.json not found: $ConfigJson  --  copy config.example.json, fill it in, re-run" }

kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

kubectl -n $Namespace delete secret paymentalerts-secrets --ignore-not-found

kubectl -n $Namespace create secret generic paymentalerts-secrets `
    --from-file=backdoor-priv.pem=$KeyPem `
    --from-file=config.json=$ConfigJson

if ($LASTEXITCODE -ne 0) { throw "secret creation failed" }

Write-Host ""
Write-Host "secret paymentalerts-secrets created in namespace $Namespace"
kubectl -n $Namespace get secret paymentalerts-secrets -o wide
