pipeline {
    agent none

    environment {
        DOCKER_IMAGE = 'yashusn/hello-world-war'
        ARTIFACTORY_URL = 'https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Build & Push') {
            agent {
                docker {
                    image 'gcr.io/kaniko-project/executor:debug'
                    // Mount the config secret you defined in your Helm chart earlier
                    args '--entrypoint="" -v /kaniko/.docker:/kaniko/.docker'
                }
            }
            steps {
                git branch: 'main', url: 'https://github.com/yashusn/hello-world-war.git'
                
                // Using Kaniko: No Docker daemon required, very secure for K8s
                sh """
                /kaniko/executor \
                  --dockerfile=Dockerfile \
                  --context=dir://\$WORKSPACE \
                  --destination=${DOCKER_IMAGE}:${BUILD_TAG} \
                  --destination=${DOCKER_IMAGE}:latest \
                  --skip-tls-verify
                """
            }
        }

        stage('Package & Publish Helm') {
            agent {
                docker { image 'alpine/helm:3.13' }
            }
            steps {
                // No need to curl/tar Helm; it's already in the image
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

        stage('Deploy') {
            agent {
                docker { image 'alpine/helm:3.13' }
            }
            steps {
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
                        --namespace default --create-namespace \
                        --set image.pullPolicy=Always
                    """
                }
            }
        }
    }
}
