pipeline {
    agent none
    
    environment {
        DOCKER_IMAGE = 'yashusn/hello-world-war'
        ARTIFACTORY_URL = 'https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm'
        BUILD_NUMBER_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Build') {
            steps {
                // [3] Checkout
                git branch: 'main', url: 'https://github.com/yashusn/hello-world-war.git'
                
                // [4] Build Docker image
				
        sh '''
        /kaniko/executor \
          --dockerfile=Dockerfile \
          --context=dir://$WORKSPACE \
          --destination=yashusn/custom-jenkins:latest \
          --skip-tls-verify
        '''
    }
}
				
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER_TAG} ."
                
                // [5] Package Helm chart
                sh """
                    curl -LO https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
                    tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
                    mv linux-amd64/helm /usr/local/bin/helm
                    helm package hello-world-war-helm/ --version ${BUILD_NUMBER_TAG}
                """
            }
        }
        
        stage('Publish') {
            agent {
                docker {
                    image 'docker:20.10-dind'
                    args '--privileged --user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                // [6] Push Docker image
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', 
                                 usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER_TAG}
                        docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER_TAG} ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
                
                // [7] Push Helm chart to JFrog
                withCredentials([usernamePassword(credentialsId: 'jfrog-credentials', 
                                 usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')]) {
                    sh """
                        curl -u ${JFROG_USER}:${JFROG_PASS} \\
                             -T hello-world-war-helm-${BUILD_NUMBER_TAG}.tgz \\
                             "${ARTIFACTORY_URL}/hello-world-war-helm-${BUILD_NUMBER_TAG}.tgz"
                    """
                }
            }
        }
        
        stage('Deploy') {
            agent {
                docker {
                    image 'alpine/helm:3.13'
                    args '--user root'
                }
            }
            steps {
                // [8][9][10] Deploy from Artifactory
                withCredentials([usernamePassword(credentialsId: 'jJFORG_CREDS', 
                                 usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_PASS')]) {
                    sh """
                        helm repo add hello-world-war ${ARTIFACTORY_URL} \\
                            --username ${JFROG_USER} --password ${JFROG_PASS}
                        helm repo update
                        
                        helm upgrade --install hello-world-war \\
                            hello-world-war/hello-world-war-helm \\
                            --set image.repository=${DOCKER_IMAGE} \\
                            --set image.tag=${BUILD_NUMBER_TAG} \\
                            --namespace default --create-namespace \\
                            --set image.pullPolicy=Always
                    """
                }
            }
        }
    }
}
