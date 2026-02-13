pipeline {
    agent { label 'docker' }

    environment {
        IMAGE_NAME = "yashusn/tomcat-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
        CONTAINER_NAME = "tomcat-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/yashusn/hello-world-war.git'
            }
        }

        stage('Build') {
            steps {
                script {
                    app = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }

        stage('Publish') {
            steps {
                script {
                    docker.withRegistry('', '4c2699fc-9b3b-4212-8405-f82be29c610c') {
                        app.push("${IMAGE_TAG}")
                        app.push("latest")
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh """
                    docker pull ${IMAGE_NAME}:latest

                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p 8080:8080 \
                      ${IMAGE_NAME}:latest
                """
            }
        }
    }
}
