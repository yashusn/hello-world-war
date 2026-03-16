pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24.0
    command: ["sleep", "99d"]
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"

  - name: helm
    image: alpine/helm:3.14.2
    command: ["sleep", "99d"]
    tty: true
    resources:
      requests:
        cpu:
