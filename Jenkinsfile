#!/usr/bin/env groovy
library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [
        $class: 'GitSCMSource',
        remote: 'https://github.com/Abdelhamid108/jenkins_Shared-Library.git',
    ]
)

pipeline {
    agent any

    environment {
        REGISTRY              = 'abdelhameed208'
        BACKEND_IMAGE         = 'graduationproject-backend'
        WEB_SERVER_IMAGE      = 'graduationproject-nginx'
        DOCKER_CREDENTIALS_ID = 'docker-hub-cred'
    }

    stages {
        stage('Check_Diffs') {
            steps {
                script {
                    // Check for changes in backend and nginx-proxy directories
                    def changedServices = checkServiceChanges(
                        baseBranch: 'main', 
                        servicePaths: ['backend', 'nginx-proxy']
                    )

                    if (!changedServices) {
                        echo "No changes detected or failed to detect changes."
                        env.SERVICES_TO_UPDATE = ""
                    } else {
                        echo "Identified services requiring update: ${changedServices.join(', ')}"
                        env.SERVICES_TO_UPDATE = changedServices.join(',')
                    }

                    // Calculate version tags based on commit counts
                    // Ensure these directories exist in your repo
                    def backend_count = sh(script: 'git rev-list --count HEAD backend/ || echo 0', returnStdout: true).trim()
                    def frontend_count = sh(script: 'git rev-list --count HEAD nginx-proxy/ || echo 0', returnStdout: true).trim()

                    env.BACKEND_IMAGE_TAG = "v1.0-${backend_count}"
                    env.FRONTEND_IMAGE_TAG = "v1.0-${frontend_count}"
                }
            }
        }

        stage('build & push images') {
            parallel {
                stage('build_backend') {
                    when { 
                        expression { 
                            return env.SERVICES_TO_UPDATE && env.SERVICES_TO_UPDATE.contains('backend') 
                        } 
                    }
                    steps {
                        script {
                            dir('backend') {
                                withDockerRegistry(credentialsId: env.DOCKER_CREDENTIALS_ID) {
                                    def image      = "${REGISTRY}/${BACKEND_IMAGE}"
                                    def build_tag  = "${image}:${env.BACKEND_IMAGE_TAG}"
                                    def latest_tag = "${image}:latest"

                                    sh "docker build -t ${build_tag} ."
                                    sh "docker push ${build_tag}"
                                    sh "docker tag ${build_tag} ${latest_tag}"
                                    sh "docker push ${latest_tag}"
                                }
                            }
                        }
                    }
                }

                stage('build_frontend') {
                    when { 
                        expression { 
                            return env.SERVICES_TO_UPDATE && env.SERVICES_TO_UPDATE.contains('nginx-proxy') 
                        } 
                    }
                    steps {
                        script {
                            dir('nginx-proxy') {
                                withDockerRegistry(credentialsId: env.DOCKER_CREDENTIALS_ID) {
                                    // Use WEB_SERVER_IMAGE and FRONTEND_IMAGE_TAG defined in environment
                                    def image      = "${REGISTRY}/${WEB_SERVER_IMAGE}" 
                                    def build_tag  = "${image}:${env.FRONTEND_IMAGE_TAG}"
                                    def latest_tag = "${image}:latest"

                                    sh "docker build -t ${build_tag} ."
                                    sh "docker push ${build_tag}"
                                    sh "docker tag ${build_tag} ${latest_tag}"
                                    sh "docker push ${latest_tag}"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

