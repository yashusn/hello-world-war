pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                sh "rm -rf hello-world-war"
               sh "git clone https://github.com/yashusn/hello-world-war"
            }
        }
        stage('Build') {
            steps {
                sh "mvn clean package"
              }
        }
        stage('Deploy') {
            steps {
                sh "cp /var/lib/jenkins/workspace/job_hello_word_jenkin/hello-world-war/target/hello-world-war.war /opt/apache-tomcat-10.1.49/webapps"
                           }
        }
    }
}
