pipeline {
    agent {
		docker {
            image 'docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
        }
	}

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
                    docker.withRegistry('', 'docker-key') {
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
                      -p 8088:8080 \
                      ${IMAGE_NAME}:latest
                """
            }
        }
    }
}
