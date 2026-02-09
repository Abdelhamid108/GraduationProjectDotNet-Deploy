# CI/CD Integration Guide

This guide explains how to integrate the API testing framework into various CI/CD platforms.

---

## GitHub Actions

### Basic Workflow

Create `.github/workflows/api-tests.yml`:

```yaml
name: API Tests

on:
  # Manual trigger
  workflow_dispatch:
    inputs:
      base_url:
        description: 'API Base URL'
        required: true
        default: 'https://ema2a.ddns.net'
  
  # Trigger on push to main
  push:
    branches: [main]
    paths:
      - 'api-tests/**'
  
  # Scheduled (daily at 6 AM UTC)
  schedule:
    - cron: '0 6 * * *'

jobs:
  api-tests:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
          
          # Install websocat
          WEBSOCAT_VERSION="1.13.0"
          wget -qO /tmp/websocat "https://github.com/vi/websocat/releases/download/v${WEBSOCAT_VERSION}/websocat.x86_64-unknown-linux-musl"
          chmod +x /tmp/websocat
          sudo mv /tmp/websocat /usr/local/bin/
      
      - name: Run API Tests
        id: tests
        run: |
          chmod +x api-tests/run_tests.sh
          ./api-tests/run_tests.sh --base-url ${{ inputs.base_url || 'https://ema2a.ddns.net' }}
        continue-on-error: true
      
      - name: Upload Test Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: api-test-report-${{ github.run_number }}
          path: api-tests/reports/
          retention-days: 30
      
      - name: Check test results
        if: steps.tests.outcome == 'failure'
        run: |
          echo "::error::API tests failed. Check the test report for details."
          exit 1
```

### With Secrets for Authentication

```yaml
jobs:
  api-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run API Tests
        env:
          TEST_USERNAME: ${{ secrets.API_TEST_USERNAME }}
          TEST_PASSWORD: ${{ secrets.API_TEST_PASSWORD }}
        run: |
          chmod +x api-tests/run_tests.sh
          ./api-tests/run_tests.sh --base-url ${{ inputs.base_url }}
```

### Matrix Testing (Multiple Environments)

```yaml
jobs:
  api-tests:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        environment:
          - name: staging
            url: https://staging.ema2a.ddns.net
          - name: production
            url: https://ema2a.ddns.net
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run tests on ${{ matrix.environment.name }}
        run: |
          ./api-tests/run_tests.sh --base-url ${{ matrix.environment.url }}
```

---

## Jenkins

### Declarative Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        string(
            name: 'BASE_URL',
            defaultValue: 'https://ema2a.ddns.net',
            description: 'API Base URL to test'
        )
        booleanParam(
            name: 'RUN_WS_TESTS',
            defaultValue: true,
            description: 'Include WebSocket tests'
        )
    }
    
    environment {
        TEST_USERNAME = credentials('api-test-username')
        TEST_PASSWORD = credentials('api-test-password')
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                    # Install jq if not present
                    which jq || sudo apt-get install -y jq
                    
                    # Install websocat
                    which websocat || {
                        wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
                        chmod +x /tmp/websocat
                        sudo mv /tmp/websocat /usr/local/bin/
                    }
                '''
            }
        }
        
        stage('Run API Tests') {
            steps {
                sh '''
                    chmod +x api-tests/run_tests.sh
                    
                    ARGS="--base-url ${BASE_URL}"
                    if [ "${RUN_WS_TESTS}" = "false" ]; then
                        ARGS="$ARGS --rest-only"
                    fi
                    
                    ./api-tests/run_tests.sh $ARGS
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'api-tests/reports/**', allowEmptyArchive: true
            
            publishHTML(target: [
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'api-tests/reports',
                reportFiles: 'report_latest.html',
                reportName: 'API Test Report'
            ])
        }
        
        failure {
            emailext(
                subject: "API Tests Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "API tests failed. See ${env.BUILD_URL} for details.",
                to: 'team@example.com'
            )
        }
    }
}
```

### Scripted Pipeline

```groovy
node {
    stage('Checkout') {
        checkout scm
    }
    
    stage('Test') {
        try {
            sh './api-tests/run_tests.sh --base-url https://ema2a.ddns.net'
        } catch (e) {
            currentBuild.result = 'UNSTABLE'
        } finally {
            archiveArtifacts 'api-tests/reports/**'
        }
    }
}
```

---

## GitLab CI

### .gitlab-ci.yml

```yaml
stages:
  - test

api-tests:
  stage: test
  image: ubuntu:22.04
  
  variables:
    BASE_URL: "https://ema2a.ddns.net"
  
  before_script:
    - apt-get update && apt-get install -y curl jq
    - |
      wget -qO /usr/local/bin/websocat \
        https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
      chmod +x /usr/local/bin/websocat
  
  script:
    - chmod +x api-tests/run_tests.sh
    - ./api-tests/run_tests.sh --base-url $BASE_URL
  
  artifacts:
    when: always
    paths:
      - api-tests/reports/
    expire_in: 30 days
  
  rules:
    - if: $CI_PIPELINE_SOURCE == "web"
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - api-tests/**/*
```

---

## Azure DevOps

### azure-pipelines.yml

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - api-tests/**

pool:
  vmImage: 'ubuntu-latest'

parameters:
  - name: baseUrl
    displayName: 'API Base URL'
    type: string
    default: 'https://ema2a.ddns.net'

steps:
  - task: Bash@3
    displayName: 'Install Dependencies'
    inputs:
      targetType: 'inline'
      script: |
        sudo apt-get update
        sudo apt-get install -y jq
        wget -qO /tmp/websocat https://github.com/vi/websocat/releases/latest/download/websocat.x86_64-unknown-linux-musl
        chmod +x /tmp/websocat && sudo mv /tmp/websocat /usr/local/bin/
  
  - task: Bash@3
    displayName: 'Run API Tests'
    inputs:
      targetType: 'inline'
      script: |
        chmod +x api-tests/run_tests.sh
        ./api-tests/run_tests.sh --base-url ${{ parameters.baseUrl }}
  
  - task: PublishBuildArtifacts@1
    displayName: 'Publish Test Report'
    condition: always()
    inputs:
      PathtoPublish: 'api-tests/reports'
      ArtifactName: 'TestReport'
```

---

## Best Practices

### 1. Use Secrets for Credentials

Never hardcode credentials. Use platform-specific secret management:

| Platform | Secret Storage |
|----------|----------------|
| GitHub Actions | Repository Secrets |
| Jenkins | Credentials Plugin |
| GitLab CI | CI/CD Variables (masked) |
| Azure DevOps | Variable Groups |

### 2. Set Appropriate Timeouts

```yaml
# GitHub Actions
timeout-minutes: 15

# GitLab CI
timeout: 15 minutes

# Jenkins (for specific stage)
timeout(time: 15, unit: 'MINUTES') {
    sh './run_tests.sh'
}
```

### 3. Handle Flaky Tests

```yaml
# Retry failed job
api-tests:
  retry: 2  # GitLab CI
```

### 4. Parallel Test Execution

For faster pipelines, run REST and WebSocket tests in parallel:

```yaml
jobs:
  rest-tests:
    runs-on: ubuntu-latest
    steps:
      - run: ./run_tests.sh --base-url $URL --rest-only
  
  ws-tests:
    runs-on: ubuntu-latest
    steps:
      - run: ./run_tests.sh --base-url $URL --ws-only
  
  combine-reports:
    needs: [rest-tests, ws-tests]
    runs-on: ubuntu-latest
    steps:
      # Merge reports here
```

### 5. Schedule Regular Tests

Run tests periodically to catch regressions:

```yaml
# GitHub Actions cron syntax
schedule:
  - cron: '0 */6 * * *'  # Every 6 hours

# GitLab CI
schedules:
  - cron: '0 6 * * *'
    ref: main
```

---

## Notification Integration

### Slack Notification

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "API Tests Failed!",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*API Tests Failed* in `${{ github.repository }}`\nWorkflow: ${{ github.workflow }}\n<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Results>"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Email Notification

```yaml
- name: Send failure email
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 587
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: "API Tests Failed - ${{ github.repository }}"
    to: team@example.com
    body: "API tests failed. Check ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```
