pipeline {
    agent { label 'Java' }

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
                sh "sudo cp /var/lib/jenkins/workspace/job_hello_word_jenkin/target/hello-world-war-1.0.0.war /opt/apache-tomcat-10.1.49/webapps"
                           }
        }
    }
}
