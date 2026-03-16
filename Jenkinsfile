pipeline {
  agent {
    kubernetes {
      label 'helm-agent'
      defaultContainer 'jnlp'
      containers ([
        containerTemplate(
          name: 'docker', 
          image: 'docker:24.0-dind',
          privileged: true,
          ttyEnabled: true,
          command: '/usr/local/bin/dockerd-entrypoint.sh',
          args: 'dockerd',
          resourceRequestCpu: '100m',
          resourceRequestMemory: '512Mi',
          resourceLimitCpu: '500m',
          resourceLimitMemory: '1Gi'
        ),
        containerTemplate(
          name: 'helm', 
          image: 'alpine/helm:3.14.2',
          ttyEnabled: true,
          command: 'sleep',
          args: '99d',
          resourceRequestCpu: '50m',
          resourceRequestMemory: '128Mi'
        )
      ])
      volumes([
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
      ])
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

    stage('Build & Push Docker') {
      steps {
        container('docker') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                          usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
              docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} .
              docker push $DOCKER_IMAGE:${BUILD_NUMBER}
              docker tag $DOCKER_IMAGE:${BUILD_NUMBER} $DOCKER_IMAGE:latest
              docker push $DOCKER_IMAGE:latest
            '''
          }
        }
      }
    }

    stage('Helm Package') {
      steps {
        container('helm') {
          sh 'helm package helm-chart/'
        }
      }
    }

    stage('Upload Helm') {
      steps {
        container('helm') {
          withCredentials([usernamePassword(credentialsId: 'JFROG_CREDS', 
                          usernameVariable: 'JF_USER', passwordVariable: 'JF_PASS')]) {
            sh '''
              curl -u $JF_USER:$JF_PASS \\
                -T hello-world-war-0.1.0.tgz \\
                "https://trials7020p.jfrog.io/artifactory/hello-wold-war-helm/"
            '''
          }
        }
      }
    }

    stage('Deploy') {
      steps {
        container('helm') {
          withCredentials([usernamePassword(credentialsId: 'JFROG_CREDS', 
                          usernameVariable: 'JF_USER', passwordVariable: 'JF_PASS')]) {
            sh '''
              helm repo add $HELM_REPO_NAME $HELM_REPO_URL \\
                --username $JF_USER --password $JF_PASS
              helm repo update
              helm upgrade --install hello-world \\
                $HELM_REPO_NAME/hello-world-war \\
                --set image.repository=$DOCKER_IMAGE \\
                --set image.tag=${BUILD_NUMBER}
            '''
          }
        }
      }
    }
  }
}
