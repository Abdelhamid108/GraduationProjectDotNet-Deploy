#!/usr/bin/env groovy

// -----------------------------------------------------------------------------
// Shared Library Import
// -----------------------------------------------------------------------------
library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
    [
        $class: 'GitSCMSource',
        remote: 'https://github.com/Abdelhamid108/jenkins_Shared-Library.git',
    ]
)

// -----------------------------------------------------------------------------
// Global Constants & Configuration
// -----------------------------------------------------------------------------
// Define the list of services and files to monitor for changes.
// This centralizes the configuration, making it easier to add new services.
def MONITORED_PATHS = ['backend', 'nginx-proxy', 'docker-compose.yml']

pipeline {
    agent any

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameters {
        // Operational Flag: Allows manual override to force a full redeployment.
        // Useful for disaster recovery, fresh environment setup, or forcing updates.
        booleanParam(name: 'IsFirstRun', defaultValue: false, description: 'Force rebuild and redeploy of all components')
    }

    // -------------------------------------------------------------------------
    // Environment Variables
    // -------------------------------------------------------------------------
    environment {
        REGISTRY              = 'abdelhameed208'
        BACKEND_IMAGE         = 'graduationproject-backend'
        WEB_SERVER_IMAGE      = 'graduationproject-nginx'
        DOCKER_CREDENTIALS_ID = 'docker-hub-cred'
        ENV_FILE              = 'docker_compose_env'
        
        // Service Names (Constants for cleaner usage in logic)
        SVC_BACKEND           = 'backend'
        SVC_FRONTEND          = 'nginx-proxy'
        FILE_COMPOSE          = 'docker-compose.yml'
    }

    stages {
        // ---------------------------------------------------------------------
        // Stage: Check Differences
        // Purpose: Detect which services have changed since the last deployment.
        // ---------------------------------------------------------------------
        stage('Check_Diffs') {
            steps {
                script {
                    echo "Checking for changes in monitored paths: ${MONITORED_PATHS}"

                    // Invoke Shared Library step to detect changes
                    def changedServices = checkServiceChanges(
                        baseBranch: 'main',
                        servicePaths: MONITORED_PATHS
                    )

                    if (!changedServices) {
                        echo "No changes detected."
                        env.SERVICES_TO_UPDATE = ""
                    } else {
                        echo "Identified services requiring update: ${changedServices.join(', ')}"
                        env.SERVICES_TO_UPDATE = changedServices.join(',')
                    }

                    // Calculate dynamic version tags based on git commit counts
                    // This ensures unique tags for every change in the respective directories
                    def backend_count = sh(script: "git rev-list --count HEAD ${SVC_BACKEND}/ || echo 0", returnStdout: true).trim()
                    def frontend_count = sh(script: "git rev-list --count HEAD ${SVC_FRONTEND}/ || echo 0", returnStdout: true).trim()

                    env.BACKEND_IMAGE_TAG = "v1.0-${backend_count}"
                    env.FRONTEND_IMAGE_TAG = "v1.0-${frontend_count}"
                }
            }
        }

        // ---------------------------------------------------------------------
        // Stage: Build & Push Images
        // Purpose: Build Docker images for changed services and push to registry.
        // ---------------------------------------------------------------------
        stage('Build & Push Images') {
            parallel {
                // --- Sub-stage: Backend ---
                stage('Build Backend') {
                    when {
                        expression {
                            // Build if backend changed OR if forced by parameter
                            return (env.SERVICES_TO_UPDATE && env.SERVICES_TO_UPDATE.contains(SVC_BACKEND)) || params.IsFirstRun == true
                        }
                    }
                    steps {
                        script {
                            echo "Building Backend Service..."
                            dir(SVC_BACKEND) {
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

                // --- Sub-stage: Frontend ---
                stage('Build Frontend') {
                    when {
                        expression {
                            // Build if frontend changed OR if forced by parameter
                            return (env.SERVICES_TO_UPDATE && env.SERVICES_TO_UPDATE.contains(SVC_FRONTEND)) || params.IsFirstRun == true
                        }
                    }
                    steps {
                        script {
                            echo "Building Frontend Service..."
                            dir(SVC_FRONTEND) {
                                withDockerRegistry(credentialsId: env.DOCKER_CREDENTIALS_ID) {
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

        // ---------------------------------------------------------------------
        // Stage: Deploy
        // Purpose: Update the running stack if any service or config changed.
        // ---------------------------------------------------------------------
        stage('Deploy') {
            when { 
                expression { 
                    // Deploy if any monitored component changed OR if forced
                    boolean anyServiceChanged = env.SERVICES_TO_UPDATE && (
                        env.SERVICES_TO_UPDATE.contains(SVC_FRONTEND) || 
                        env.SERVICES_TO_UPDATE.contains(SVC_BACKEND) || 
                        env.SERVICES_TO_UPDATE.contains(FILE_COMPOSE)
                    )
                    return anyServiceChanged || params.IsFirstRun == true 
                }
            }
            steps {
                script {
                    echo "Starting Deployment..."
                    withCredentials([file(credentialsId: env.ENV_FILE, variable: 'SECURE_ENV_FILE')]) {
                        // Ensure we have the latest code (docker-compose.yml)
                        sh "cp ${SECURE_ENV_FILE} ./.env"

                        // Pull new images and restart services
                        sh "docker-compose pull"
                        sh "docker-compose up -d"
                     
                        echo "The app Deployed Successfully"
                    }
                }
            }
        }
    }
}

