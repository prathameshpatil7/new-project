pipeline {
    agent any
    triggers {
        githubPush()
    }
    tools {
        jdk 'jdk21'
        maven 'maven3'
    }
    environment {
        DOCKERHUB_CREDS = credentials('dockerhub-creds')
        DOCKER_IMAGE_NAME = "patilprathamesh/petclinic"
        GITOPS_REPO_URL = "https://github.com/prathameshpatil7/petclinic-gitops.git"
        GITOPS_REPO_CREDS = 'gitops-repo-creds'
        // SCANNER_HOME = tool 'sonar-scanner'
    }


    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'docker', url: 'https://github.com/prathameshpatil7/Java-maven-CICD-Project.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('SonarQube Analysis & Quality Gate') {
            steps {
                withSonarQubeEnv('MySonar') {
                    // Run the Sonar analysis with Maven
                    sh 'mvn clean verify sonar:sonar'
                    
                }
            }
            post {
                always {
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false
                    }
                }
            }
        }
        stage('OWASP Dependency-Check') {
            steps {
		  withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_KEY')]) {
		        dependencyCheck additionalArguments: """
        			--data /var/lib/jenkins/odc-data \
        			--nvdApiKey ${NVD_KEY} \
        			--scan target 
        		    """, odcInstallation: 'Default-DC'
		        }
		        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}"
                    docker.build(DOCKER_IMAGE_NAME + ":${BUILD_NUMBER}", ".")
                }
            }
        }
        
        stage('Run Docker Container for Testing') {
            steps {
                script {
                    echo "Running container for testing..."
                    sh """
                        docker run -d --name petclinic-test -p 8080:8080 ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                        sleep 30
                        docker ps
                        docker logs petclinic-test
                    """
                }
            }
        }

        stage('Vulnerability Scan with Trivy') {
            steps {
                echo "Scanning image for HIGH and CRITICAL vulnerabilities..."
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}"
            }
        }
        
         stage('Push to DockerHub') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub-creds', url: 'https://index.docker.io/v1/', toolName: 'docker') {
                        sh """
                            echo "Tagging and pushing Docker image..."
                            docker tag ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} ${DOCKER_IMAGE_NAME}:latest
                            docker push ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${DOCKER_IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('Update GitOps Repository') {
            steps {
                // Check out the GitOps repo in a separate directory
                dir('gitops-repo') {
                        git branch: 'main', credentialsId: 'gitops-repo-creds', url: 'https://github.com/prathameshpatil7/petclinic-gitops.git' 
                        sh "ls"
                        // Update the image tag in the deployment file
                        sh "sed -i 's|image: .*|image: ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}|g' deployment.yaml"
                        
                        withCredentials([usernamePassword(credentialsId: 'gitops-repo-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                                sh """
                                    git config --global user.email 'jenkins@example.com'
                                    git config --global user.name 'Jenkins CI'
                                    git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/prathameshpatil7/petclinic-gitops.git
                                    git commit -am 'Update image to version ${BUILD_NUMBER}' || echo "No changes to commit"
                                    git push origin main
                                """
                        }
                    }       
                }
            }
        
    }
}
