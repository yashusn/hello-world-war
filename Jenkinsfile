apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24.0-dind          # ← dind REQUIRED
    command: ["/usr/local/bin/dockerd-entrypoint.sh"]
    args: ["dockerd"]                # ← dockerd daemon
    privileged: true                 # ← REQUIRED for dind
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        cpu: "100m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"

  - name: helm
    image: alpine/helm:3.14.2        # ← Stable version
    command: ["sleep"]
    args: ["99d"]                    # ← Keeps alive
    tty: true
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
