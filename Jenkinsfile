pipeline {
  agent {
    kubernetes {
      namespace: 'my-jenkins'
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
        cpu: "25m"
        memory: "64Mi"

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
      steps { 
        git credentialsId: 'git_creds', url: 'https://github.com/yashusn/hello-world-war.git'
      }
    }

    stage('Build Docker') {
      steps {
        container('docker') {
          sh '''
            docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
            docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
          '''
        }
      }
    }

    stage('Push Docker') {
      steps {
        container('docker') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                          usernameVariable: 'DOCKER_USER', 
                          passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
              docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
              docker push ${DOCKER_IMAGE}:latest
            '''
          }
        }
      }
    }

    stage('Helm Package & Deploy') {
      steps {
        container('helm') {
          withCredentials([usernamePassword(credentialsId: 'JFROG_CREDS', 
                          usernameVariable: 'JF_USER', 
                          passwordVariable: 'JF_PASS')]) {
            sh '''
              helm package helm-chart/
              curl -u $JF_USER:$JF_PASS -T hello-world-war-0.1.0.tgz \\
                "https://trials7020p.jfrog.io/artifactory/hello-wold-war-helm/"
              helm repo add $HELM_REPO_NAME $HELM_REPO_URL \\
                --username $JF_USER --password $JF_PASS
              helm repo update
              helm upgrade --install hello-world \\
                $HELM_REPO_NAME/hello-world-war \\
                --set image.repository=$DOCKER_IMAGE \\
                --set image.tag=${BUILD_NUMBER} \\
                --namespace default
            '''
          }
        }
      }
    }
  }
}
