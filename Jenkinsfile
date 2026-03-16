pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "yashusn/hello-world-war"
        HELM_CHART = "hello-world-war-helm"
        ARTIFACTORY_URL = "https://trials7020p.jfrog.io/artifactory/api/helm/hello-wold-war-helm"
        BUILD_NUMBER_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        ARTIFACTORY_CREDENTIALS = credentials('JFROG_CREDS')
        K8S_NAMESPACE = 'my-jenkins'
    }
    
    stages {
        stage('Build') {
            steps {
                // [3] Checkout source code
                checkout scm
                
                // [4] Build Docker image using multi-stage Dockerfile
                script {
            def image = docker.build("yashusn/hello-world-war:${BUILD_NUMBER}")
        }
                
                // [5] Package Helm chart
                sh 'helm package hello-world-war-helm/'
            }
        }
        
        stage('Publish') {
            steps {
                // [6] Push Docker image to registry
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials-id') {
                        def image = docker.image("${DOCKER_IMAGE}:${BUILD_NUMBER_TAG}")
                        image.push()
                        image.push('latest')
                    }
                }
                
                // [7] Push Helm chart to JFrog Artifactory
                sh """
                    curl -u ${ARTIFACTORY_CREDENTIALS} \\
                         -T hello-world-war-${BUILD_NUMBER_TAG}.tgz \\
                         "${ARTIFACTORY_URL}/hello-world-war-${BUILD_NUMBER_TAG}.tgz"
                """
            }
        }
        
        stage('Deploy') {
            steps {
                // [8] Pull Helm chart from JFrog Artifactory
                sh """
                    helm repo add hello-world-war ${ARTIFACTORY_URL}
                    helm repo update
                """
                
                // [9][10] Install/Upgrade with build number as image tag
                sh """
                    helm upgrade --install hello-world-war \\
                        hello-world-war/hello-world-war \\
                        --namespace ${K8S_NAMESPACE} \\
                        --set image.repository=${DOCKER_IMAGE} \\
                        --set image.tag=${BUILD_NUMBER_TAG} \\
                        --create-namespace
                """
            }
        }
    }
    
    post {
        always {
            sh 'helm repo remove hello-world-war || true'
            sh 'docker system prune -f'
            cleanWs()
        }
    }
}
