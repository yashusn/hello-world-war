pipeline {
   // agent { label 'Java' }
agent none
stages { 
    stage ('hello-world-war') {
        parallel {
        stage('Checkout') {
		agent { label 'Java' }
            steps {
                sh "rm -rf hello-world-war"
               sh "git clone https://github.com/yashusn/hello-world-war"
            }
        }
        stage('Build') {
		agent { label 'Java' }
            steps {
                sh "mvn clean package"
              }
        }
        stage('Deploy') {
		agent { label 'Java' }
            steps {
                sh "sudo cp /home/slave2/workspace/job_hello_word_jenkin/target/hello-world-war-1.0.0.war /opt/apache-tomcat-10.1.49/webapps"
                           }
        }
    }
}
}
}
