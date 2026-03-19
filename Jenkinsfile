// ═══════════════════════════════════════════════════════════════════
// Jenkins Declarative Pipeline
// Repo: https://github.com/yashusn/hello-world-war.git
// ═══════════════════════════════════════════════════════════════════

pipeline {
    agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
  - name: helm
    image: alpine/helm:3.14.0
    command: ['sleep', '99999']
  - name: jnlp
    image: jenkins/inbound-agent:latest
"""
      defaultContainer 'jnlp'
    }
  }

    // ── Global environment variables ──────────────────────────────────
  environment {
    GIT_REPO         = 'https://github.com/yashusn/hello-world-war.git'
    GIT_BRANCH       = 'master'
    DOCKER_IMAGE     = 'yashusn/hello-world-war'
    IMAGE_TAG        = "${env.BUILD_NUMBER}"       // unique per build
    HELM_CHART_NAME  = 'my-helloworld'
    HELM_CHART_DIR   = 'helm/my-helloworld'
    HELM_NAMESPACE   = 'default'
    HELM_RELEASE     = 'helloworld-release'
    JFROG_URL        = 'https://trials7020p.jfrog.io/artifactory'
    JFROG_REPO       = 'helm-local'
    CHART_VERSION    = "0.1.${env.BUILD_NUMBER}"  // versioned per build
  }

  stages {

        // ────────────────────────────────────────────────────────────────
    // STAGE 1: Checkout from Git
    // ────────────────────────────────────────────────────────────────
    stage('Checkout') {
      steps {
        git branch: "${GIT_BRANCH}",
            credentialsId: 'github-token',
            url: "${GIT_REPO}"
        echo "✅ Checked out branch: ${GIT_BRANCH}, commit: ${env.GIT_COMMIT}"
      }
    }

        // ────────────────────────────────────────────────────────────────
    // STAGE 2: Build Docker Image
    // ────────────────────────────────────────────────────────────────
    stage('Build Docker Image') {
      steps {
        script {
          // Build the image; tag with build number for traceability
          sh """
            docker build \\
              -t ${DOCKER_IMAGE}:${IMAGE_TAG} \\
              -t ${DOCKER_IMAGE}:latest \\
              .
          """
          echo "✅ Image built: ${DOCKER_IMAGE}:${IMAGE_TAG}"
        }
      }
    }

        // ────────────────────────────────────────────────────────────────
    // STAGE 3: Push Docker Image to Docker Hub
    // ────────────────────────────────────────────────────────────────
    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh """
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
            docker push ${DOCKER_IMAGE}:latest
            docker logout
          """
        }
        echo "✅ Pushed to Docker Hub: ${DOCKER_IMAGE}:${IMAGE_TAG}"
      }
    }

        // ────────────────────────────────────────────────────────────────
    // STAGE 4: Create / Update Helm Chart values + lint
    // ────────────────────────────────────────────────────────────────
    stage('Prepare Helm Chart') {
      steps {
        script {
          // Update Chart.yaml with the versioned chart + app version
          sh """
            sed -i "s/^version:.*/version: ${CHART_VERSION}/" \\
              ${HELM_CHART_DIR}/Chart.yaml
            sed -i "s/^appVersion:.*/appVersion: \\"${IMAGE_TAG}\\"/" \\
              ${HELM_CHART_DIR}/Chart.yaml
          """

          // Lint the chart — fails build if YAML is invalid
          sh "helm lint ${HELM_CHART_DIR}"
          echo "✅ Helm chart linted OK, version: ${CHART_VERSION}"
        }
      }
    }

        // ────────────────────────────────────────────────────────────────
    // STAGE 5: Deploy to Kubernetes via Helm (with Ingress)
    // ────────────────────────────────────────────────────────────────
    stage('Deploy via Helm') {
      steps {
        withCredentials([file(
          credentialsId: 'kubeconfig',
          variable: 'KUBECONFIG'
        )]) {
          script {
            sh """
              # helm upgrade --install = deploy if not exists, upgrade if exists
              helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_DIR} \\
                --namespace ${HELM_NAMESPACE} \\
                --create-namespace \\
                --set image.repository=${DOCKER_IMAGE} \\
                --set image.tag=${IMAGE_TAG} \\
                --set ingress.enabled=true \\
                --set ingress.hosts[0].host=helloworld.yourdomain.com \\
                --wait \\
                --timeout 5m
            """

            // Verify the rollout succeeded
            sh """
              kubectl rollout status deployment/${HELM_RELEASE} \\
                -n ${HELM_NAMESPACE} --timeout=5m
            """

            echo "✅ Deployed release: ${HELM_RELEASE} with image tag: ${IMAGE_TAG}"
          }
        }
      }
    }

        // ────────────────────────────────────────────────────────────────
    // STAGE 6: Package Helm chart & Push to JFrog via Helm Registry
    // ────────────────────────────────────────────────────────────────
    stage('Push Helm Chart to JFrog') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'jfrog_creds',
          usernameVariable: 'JFROG_USER',
          passwordVariable: 'JFROG_PASS'
        )]) {
          script {
            // ── Step A: Package the chart into a .tgz ──────────────────
            sh """
              helm package ${HELM_CHART_DIR} \\
                --version ${CHART_VERSION} \\
                --app-version ${IMAGE_TAG} \\
                --destination .
            """

            // ── Step B: Add JFrog as OCI/Helm registry & push ──────────
            sh """
              # Login to JFrog Helm (OCI) registry
              echo "${JFROG_PASS}" | helm registry login \\
                youraccount.jfrog.io \\
                --username "${JFROG_USER}" \\
                --password-stdin

              # Push .tgz as OCI chart to JFrog
              helm push ${HELM_CHART_NAME}-${CHART_VERSION}.tgz \\
                oci://youraccount.jfrog.io/${JFROG_REPO}

              helm registry logout youraccount.jfrog.io
            """

            echo "✅ Helm chart pushed to JFrog: ${HELM_CHART_NAME}-${CHART_VERSION}.tgz"
          }
        }
      }
    }

  } // end stages

    // ── Post actions ──────────────────────────────────────────────────
  post {
    success {
      echo "🎉 Pipeline completed successfully! Build #${BUILD_NUMBER}"
    }
    failure {
      echo "❌ Pipeline failed at stage. Check logs above."
    }
    always {
      // Clean workspace to free disk space
      cleanWs()
    }
  }

}
