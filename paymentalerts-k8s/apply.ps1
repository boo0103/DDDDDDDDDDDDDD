# Apply all manifests in k8s/ in order.
#
# Prereqs:
#   - kubectl pointed at your cluster
#   - cert-manager installed (for TLS) with a ClusterIssuer named letsencrypt-prod
#       -- or edit k8s\50-ingress.yaml to skip TLS
#   - an ingress controller (nginx) running
#   - .\load-secrets.ps1 has been run at least once

param(
  [string] $Dir = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "k8s")
)

$ErrorActionPreference = "Stop"

Get-ChildItem -Path $Dir -Filter *.yaml | Sort-Object Name | ForEach-Object {
    Write-Host "applying $($_.Name)" -ForegroundColor Cyan
    kubectl apply -f $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed on $($_.Name)" }
}

Write-Host ""
Write-Host "status:"
kubectl -n paymentalerts get pods,svc,ingress,pvc
