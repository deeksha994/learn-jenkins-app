pipeline {
    agent any
    environment{
        NETLIFY_SITE_ID ='f044aa26-0297-4549-b127-4eb3a96a7579'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }
    stages {
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
                            image 'mcr.microsoft.com/playwright:v1.50.1-noble'
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
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                 npm install netlify-cli node-jq
                node_modules/.bin/netlify --version
                echo "Deploying to stage ,site id:$NETLIFY_SITE_ID"
                node_modules/.bin/netlify status
                node_modules/.bin/netlify deploy --dir=build --json > deploy-output.json
                node_modules/.bin/node-jq -r '.deploy_url'  deploy-output.json
                '''
                script{
                env.STAGING_URL=sh(script:"node_modules/.bin/node-jq -r '.deploy_url'  deploy-output.json",returnStdout:true)
            }
            }
            
        }
        stage('Stage E2E') {
            agent{
                docker{
                image 'mcr.microsoft.com/playwright:v1.50.1-noble'
                reuseNode true
                    }
                }
            environment{
                CI_ENVIRONMENT_URL="${env.STAGING_URL}"
                }
            steps{
                sh '''
                npx playwright test --reporter=html
                echo "node modules in folder"
                '''
                }
            post{
                always{
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Stage E2E Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                }
        }    
        stage('Approval'){
            steps{
                timeout(time: 1, unit: 'MINUTES') {
                     input message: 'Do you wish to deploy to production ?', ok: 'Yes I am sure I want to deploy.'
                }
                
            }
        }
        stage('Deploy to production') {
            agent{
                docker{
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                npm install netlify-cli 
                node_modules/.bin/netlify --version
                echo "Deploying to production ,site id:$NETLIFY_SITE_ID"
                node_modules/.bin/netlify status
                node_modules/.bin/netlify deploy --dir=build --prod
                '''
            }
        }
        stage('Prod E2E') {
            agent{
                docker{
                image 'mcr.microsoft.com/playwright:v1.50.1-noble'
                reuseNode true
                    }
                }
            environment{
                CI_ENVIRONMENT_URL='https://rad-melomakarona-6d65d3.netlify.app'
                }
            steps{
                sh '''
                npx playwright test --reporter=html
                echo "node modules in folder"
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
    

