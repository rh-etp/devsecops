## Work in Progress, do NOT use

http://bit.ly/devsecops-hackathon

_______________________________

This section describes the steps to run a very basic devsecops pipeline. The file is available in this repo under the name of Jenkinsfile. The example spring application is [forked](https://github.com/masoodfaisal/todo-spring-be)


# Pre-requistie software
- Please install [docker](https://www.docker.com/get-started)
- Locally run [Jenkins](https://jenkins.io/doc/book/installing/#war-file)
- [Clair scanner](https://github.com/arminc/clair-scanner/releases) is available
- [Vegeta](https://github.com/tsenart/vegeta) is avialable

## Run supporting software
```bash
#run clair
docker run -p 5432:5432 -d --name db arminc/clair-db:latest
docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5

#run ZAP server
docker run -v $(pwd):/zap/wrk/:rw \
        owasp/zap2docker-weekly zap-baseline.py \
        -g baseline-scan.conf \
        -t http://$(ifconfig en0 | grep "inet " | cut -d " " -f2):8080
            -r baseline-scan-report.html

#sonarcube
docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube

```

##Jenkinsfile
The file present perform following stages
- compile
- unit test
- owasp dependency scan
- sonar cube
- integration test
- ZAP based scan
- Clair scan

## References
A good flow for image scanning and signing is available ar [Red Hat Community of Practice Repo](https://github.com/redhat-cop/openshift-image-signing-scanning)