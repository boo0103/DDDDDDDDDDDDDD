# Build and push the backend container image.
#
# Prereqs: docker CLI installed; logged into your registry (docker login,
# or `echo $PAT | docker login ghcr.io -u <user> --password-stdin` for GHCR).
#
# Usage:
#   .\build-and-push.ps1 -Registry "ghcr.io/boo0103" -Tag "latest"
#
# The jar is copied in from the local paymentalerts backend build/ folder.

param(
  [Parameter(Mandatory=$true)] [string] $Registry,
  [string] $Tag    = "latest",
  [string] $JarSrc = "C:\Users\scoop\paymentalerts\backend\build\backdoor-backend.jar"
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $JarSrc)) {
    throw "backend jar not found at $JarSrc  --  build it first:  cd ..\paymentalerts\backend; .\build.ps1"
}

Copy-Item -Force $JarSrc (Join-Path $here "backdoor-backend.jar")

$image = "$Registry/paymentalerts-backend:$Tag"

docker build -t $image $here
if ($LASTEXITCODE -ne 0) { throw "docker build failed" }

docker push $image
if ($LASTEXITCODE -ne 0) { throw "docker push failed" }

Write-Host ""
Write-Host "pushed: $image"
Write-Host "now edit k8s\30-deployment.yaml and set:  image: $image"
