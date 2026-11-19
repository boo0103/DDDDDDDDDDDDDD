# paymentalerts backend on Kubernetes

Drop-in deploy for the paymentalerts backend onto any Kubernetes cluster.
The container image is built from the pre-built jar at
`C:\Users\scoop\paymentalerts\backend\build\backdoor-backend.jar`.

## Layout

```
paymentalerts-k8s\
  Dockerfile              image: JRE 21 + the jar, runs as uid 1000
  .dockerignore
  build-and-push.ps1      copy jar in, docker build, docker push
  load-secrets.ps1        kubectl create secret from local key + config
  apply.ps1               kubectl apply -f k8s\*.yaml  (in order)
  k8s\
    00-namespace.yaml
    10-pvc.yaml           1 Gi PVC for signed manifests + plugin jars
    30-deployment.yaml    single-replica, non-root, read-only rootfs
    40-service.yaml       ClusterIP :80 -> pod :8080
    50-ingress.yaml       nginx + Let's Encrypt
    cert-issuer.example.yaml  optional ClusterIssuer
    config.example.json   backend config template
```

## Prereqs

- A cluster you control (`kubectl get nodes` works).
- A container registry you can push to (GHCR, Docker Hub, DO Registry).
- An ingress controller installed (nginx-ingress is assumed).
- cert-manager + a ClusterIssuer named `letsencrypt-prod`, OR remove the
  TLS block from `50-ingress.yaml`.
- A domain with an A record pointing at your ingress controller's external IP.
- Docker Desktop on your laptop for the image build.

Cheap managed-cluster options if you don't have one yet: Linode LKE (free
control plane + $5 node), DOKS ($12 control plane + $4 node), or self-hosted
k3s on a single $5 VPS.

## Deploy, high level

1. `build-and-push.ps1 -Registry "<your-registry>" -Tag "1"` — builds the
   image and pushes it.
2. Edit `k8s\30-deployment.yaml` to reference the image you just pushed.
3. Copy `k8s\config.example.json` to `k8s\config.json`, fill in `base_url`
   and `admin_api_key`.
4. Edit `k8s\50-ingress.yaml`, replace both `REPLACE_ME.example.com` with
   your hostname.
5. `load-secrets.ps1 -ConfigJson .\k8s\config.json` — pushes the private
   key + config.json into a Kubernetes Secret.
6. `apply.ps1` — applies all manifests in order.
7. `kubectl -n paymentalerts get pods -w` — wait for Ready.
8. `curl https://<your-domain>/healthz` should return `ok`.

## Pointing the mod at the cluster

The public key hex stays the same (same keypair, just moved into a Secret),
so only `BASE_URL` in `mod/src/.../BackdoorConfig.java` needs to change to
`https://<your-domain>`. Then rebuild the mod with `gradlew build`.

## Operations

- Logs: `kubectl -n paymentalerts logs -l app=paymentalerts-backend -f`
- Restart: `kubectl -n paymentalerts rollout restart deploy/paymentalerts-backend`
- Rotate admin key: edit `k8s\config.json`, rerun `load-secrets.ps1`, restart deploy.
- Rotate signing key: regenerate locally with the backend's `--init`, rerun
  `load-secrets.ps1`, bake the new pub hex into `BackdoorConfig.java`,
  rebuild + redistribute the mod. Old mod jars will no longer accept pushes.

## Notes on the manifests

- `30-deployment.yaml` uses `strategy: Recreate` because the PVC is
  ReadWriteOnce and both the store and the key are single-writer.
- Root filesystem is read-only; `/tmp` is an emptyDir, store is the PVC,
  config is the Secret mount at `/etc/paymentalerts`.
- Resource requests are tiny (50m CPU / 128 MiB memory); limits are modest
  (500m CPU / 512 MiB) — this service barely uses anything.
- `ingress-nginx` is assumed. If you use Traefik, replace
  `ingressClassName: nginx` and adjust annotations.
