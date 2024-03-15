#!/bin/bash

echo "Iniciando o script..."

# -----------------------------
#para executar esse script:

# no windows utilize no bash vscode o comando: bash ./setup_jenkins_with_docker.sh
# no linux utilize o terminal o comando: chmod +x setup_jenkins_with_docker.sh (para dar as permissões) e ./setup_jenkins_with_docker.sh (para executar o script)

# -----------------------------

echo "Criando o arquivo Dockerfile..."
# Criação do arquivo Dockerfile
cat <<EOF > Dockerfile
FROM jenkins/jenkins:lts-jdk17

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER root
RUN apt-get update \
    && apt-get install -y docker.io

RUN apt-get update && apt-get install -y groovy

USER jenkins
EOF

echo "Arquivo Dockerfile criado."

echo "Criando o arquivo docker-compose.yml..."

# Criação do arquivo docker-compose.yml
cat <<EOF > docker-compose.yml
version: "3.3"

services:
    jenkins:
        build:
            context: .
            dockerfile: Dockerfile
        container_name: jenkins
        ports:
            - "8080:8080"
            - "50000:50000"
        volumes:
            - ./jenkins_home:/var/jenkins_home
            - /var/run/docker.sock:/var/run/docker.sock
            - ./001-create_admin.groovy:/usr/share/jenkins/ref/init.groovy.d/001-create_admin.groovy
            - ./002-approve_script.groovy:/usr/share/jenkins/ref/init.groovy.d/002-approve_script.groovy
            - ./003-create_pipeline.groovy:/usr/share/jenkins/ref/init.groovy.d/003-create_pipeline.groovy
        environment:
            - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
        restart: unless-stopped

volumes:
    jenkins_home: {}
EOF
echo "Arquivo docker-compose.yml criado."

echo "Criando os arquivos de script Groovy..."

# Criação dos arquivos de script Groovy
cat <<EOF > 001-create_admin.groovy
import jenkins.model.*
import hudson.security.*

def jenkins = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'password')

jenkins.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(strategy)

jenkins.save()
EOF
echo "Arquivo 001-create_admin.groovy criado."


# Script 2 - 002-approve_script.groovy
cat <<EOF > 002-approve_script.groovy
import java.lang.reflect.*
import jenkins.model.Jenkins;
import jenkins.model.*;
import org.jenkinsci.plugins.scriptsecurity.scripts.*;
import org.jenkinsci.plugins.scriptsecurity.sandbox.whitelists.*;

scriptApproval = ScriptApproval.get()
alreadyApproved = new HashSet<>(Arrays.asList(scriptApproval.getApprovedSignatures()))


approveSignature('method groovy.json.JsonBuilder call java.util.List')
approveSignature('method groovy.json.JsonSlurper parseText java.lang.String')
approveSignature('method groovy.json.JsonSlurperClassic parseText')
approveSignature('method groovy.lang.Binding getVariables')
approveSignature('method groovy.lang.Binding getVariable java.lang.String')
approveSignature('method groovy.lang.Binding hasVariable java.lang.String')
approveSignature('method groovy.lang.Closure getMaximumNumberOfParameters')
approveSignature('method groovy.lang.GString plus java.lang.String')
approveSignature('method groovy.lang.GroovyObject invokeMethod java.lang.String java.lang.Object')
approveSignature('method hudson.model.Actionable getAction java.lang.Class')
approveSignature('method hudson.model.Actionable getActions')
approveSignature('method hudson.model.Cause$UpstreamCause getUpstreamProject')
approveSignature('method hudson.model.Cause$UserIdCause getUserId')
approveSignature('method hudson.model.ItemGroup getItem java.lang.String')
approveSignature('method hudson.model.Item getUrl')
approveSignature('method hudson.model.Job getBuildByNumber int')
approveSignature('method hudson.model.Job getLastBuild')
approveSignature('method hudson.model.Job getLastSuccessfulBuild')
approveSignature('method hudson.model.Job isBuilding')
approveSignature('method hudson.model.Run getCauses')
approveSignature('method hudson.model.Run getEnvironment hudson.model.TaskListener')
approveSignature('method hudson.model.Run getParent')
approveSignature('method hudson.model.Run getNumber')
approveSignature('method hudson.model.Run getResult')
approveSignature('method hudson.model.Run getUrl')
approveSignature('method hudson.model.Run getLogFile')
approveSignature('method java.util.Map containsKey java.lang.Object')
approveSignature('method java.util.Map entrySet')
approveSignature('method java.util.Map get java.lang.Object')
approveSignature('method java.util.Map keySet')
approveSignature('method java.util.Map putAll java.util.Map')
approveSignature('method java.util.Map remove java.lang.Object')
approveSignature('method java.util.Map size')
approveSignature('method java.util.Map values')
approveSignature('method javaposse.jobdsl.dsl.DslScriptLoader runScript java.lang.String')
approveSignature('method javaposse.jobdsl.dsl.jobs.PipelineJob definition')
approveSignature('method javaposse.jobdsl.dsl.jobs.PipelineJob cps')
approveSignature('method javaposse.jobdsl.dsl.jobs.PipelineJob script')
approveSignature('method javaposse.jobdsl.dsl.jobs.PipelineJob pipelineJob java.lang.String')
approveSignature('method javaposse.jobdsl.plugin.JenkinsJobManagement JenkinsJobManagement java.io.PrintStream java.util.Map java.io.File')
approveSignature('method javaposse.jobdsl.plugin.JenkinsJobManagement new DslScriptLoader')

scriptApproval.save()

void approveSignature(String signature) {
    if (!alreadyApproved.contains(signature)) {
       scriptApproval.approveSignature(signature)
    }
}
EOF

echo "Arquivo 002-approve_script.groovy criado."


# Script 3 - 003-create_pipeline.groovy
cat <<EOF > 003-create_pipeline.groovy
import javaposse.jobdsl.dsl.DslScriptLoader
import javaposse.jobdsl.plugin.JenkinsJobManagement

def config = new JenkinsJobManagement(System.out, [:], new File('.'))
new DslScriptLoader(config).runScript("""
pipelineJob('helloworld') {
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    stages {
                        stage('Hello') {
                            steps {
                                echo 'Hello World'
                            }
                        }
                    }
                }
            ''')
        }
    }
}
""")
EOF

echo "Arquivo 003-create_pipeline.groovy criado."

echo "Criando o arquivo plugins.txt..."

# Criação do arquivo plugins.txt
cat <<EOF > plugins.txt
job-dsl:latest
script-security:latest
workflow-cps:latest
workflow-job:latest
workflow-aggregator:latest
docker-workflow:latest
pipeline-utility-steps:latest
pipeline-stage-view:latest
blueocean:latest
json-path-api:2.8.0-5.v07cb_a_1ca_738c
EOF

echo "Arquivo plugins.txt criado."

echo "Construindo e inicializando o Jenkins..."

# Construção e inicialização do Jenkins
docker-compose up -d

echo "Jenkins construído e inicializado."