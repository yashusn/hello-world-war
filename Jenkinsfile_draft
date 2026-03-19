pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ["/busybox/cat"]
    tty: true
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
  - name: helm
    image: alpine/helm:3.13.0
    command: ["/bin/sh"]
    tty: true
  volumes:
    - name: docker-config
      secret:
        secretName: regcred
'''
        }
    }

    environment {
        DOCKER_IMAGE = 'yashusn/hello-world-war'
        ARTIFACTORY_URL = 'https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Build & Push') {
            steps {
                container('kaniko') {
                    git branch: 'main', url: 'https://github.com/yashusn/hello-world-war.git'
                    sh """
                    /kaniko/executor \
                      --dockerfile=Dockerfile \
                      --context=dir://\$WORKSPACE \
                      --destination=${DOCKER_IMAGE}:${BUILD_TAG} \
                      --destination=${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Package & Publish') {
            steps {
                container('helm') {
                    sh "helm package hello-world-war-helm/ --version ${BUILD_TAG}"
                    
                    withCredentials([usernamePassword(credentialsId: 'jfrog-credentials', 
                                     usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')]) {
                        sh """
                        curl -u ${JFROG_USER}:${JFROG_PASS} \
                             -T hello-world-war-helm-${BUILD_TAG}.tgz \
                             "${ARTIFACTORY_URL}/hello-world-war-helm-${BUILD_TAG}.tgz"
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                container('helm') {
                    withCredentials([usernamePassword(credentialsId: 'jfrog-credentials', 
                                     usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')]) {
                        sh """
                        helm repo add hello-world-war ${ARTIFACTORY_URL} \
                            --username ${JFROG_USER} --password ${JFROG_PASS}
                        helm repo update
                        
                        helm upgrade --install hello-world-war \
                            hello-world-war/hello-world-war-helm \
                            --set image.repository=${DOCKER_IMAGE} \
                            --set image.tag=${BUILD_TAG} \
                            --namespace default --create-namespace
                        """
                    }
                }
            }
        }
    }
}
