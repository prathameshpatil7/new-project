# Jenkins CI/CD Pipeline for Java Maven Application with Docker, SonarQube, and GitOps
<img width="1994" height="1012" alt="image" src="https://github.com/user-attachments/assets/934e2fdb-3705-4f74-9290-fc0cdc668627" />

## 📌 Overview

This project demonstrates a **complete CI/CD pipeline** for a **Java Maven application** using **Jenkins Declarative Pipeline**.
The pipeline performs:

* **Source Code Management** with GitHub
* **Build and Test** with Maven
* **Code Quality and Security** with SonarQube and OWASP Dependency Check
* **Docker Image Build and Test**
* **Vulnerability Scanning** with Trivy
* **Push Docker Image** to DockerHub
* **Update GitOps Repository** for deployment in Kubernetes

---

## ✅ **Pipeline Workflow**

### 1. **Trigger**

* Pipeline is triggered on **GitHub Push** via `githubPush()` trigger.
* Uses Jenkins agent `any`.

### 2. **Tools and Environment**

* **JDK 21** and **Maven 3** are configured in Jenkins.
* Environment variables:

  * `DOCKER_IMAGE_NAME`: Name of the Docker image.
  * `DOCKERHUB_CREDS`: Jenkins credentials for DockerHub.
  * `GITOPS_REPO_URL`: GitOps repo URL.
  * `GITOPS_REPO_CREDS`: Jenkins credentials for GitOps repo.

---

## ✅ **Pipeline Stages**

### **Stage 1: Git Checkout**

* Checks out the source code from the specified GitHub branch.

### **Stage 2: Maven Build**

* Runs:

  ```bash
  mvn clean package
  ```
* Builds the JAR file for the application.

### **Stage 3: SonarQube Analysis & Quality Gate**

* Runs static code analysis using **SonarQube**:

  ```bash
  mvn clean verify sonar:sonar
  ```
* Waits for the **Quality Gate** result.

### **Stage 4: OWASP Dependency Check**

* Runs security scanning for dependencies using OWASP plugin:

  ```bash
  dependencyCheck --scan target
  ```
* Publishes a report in Jenkins.

### **Stage 5: Docker Build**

* Builds the Docker image for the application:

  ```bash
  docker build -t patilprathamesh/petclinic:${BUILD_NUMBER} .
  ```

### **Stage 6: Run Docker Container for Testing**

* Runs the built Docker image in a container:

  ```bash
  docker run -d --name petclinic-test -p 8080:8080 patilprathamesh/petclinic:${BUILD_NUMBER}
  ```
* Waits for the app to start, prints logs, then removes the container after testing.

### **Stage 7: Vulnerability Scan with Trivy**

* Scans the Docker image for **HIGH** and **CRITICAL** vulnerabilities:

  ```bash
  trivy image --exit-code 1 --severity HIGH,CRITICAL patilprathamesh/petclinic:${BUILD_NUMBER}
  ```

### **Stage 8: Push to DockerHub**

* Pushes both `BUILD_NUMBER` and `latest` tags to DockerHub:

  ```bash
  docker push patilprathamesh/petclinic:${BUILD_NUMBER}
  docker push patilprathamesh/petclinic:latest
  ```

### **Stage 9: Update GitOps Repository**

* Updates the **Kubernetes deployment YAML** in GitOps repo with the new image tag:

  ```bash
  sed -i 's|image: .*|image: patilprathamesh/petclinic:${BUILD_NUMBER}|g' deployment.yaml
  git commit -am "Update image to version ${BUILD_NUMBER}"
  git push origin main
  ```

### **Stage 10: Pipeline Complete**

* Marks the successful completion of the pipeline.

---

## ✅ **Pipeline Diagram**

<img width="1994" height="1012" alt="image" src="https://github.com/user-attachments/assets/ca9aa6c9-4b75-445c-8beb-b37e584471e4" />

---

## ✅ **Prerequisites**

* Jenkins installed with:

  * **Pipeline Plugin**
  * **SonarQube Plugin**
  * **OWASP Dependency-Check Plugin**
  * **Docker Pipeline Plugin**
* **SonarQube Server** configured in Jenkins.
* **Docker installed** on Jenkins agent.
* **Trivy installed** on Jenkins agent.
* **GitHub Webhook** configured for Jenkins.
* **DockerHub credentials** stored in Jenkins as `dockerhub-creds`.
* **GitOps repo credentials** stored in Jenkins as `gitops-repo-creds`.

---

## ✅ **Run Locally (For Testing)**

To run the application locally using Docker after pipeline build:

```bash
docker pull patilprathamesh/petclinic:latest
docker run -d -p 8080:8080 patilprathamesh/petclinic:latest
```

Access the application at:

```
http://localhost:8080
```

---

## ✅ **Security Scans**

* **SonarQube**: For code quality and bugs.
* **OWASP Dependency Check**: For dependency vulnerabilities.
* **Trivy**: For container image vulnerabilities.

---

## ✅ **GitOps Deployment**

* After pipeline completion, the GitOps repo updates automatically.
* ArgoCD or Flux can sync the changes to Kubernetes cluster.

---

## ✅ **Future Enhancements**

* Add **integration tests** after Docker container runs.
* Implement **Kubernetes deployment stage**.
* Enable **Slack/MS Teams notifications** for pipeline status.

---

🔥 This pipeline ensures **secure, automated, and continuous delivery** of your Java application using modern DevOps practices.
---

SCREENSHOTS:
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-51-58" src="https://github.com/user-attachments/assets/9499cfdb-98fd-4d8a-950a-c7b15ea8fc00" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-51-50" src="https://github.com/user-attachments/assets/57b40985-7dc0-47f5-b258-9119bb62c559" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-45-54" src="https://github.com/user-attachments/assets/5c52f96b-93cb-40f6-8d0e-8ee97a4ea1c1" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-45-04" src="https://github.com/user-attachments/assets/0a484771-3806-48a6-8cde-f3b54429be54" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-43-50" src="https://github.com/user-attachments/assets/af8273f0-1323-4b82-ba68-70714b60ee15" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 19-43-57" src="https://github.com/user-attachments/assets/81d88873-b273-44a0-aff7-457825902c48" />
<img width="1920" height="1110" alt="Screenshot from 2025-08-23 18-44-12" src="https://github.com/user-attachments/assets/019856ab-d3d3-4d7a-9e2b-f57971447ea8" />






