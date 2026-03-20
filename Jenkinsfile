pipeline {
  agent { label 'built-in' }

  environment {
    DOCKER_IMAGE    = 'yashusn/hello-world-war'
    IMAGE_TAG       = "${env.BUILD_NUMBER}"
    HELM_CHART_DIR  = 'helm'
    HELM_RELEASE    = 'helloworld-release'
    HELM_NAMESPACE  = 'default'
    CHART_VERSION   = "0.1.${env.BUILD_NUMBER}"
    JFROG_URL       = 'https://trials7020p.jfrog.io/'
    JFROG_REPO      = 'helm-local'
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'master',
            credentialsId: 'github-token',
            url: 'https://github.com/yashusn/hello-world-war.git'
        echo "Checked out commit: ${env.GIT_COMMIT}"
      }
    }

    stage('Build & Push Docker Image via Kaniko') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          script {
            sh """
              kubectl run kaniko-${BUILD_NUMBER} \
                --image=gcr.io/kaniko-project/executor:latest \
                --restart=Never \
                --namespace=jenkins \
                --overrides='{
                  "spec": {
                    "containers": [{
                      "name": "kaniko",
                      "image": "gcr.io/kaniko-project/executor:latest",
                      "args": [
                        "--context=git://github.com/yashusn/hello-world-war.git#refs/heads/master",
                        "--destination=yashusn/hello-world-war:${BUILD_NUMBER}",
                        "--destination=yashusn/hello-world-war:latest",
                        "--cache=true"
                      ],
                      "volumeMounts": [{
                        "name": "kaniko-secret",
                        "mountPath": "/kaniko/.docker"
                      }]
                    }],
                    "volumes": [{
                      "name": "kaniko-secret",
                      "secret": {
                        "secretName": "kaniko-secret",
                        "items": [{"key": "config.json", "path": "config.json"}]
                      }
                    }],
                    "restartPolicy": "Never"
                  }
                }' \
                --timeout=300s

              kubectl wait pod/kaniko-${BUILD_NUMBER} \
                --for=condition=Ready \
                --namespace=jenkins \
                --timeout=300s || true

              kubectl logs -n jenkins kaniko-${BUILD_NUMBER} -f

              kubectl delete pod kaniko-${BUILD_NUMBER} -n jenkins
            """
          }
        }
      }
    }

    stage('Prepare Helm Chart') {
      steps {
        script {
          sh """
            sed -i "s/^version:.*/version: ${CHART_VERSION}/" ${HELM_CHART_DIR}/Chart.yaml
            sed -i "s/^appVersion:.*/appVersion: \\"${IMAGE_TAG}\\"/" ${HELM_CHART_DIR}/Chart.yaml
            helm lint ${HELM_CHART_DIR}
          """
        }
      }
    }

    stage('Deploy via Helm') {
      steps {
        script {
          sh """
            helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_DIR} \
              --namespace ${HELM_NAMESPACE} \
              --create-namespace \
              --set image.repository=${DOCKER_IMAGE} \
              --set image.tag=${IMAGE_TAG} \
              --wait \
              --timeout 5m
          """
        }
      }
    }

    stage('Print Access URL') {
      steps {
        script {
          sh """
            echo "======================================================"
            echo "   DEPLOYMENT SUCCESSFUL - ACCESS INFORMATION"
            echo "======================================================"

            ELB=\$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
              -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

            echo ""
            echo "  App URL    : http://\${ELB}/helloworld/"
            echo "  Jenkins URL: http://\${ELB}/"
            echo "  Image Tag  : ${DOCKER_IMAGE}:${IMAGE_TAG}"
            echo "  Namespace  : ${HELM_NAMESPACE}"
            echo "  Release    : ${HELM_RELEASE}"
            echo ""

            echo "--- Ingress ---"
            kubectl get ingress -n ${HELM_NAMESPACE}

            echo ""
            echo "--- Pods ---"
            kubectl get pods -n ${HELM_NAMESPACE}

            echo ""
            echo "--- Services ---"
            kubectl get svc -n ${HELM_NAMESPACE}

            echo "======================================================"
          """
        }
      }
    }
stage('Push Helm Chart to JFrog') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'jfrog-creds',
            usernameVariable: 'JFROG_USER',
            passwordVariable: 'JFROG_PASS'
        )]) {
            script {
                sh '''
                    # 1. Install the Helm Push plugin (if not already installed on the agent)
                    if ! helm plugin list | grep -q "push"; then
                        helm plugin install https://github.com/chartmuseum/helm-push
                    fi

                    # 2. Package the chart
                    helm package helm \
                        --version "0.1.${BUILD_NUMBER}" \
                        --app-version "0.1.${BUILD_NUMBER}" \
                        --destination .

                    # 3. Add the JFrog Helm repository to the local Helm client
                    helm repo add jfrog-repo https://trials7020p.jfrog.io/artifactory/hello-wold-war-helm-local/ \
                        --username ${JFROG_USER} \
                        --password ${JFROG_PASS}

                    # 4. Push the chart using the 'cm-push' command (provided by the plugin)
                    # Note: We use the local repo name 'jfrog-repo' defined in the previous step
                    helm cm-push my-helloworld-0.1.${BUILD_NUMBER}.tgz jfrog-repo
                    
                    # 5. Clean up local repo config (optional but good practice)
                    helm repo remove jfrog-repo
                '''
            }
        }
    }
}
    

  }

  post {
    success { echo "Pipeline complete! Build #${BUILD_NUMBER}" }
    failure { echo "Pipeline failed. Check logs." }
    always  { deleteDir() }
  }
}
