pipeline {
    agent any
    environment{ 
        NETLIFY_SITE_ID ='f044aa26-0297-4549-b127-4eb3a96a7579'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID"
    }
    stages {
        stage('Docker'){
            steps{
                sh 'docker build -t playright_image .'
            }
        }

        stage('Build') {
            agent{
                docker{
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                ls -la
                node --version
                npm --version
                npm ci
                npm run build
                ls -la
                '''
            }
        }
        
        stage('Run Test'){
            parallel{
                stage('Test') {
                    agent{
                        docker{
                            image 'node:18-alpine'
                            reuseNode true
                            }
                        }
                    steps{
                        sh '''
                        echo "Test stage"
                        test -f build/index.html
                        npm test
                        '''
                        }
                     post{
                        always{
                            junit 'jest-results/junit.xml'
                            }
                        }
                }
                stage('E2E') {
                    agent{
                         docker{
                            image 'mcr.microsoft.com/playwright:v1.50.1-jammy'
                            reuseNode true
                            }
                        }
                    steps{
                        sh '''
                        npm install serve
                        node_modules/.bin/serve -s build &
                        sleep 10
                        npx playwright test --reporter=html
                        '''
                        }
                    post{
                        always{
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Local Report', reportTitles: '', useWrapperFileDirectly: true])
                             }
                         }
                }
             }
        }

        stage('Deploy to stage') {
            agent{
                docker{
                image 'playright_image'
                reuseNode true
                    }
                }
            environment{
                CI_ENVIRONMENT_URL="STAGING_URL"
                }
            steps{
                sh '''
                netlify --version
                echo "Deploying to stage ,site id:$NETLIFY_SITE_ID"
                netlify status
                netlify deploy --dir=build --json > deploy-output.json
                CI_ENVIRONMENT_URL=$(node-jq -r '.deploy_url'  deploy-output.json)
                npx playwright test --reporter=html
                '''
                }
            post{
                always{
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Stage E2E Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                }
        }  

        stage('Deploy to production') {
            agent{
                docker{
                image 'playright_image'
                reuseNode true
                    }
                }
            environment{
                CI_ENVIRONMENT_URL='https://rad-melomakarona-6d65d3.netlify.app'
                }
            steps{
                sh '''
                node --version
                netlify --version
                echo "Deploying to production ,site id:$NETLIFY_SITE_ID"
                netlify status
                netlify deploy --dir=build --prod
                npx playwright test --reporter=html
                '''
                }
            post{
                always{
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                }
        }    
    }
}
    

