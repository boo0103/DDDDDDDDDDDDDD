# syntax=docker/dockerfile:1.7
#
# Backend image for paymentalerts.
# Pre-built jar is copied in at build time (see build-and-push.ps1).
# At runtime, config.json + private key are mounted from a Kubernetes Secret
# at /etc/paymentalerts/, and the store/ dir comes from a PVC at
# /var/lib/paymentalerts/store.

FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S -g 1000 paymentalerts \
 && adduser -S -u 1000 -G paymentalerts -s /sbin/nologin paymentalerts \
 && mkdir -p /opt/paymentalerts /etc/paymentalerts /var/lib/paymentalerts/store \
 && chown -R paymentalerts:paymentalerts /opt/paymentalerts /var/lib/paymentalerts

COPY --chown=paymentalerts:paymentalerts backdoor-backend.jar /opt/paymentalerts/backdoor-backend.jar

USER paymentalerts
WORKDIR /opt/paymentalerts
EXPOSE 8080

# Config path is the first argument. The Secret volume mount exposes
# /etc/paymentalerts/config.json at runtime.
ENTRYPOINT ["java","-jar","/opt/paymentalerts/backdoor-backend.jar","/etc/paymentalerts/config.json"]
