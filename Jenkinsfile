pipeline {
   // agent { label 'Java' }
agent none
	parameters {
string(name: 'mcmd1', defaultValue: 'clean', description: 'maven clean command')
booleanParam(name: 'SAMPLE_BOOLEAN', defaultValue: true, description: 'A boolean parameter')
choice(name: 'mcmd2', choices: ['Package', 'compile', 'install','validate'], description: 'Choose one option')
}
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
                sh "mvn $mcmd1 $mcmd2"
              }
        }
        stage('Deploy') {
		agent { label 'Java' }
            steps {
                sh "sudo cp /home/slave1/workspace/job_hello_word_jenkin/target/hello-world-war-1.0.0.war /opt/apache-tomcat-10.1.49/webapps"
                           }
        }
    }
}
}
}
