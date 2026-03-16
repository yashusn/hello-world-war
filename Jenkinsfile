pipeline {
  agent {
    kubernetes {
      label 'helm-agent'
      yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24.0-dind
    command: ["/usr/local/bin/dockerd-entrypoint.sh"]
    args: ["dockerd"]
    privileged: true
    tty: true
    resources:
      requests:
        cpu: "100m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: helm
    image: alpine/helm:3.14.2
    command: ["sleep", "99d"]
    tty: true
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
    }
  }

  environment {
    DOCKER_IMAGE = "yashusn/hello-world-war"
    HELM_REPO_URL = "https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm"
    HELM_REPO_NAME = "hello-war"
  }

  stages {
    stage('Checkout') {
      steps { git credentialsId: 'git_creds', url: 'https://github.com/yashusn/hello-world-war.git'
            }
