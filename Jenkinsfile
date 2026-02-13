pipeline {
    agent any

    environment {
        IMAGE_NAME = "yashusn/tomcat-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
        CONTAINER_NAME = "tomcat-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your/repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                   docker build -t $IMAGE_NAME:$IMAGE_TAG .
                """
            }
        }

        stage('Publish Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh """
                       echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                       docker push $IMAGE_NAME:$IMAGE_TAG
                       docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
                       docker push $IMAGE_NAME:latest
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                sh """
                   docker pull $IMAGE_NAME:latest

                   # Stop old container if exists
                   docker ps -q --filter "name=$CONTAINER_NAME" | grep -q . && \
                   docker stop $CONTAINER_NAME || true

                   docker ps -aq --filter "name=$CONTAINER_NAME" | grep -q . && \
                   docker rm $CONTAINER_NAME || true

                   # Run new container
                   docker run -d \
                     --name $CONTAINER_NAME \
                     -p 8080:8080 \
                     $IMAGE_NAME:latest
                """
            }
        }
    }

    # post {
        # always {
            # sh "docker image prune -f || true"
        # }
    # }
}
