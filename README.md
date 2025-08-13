

<img width="1463" height="548" alt="diagram-export-8-11-2025-11_32_00-PM" src="https://github.com/user-attachments/assets/926d6047-b0cb-49f4-a5a3-bda6de52bd64" />

<img width="1920" height="1200" alt="Screenshot from 2025-08-10 11-51-37" src="https://github.com/user-attachments/assets/01b2c6e2-f510-42ea-8c04-b208bd032566" />


## **Phase 1: Install Jenkins in system**
#### Install JAVA 21
```
sudo apt update
sudo apt install fontconfig openjdk-21-jre
java -version
openjdk version "21.0.3" 2024-04-16
OpenJDK Runtime Environment (build 21.0.3+11-Debian-2)
OpenJDK 64-Bit Server VM (build 21.0.3+11-Debian-2, mixed mode, sharing)
```
#### Install Jenkins
```
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install 
```
#### Start Jenkins
```
sudo systemctl enable jenkins
sudo systemctl start jenkins
```
#### To change the default port of jenkins, run `systemctl edit jenkins` and add the following:
```
[Service]
Environment="JENKINS_PORT=8081"
```
Then, open the Jenkins configuration file using a text editor like `nano` `sudo nano /etc/default/jenkins` 

Inside this file, find the line that says `HTTP_PORT=8080`  and change it to `HTTP_PORT=8082` .

#### Restart the Jenkins service to apply the new port:
```
sudo systemctl restart jenkins
```


## Phase 2: Setup Jenkins in UI
#### Install Plugins:
- Eclipse Temurin installer 
- OWASP Dependency-Check 
- Docker 
- SonarQube Scanner 
#### Configure Global Tools
Configure JDK --> jdk21

Configure MAVEN --> maven3 (**3.6.0)**





## Phase 3: Installing Apache Tomcat
## **1. Install Tomcat**
```bash
cd /opt/
sudo wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65.tar.gz
sudo tar -xvf apache-tomcat-9.0.65.tar.gz
```
---

## **2. Make scripts executable**
```bash
sudo chmod +x /opt/apache-tomcat-9.0.65/bin/*.sh
```
---

## **3. Give Jenkins full ownership**
```bash
sudo chown -R jenkins:jenkins /opt/apache-tomcat-9.0.65
```
---

## **4. Create symbolic links (manual control)**
```bash
sudo ln -s /opt/apache-tomcat-9.0.65/bin/startup.sh /usr/bin/startTomcat
sudo ln -s /opt/apache-tomcat-9.0.65/bin/shutdown.sh /usr/bin/stopTomcat
```
---

## **5. Create systemd service file**
```bash
sudo nano /etc/systemd/system/tomcat.service
```
Paste:

```ini
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=jenkins
Group=jenkins

Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
Environment="CATALINA_PID=/opt/apache-tomcat-9.0.65/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/apache-tomcat-9.0.65"
Environment="CATALINA_BASE=/opt/apache-tomcat-9.0.65"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/opt/apache-tomcat-9.0.65/bin/startup.sh
ExecStop=/opt/apache-tomcat-9.0.65/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
```
---

## **6. Reload and enable Tomcat**
```bash
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
sudo systemctl status tomcat
```
---

## **7. Allow passwordless sudo for Jenkins**
Edit sudoers:

```bash
sudo visudo
```
Add:

```
jenkins ALL=NOPASSWD: /bin/cp, /opt/apache-tomcat-9.0.65/bin/startup.sh, /opt/apache-tomcat-9.0.65/bin/shutdown.sh, /opt/apache-tomcat-9.0.65/webapps/petclinic.war, /bin/systemctl restart tomcat
```
---

## **8. Allow remote manager & host-manager access**
Edit:

```bash
sudo nano /opt/apache-tomcat-9.0.65/webapps/manager/META-INF/context.xml
sudo nano /opt/apache-tomcat-9.0.65/webapps/host-manager/META-INF/context.xml
```
Comment out the `<Valve>` block:

```xml
<!--
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
       allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->
```
---

## **9. Open port 8080 in AWS EC2**
In **Security Groups** → **Inbound Rules**:

- Type: Custom TCP Rule
- Port: 8080
- Source: 0.0.0.0/0 (or your IP)
---

## **10. Add Tomcat admin user**
```bash
sudo nano /opt/apache-tomcat-9.0.65/conf/tomcat-users.xml
```
Add:

```xml
<role rolename="manager-gui"/>
<role rolename="admin-gui"/>
<user username="admin" password="StrongPasswordHere" roles="manager-gui,admin-gui"/>
```
---

## **11. Jenkins pipeline usage**
- **Deploy WAR**:
```bash
sudo cp target/petclinic.war /opt/apache-tomcat-9.0.65/webapps/
```
- **Restart Tomcat**:
```bash
sudo systemctl restart tomcat
```
Both will work without password prompts because of sudoers settings.

## **12. Manual control**
```bash
startTomcat     # Manual start
stopTomcat      # Manual stop
sudo systemctl start tomcat
sudo systemctl stop tomcat
sudo systemctl restart tomcat
```


---

# JENKINS PIPELINE


<img width="1463" height="548" alt="diagram-export-8-11-2025-11_32_00-PM" src="https://github.com/user-attachments/assets/3d284cbb-e46a-4b40-abbb-fcb8fca49c6b" />


```
pipeline {
    agent any
    triggers {
        githubPush()
    }
    tools {
        jdk 'jdk21'
        maven 'maven3'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/prathameshpatil7/new-project.git'
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('SonarQube Analysis & Quality Gate') {
            steps {
                withSonarQubeEnv('MySonarQube') {
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

        stage('Deploy to Tomcat') {
            steps {
                sh 'cp target/petclinic.war /opt/apache-tomcat-9.0.65/webapps/petclinic.war'
                sh 'startTomcat'
            }
        }
    }
}
```


