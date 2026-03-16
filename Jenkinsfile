pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yashusn/hello-world-war"
        HELM_REPO_URL = "https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm"
        HELM_REPO_NAME = "hello-war"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git credentialsId: 'git_creds', url: 'https://github.com/yashusn/hello-world-war.git'
            }
        }
        stage('Install Docker') {
            steps {
                sh '''
                chmod +x scripts/install-docker.sh
                ./scripts/install-docker.sh
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                        sh "docker push $DOCKER_IMAGE:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Package Helm Chart') {
            steps {
                sh "helm package helm-chart"
            }
        }

        stage('Upload Helm Chart to JFrog') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'JFROG_CREDS', usernameVariable: 'JF_USER', passwordVariable: 'JF_PASS')]) {
                    sh """
                    curl -u $JF_USER:$JF_PASS \
                    -T hello-world-war-0.1.0.tgz \
                    https://trials7020p.jfrog.io/artifactory/hello-wold-war-helm/
                    """
                }
            }
        }

        stage('Add Helm Repo') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'JFROG_CREDS', usernameVariable: 'JF_USER', passwordVariable: 'JF_PASS')]) {
                    sh """
                    helm repo add $HELM_REPO_NAME $HELM_REPO_URL \
                    --username $JF_USER \
                    --password $JF_PASS
                    helm repo update
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                helm upgrade --install hello-world \
                $HELM_REPO_NAME/hello-world-war \
                --set image.repository=$DOCKER_IMAGE \
                --set image.tag=${BUILD_NUMBER}
                """
            }
        }
    }
}
