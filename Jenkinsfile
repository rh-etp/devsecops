/**
This pipeline provides a skeleton to build and deploy apps on Openshift Container Platform

@Author Faisal Masood <fmasood@redhat.com>

*/


/*
Jenkins parameterized values:
namespaceDev 			contains the value of openshift namespace, possible values dev/uat etc
namespaceUat			contains the value of openshift namespace, possible values dev/uat etc
envFolder 				contains the environment folder within the project path (e.g. dev, uat)
*/

/***  Global Variables  ***/
def uniqueApplicationId
def appName
def appNameRaw
def appMajorVersion
def appVersion
def gitCommitId
def noProxyHosts

def LOCATION = "https://github.com/masoodfaisal/todo-spring-be.git"

node('maven') {




    stage('Checkout'){
        // withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'gitCredentials',
        //                   usernameVariable: 'stashUserName', passwordVariable: 'stashPassword']]) {


            sh '''
                git config --global http.sslVerify false
                #git config --global user.name \${stashUserName}
                #git config --global user.email a@example.com
                #LOCATION=https://\${stashUserName}:\${stashPassword}@\${repoLocation}
                git clone -b master --single-branch \$LOCATION .
               '''
        // }



    }


    stage("Populate variables") {

		appVersion = getVersionFromPom("pom.xml")

        // Remove -SNAPSHOT from app version if any
        int indexSnapshot = appVersion.indexOf("-SNAPSHOT")
        if (indexSnapshot > 0) {
        	appMajorVersion = appVersion.substring(0, indexSnapshot)
        }
        else {
        	appMajorVersion = appVersion
        }

        // Take only the major version (e.g. 1.0.0 -> 1)
        if (appMajorVersion.indexOf('.') > 0) {
        	appMajorVersion = appMajorVersion.substring(0, appMajorVersion.indexOf('.'))
        }
        appMajorVersion = appMajorVersion.replaceAll("[^A-Za-z0-9]", "")


        // Keep only alphanumeric characters in app name
        appNameRaw = getArtifactIdFromPom("pom.xml")
		//appNameRaw = readFile('appname.txt').trim()
        appName = appNameRaw.replaceAll("[^A-Za-z0-9]", "")

        println "[appName] ${appName}"
       	println "[appMajorVersion] ${appMajorVersion}"

    	// retrieve GIT_COMMIT ID
    	gitCommitId = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    	
    }

    stage('Build Fat jar'){
        sh """
                #export MAVEN_OPTS=''
                mvn -T5  clean package -DskipTests
            """
    }

    stage('Run OWASP Library scan'){
        sh """
            mvn org.owasp:dependency-check-maven:3.1.0:check -P owasp
           """
    }



    stage('Run Unit Test'){

        sh """
                mvn test
            """

    }


    stage('Run Integration Test'){

        sh """
                mvn failsafe:integration-test failsafe:verify
           """
   
    }

    stage('Run SONAR test'){
        sh """
                mvn sonar:sonar -P sonar
            """
    }

    //TODO - later
    stage('Deploy to JAR Repository e.g. Artifactoiry'){
      /**
        sh """
                mvn deploy
           """
        */
    }
    
    //TODO
    stage('Start local container build'){
        //build container using dockerfile and scan them before pushing them to the registry
        sh """
                echo 'Container is not built from source code, yet. Build it manually using the command below - TODO'
                #make sure that the hard coded jar is there
                docker build -t spring-todo-be:1.0 .
           """
    }
	
    /* ignore this in favour of clair
    stage('Openscap based container scan'){
        
        
    }
    */
    //Faisal Masood prefer this instead of the openscap scan
    stage('Clair based container scan'){
        sh """
            ./clair-scanner_darwin_amd64.dms -c http://localhost:6060 --ip $(hostname) --report container.json  spring-todo-be:1.0 || true
        """
        
        
    }

    //TODO
    stage('OWASP ZAP scan for api'){
        //build container using dockerfile and scan them before pushing them to the registry
        sh """
            #make sure that application is running locally - later this will be docker based e.g.
            #the example app needs mongo also running locally - later this will be docker based
            #https://github.com/zaproxy/zaproxy/wiki/ZAP-Baseline-Scan
            docker run -v $(pwd):/zap/wrk/:rw owasp/zap2docker-stable zap-baseline.py -g baseline-scan.conf  -t http://$(ifconfig en0 | grep "inet " | cut -d " " -f2):8080/api/todolist
        """
    }

    //OR Use Arachni instead of OWASP
    stage('Arachni scan for api'){
        //https://wiki.jenkins.io/display/JENKINS/Arachni+Scanner+plugin
        
    }

    stage('Vegeta based stress testing'){
        sh """
            #make sure vegeata is available - https://github.com/tsenart/vegeta
            echo "curl -H content-type:application/json http://localhost:8080/api/todolist" | ./vegeta attack -duration=60s -rate=200 -keepalive=false | tee results.bin | ./vegeta report
        """
    }

    //normal stuff -  seems redundant as we already built the container. we can just push it
    //keeping it here for completeness purposes
    stage('Start s2i container build'){
        // SAMPLE ONLY
        /*
        sh """
                oc project ${namespaceDev}
                BUILD_STATUS=\$(oc get buildconfig ${appName}${appMajorVersion} -n ${namespaceDev} | awk '{if(NR>1) print \$1}')
                if [[ \${BUILD_STATUS} != ${appName}${appMajorVersion} ]]; then
                    echo "Build does not exist. Creating BuildConfig/IS."
                    oc process -f ./buildconfig-template.yml -n ${namespaceDev} -p APP_NAME=${appName} -p APP_MAJOR_VERSION=${appMajorVersion} -p GIT_COMMIT_ID=${gitCommitId} -p JENKINS_BUILD_NUMBER=${BUILD_NUMBER} -p APP_VERSION=${appVersion} -p IMAGE_TAG=${appVersion} -p REGISTRY_LOCATION=${registryLocation} -p EXTERNAL_NAMESPACE=${externalNamespace} -p PUSH_SECRET=${pushPullSecret} | oc create -n ${namespaceDev} -f -
                else
					oc process -f ./buildconfig-template.yml -n ${namespaceDev} -p APP_NAME=${appName} -p APP_MAJOR_VERSION=${appMajorVersion} -p GIT_COMMIT_ID=${gitCommitId} -p JENKINS_BUILD_NUMBER=${BUILD_NUMBER} -p APP_VERSION=${appVersion} -p IMAGE_TAG=${appVersion} -p REGISTRY_LOCATION=${registryLocation} -p EXTERNAL_NAMESPACE=${externalNamespace} -p PUSH_SECRET=${pushPullSecret} | oc replace -n ${namespaceDev} -f -
                fi
           """

        sh """
                oc project ${namespaceDev}
                oc start-build ${appName}${appMajorVersion} -n ${namespaceDev} --from-file=./target/${appNameRaw}-${appVersion}.jar --follow
           """
        */

    }


    stage('Create image stream tag') {
		// SAMPLE ONLY
        /*
        sh """
				oc project ${namespaceDev}
				oc tag ${registryLocation}/${externalNamespace}/${appName}${appMajorVersion}:${appVersion}  ${appName}${appMajorVersion}:${appVersion}  --source=docker  --scheduled=true --reference-policy=local --insecure
				    			                  
		   """
        */   
    }
    
    stage('Deploy configmaps to DEV namespace'){
        // SAMPLE ONLY
        /*
        sh """
                oc project ${namespaceDev}
                CONFIG_MAP_STATUS=\$(oc get configmap ${appName}${appMajorVersion}  -n ${namespaceDev} | awk '{if(NR>1) print \$1}')
                if [[ \${CONFIG_MAP_STATUS} != ${appName}${appMajorVersion} ]]; then
                    echo "ConfigMap doesnot exists . Creating ConfigMap"
                    oc create configmap ${appName}${appMajorVersion} -n ${namespaceDev} --from-file=configuration/${envFolder}/application.properties
                else
                    oc create configmap ${appName}${appMajorVersion} -n ${namespaceDev} --from-file=configuration/${envFolder}/application.properties --dry-run -o yaml | oc replace configmap  ${appName}${appMajorVersion} -n ${namespaceDev} -f -
                fi

                oc label --overwrite=true configmap ${appName}${appMajorVersion} -n ${namespaceDev} component=${appName} group=app-group project=${appName} provider=s2i version=${appMajorVersion} appname=${appName} appversion=${appVersion} buildnumber=${BUILD_NUMBER} gitcommitid=${gitCommitId}
           """
        */   
    }

    stage('Deploy application to DEV namespace'){

        // SAMPLE ONLY
        /*
        sh """
                oc project ${namespaceDev}
                DEPLOY_STATUS=\$(oc get deploymentconfig ${appName}${appMajorVersion}  -n ${namespaceDev} | awk '{if(NR>1) print \$1}')
                if [[ \${DEPLOY_STATUS} != ${appName}${appMajorVersion} ]]; then
                    echo "Deployment doesnot exists already. Creating DeploymentConfig/Svc/Route"
                    oc process -f ${workspace}/ocp-objects/deploy-template.yaml -n ${namespaceDev} -p APP_NAME=${appName} -p APP_MAJOR_VERSION=${appMajorVersion} -p APP_VERSION=${appVersion} -p GIT_COMMIT_ID=${gitCommitId} -p JENKINS_BUILD_NUMBER=${BUILD_NUMBER} -p MEM_LIMIT=900Mi -p MEM_REQUEST=900Mi -p CPU_LIMIT=900m -p CPU_REQUEST=250m -p NAMESPACE=${namespaceDev} -p NUMBER_OF_REPLICAS=1 -p IMAGE_TAG=${appVersion}  -p REGISTRY_LOCATION=${registryLocation} -p EXTERNAL_NAMESPACE=${externalNamespace} -p PULL_SECRET=${pushPullSecret} -p NON_PROXY_HOST=${noProxyHosts} | oc create -n ${namespaceDev} -f -
                    sleep 5
                else
                	oc process -f ${workspace}/ocp-objects/deploy-template.yaml -n ${namespaceDev} -p APP_NAME=${appName} -p APP_MAJOR_VERSION=${appMajorVersion} -p APP_VERSION=${appVersion} -p GIT_COMMIT_ID=${gitCommitId} -p JENKINS_BUILD_NUMBER=${BUILD_NUMBER} -p MEM_LIMIT=900Mi -p MEM_REQUEST=900Mi -p CPU_LIMIT=900m -p CPU_REQUEST=250m -p NAMESPACE=${namespaceDev} -p NUMBER_OF_REPLICAS=1 -p IMAGE_TAG=${appVersion}  -p REGISTRY_LOCATION=${registryLocation} -p EXTERNAL_NAMESPACE=${externalNamespace} -p PULL_SECRET=${pushPullSecret} -p NON_PROXY_HOST=${noProxyHosts} | oc apply -n ${namespaceDev} --force=true -f -
                fi

    			#Autoscale
    			HPA_STATUS=\$(oc get hpa ${appName}${appMajorVersion}  -n ${namespaceDev} | awk '{if(NR>1) print \$1}')
                if [[ \${HPA_STATUS} != ${appName}${appMajorVersion} ]]; then
                	echo "Horizontal pod autoscaler does not exist yet. Creating one..."
                	oc autoscale dc/${appName}${appMajorVersion} -n ${namespaceDev} --min 1 --max 5 --cpu-percent=60
                else
                	echo "Horizontal pod autoscaler already exists. Updating labels..."
           		fi
           		oc label --overwrite=true hpa ${appName}${appMajorVersion} -n ${namespaceDev} component=${appName} group=app-group project=${appName} provider=s2i version=${appMajorVersion} appname=${appName} appversion=${appVersion} buildnumber=${BUILD_NUMBER} gitcommitid=${gitCommitId}

                #deploy the docker image
           		oc rollout status dc/${appName}${appMajorVersion} -n ${namespaceDev}
           """
           */

    }

    stage('Expose deployed Service as Route'){
       // SAMPLE ONLY
        /*
        sh """
                oc project ${namespaceDev}
                ROUTE_STATUS=\$(oc get route ${appName}${appMajorVersion}  -n ${namespaceDev} | awk '{if(NR>1) print \$1}')
                if [[ \${ROUTE_STATUS} != ${appName}${appMajorVersion} ]]; then
                    echo "Route not found. First deploy"
                    #oc expose svc ${appName}${appMajorVersion} --name=${appName}${appMajorVersion} --path=${apiURL}/v${appMajorVersion} -n ${namespaceDev}
                    oc create route edge ${appName}${appMajorVersion} --service=${appName}${appMajorVersion}  --port=8080 --path=${apiURL}/v${appMajorVersion} -n ${namespaceDev}
                fi
                oc label --overwrite=true route ${appName}${appMajorVersion} -n ${namespaceDev} component=${appName} group=app-group project=${appName} provider=s2i version=${appMajorVersion} appname=${appName} appversion=${appVersion} buildnumber=${BUILD_NUMBER} gitcommitid=${gitCommitId}
           """
        */   
    }


    //TODO - later - think about the release to UAT process

	/*
    stage('Move to UAT Environment'){

        timeout(time: 1, unit: 'DAYS'){
            input message: 'Ready for application promotions?'
        }

        //associate the right role
        sh """
            oc policy add-role-to-group system:image-puller system:serviceaccounts:${namespaceUat} -n ${namespaceDev}

           """

    }*/



}


// Convenience Functions to read variables from the pom.xml
//https://jenkins.io/doc/pipeline/steps/pipeline-utility-steps/#readmavenpom-read-a-maven-project-file
def getVersionFromPom(pom) {
    def matcher = readFile(pom) =~ '<version>(.+)</version>'
    matcher ? matcher[0][1] : null
}

def getGroupIdFromPom(pom) {
    def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
    matcher ? matcher[0][1] : null
}

def getArtifactIdFromPom(pom) {
    def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
    matcher ? matcher[0][1] : null
}


def getReleaseFromMetaData(pom) {
    def matcher = readFile(pom) =~ '<release>(.+)</release>'
    matcher ? matcher[0][1] : null
}

