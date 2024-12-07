### Task #4. Sonatype Nexus

Install Nexus and set up docker group repository. Nexus installation must be done
using a script, ensuring idempotency, and should be run as systemd service.
Setup integration with Gitlab CI/CD pipeline ( minimum – stage that build docker
image and push into nexus + deploy stage where your builded image will be pulled
from nexus )


https://gitlab.com/mastering-ci-cd/nexustask4

https://gitlab.com/mastering-ci-cd/nexustask4

https://gitlab.com/mastering-ci-cd/nexustask4

### running on
http://localhost:8081/#admin/repository/repositories

Commands
### docker login
```bash
docker login http://localhost:5000 -u admin -p pass
```
expected output
```bash
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/aral/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credential-stores

Login Succeeded
```

### docker creationg image and push image
```bash
docker build -t localhost:5000/my-nginx .
docker push localhost:5000/my-nginx:latest
```

expected output
```bash
Using default tag: latest
The push refers to repository [localhost:5000/my-nginx]
d32d820bcf1c: Pushed 
c28e0f7d0cc5: Pushed 
8aa4787aa17a: Pushed 
b060cc3bd13c: Pushed 
2c3a053d7b67: Pushed 
fc00b055de35: Pushed 
c0f1022b22a9: Pushed 
latest: digest: sha256:54117fea772255e92722d9709c2f2f21a836e3afc6acd7a867d3b191e95b6915 size: 1778
```

### List of images
curl -u admin:pass123123 "http://localhost:8081/service/rest/v1/search?repository=my_repo"

Expected output
```bash
{
  "items" : [ {
    "id" : "bXlfcmVwbzo0ZjFiYmNkZA",
    "repository" : "my_repo",
    "format" : "docker",
    "group" : "",
    "name" : "my-nginx",
    "version" : "latest",
    "assets" : [ {
      "downloadUrl" : "http://localhost:8081/repository/my_repo/v2/my-nginx/manifests/latest",
      "path" : "/v2/my-nginx/manifests/latest",
      "id" : "bXlfcmVwbzoxNzE1NjBhMg",
      "repository" : "my_repo",
      "format" : "docker",
      "checksum" : {
        "sha1" : "0c3136e73264f2a4222db99b5e66a964a976eda1",
        "sha256" : "54117fea772255e92722d9709c2f2f21a836e3afc6acd7a867d3b191e95b6915"
      },
      "contentType" : "application/vnd.docker.distribution.manifest.v2+json",
      "lastModified" : "2024-12-07T05:24:39.571+00:00",
      "lastDownloaded" : null,
      "uploader" : "admin",
      "uploaderIp" : "127.0.0.1",
      "fileSize" : 1778,
      "blobCreated" : null,
      "blobStoreName" : null
    } ]
  } ],
  "continuationToken" : null
```

### pull image
```bash
docker pull localhost:5000/my-nginx:latestt
```
expected output
```bash
latest: Pulling from my-nginx
Digest: sha256:54117fea772255e92722d9709c2f2f21a836e3afc6acd7a867d3b191e95b6915
Status: Image is up to date for localhost:5000/my-nginx:latest
localhost:5000/my-nginx:latest
```


### status nexus systemd
```bash
sudo systemctl status nexus
```
Expected output
```bash
 nexus.service - nexus service
     Loaded: loaded (/etc/systemd/system/nexus.service; enabled; vendor preset:>
     Active: active (running) since Sat 2024-12-07 09:34:09 +05; 2h 9min ago
   Main PID: 22298 (java)
      Tasks: 203 (limit: 18199)
     Memory: 3.2G
        CPU: 3min 5.729s
     CGroup: /system.slice/nexus.service
             └─22298 /usr/lib/jvm/java-17-openjdk-amd64/bin/java -server -Dinst>

дек 07 09:34:08 aral-ROG-Strix-G513RM-G513RM systemd[1]: Starting nexus service>
дек 07 09:34:09 aral-ROG-Strix-G513RM-G513RM nexus[21986]: Starting nexus
дек 07 09:34:09 aral-ROG-Strix-G513RM-G513RM systemd[1]: Started nexus service.
lines 1-13/13 (END)
```


### password admin
```bash
sudo cat /opt/sonatype-work/nexus3/admin.password
```
expected output
```bash
023ffe0b-5e4c-4f1f-866b-82609a9a17f9
```

### creating my repo docker
```bash
curl -v -u admin:pass123123 -X POST "http://localhost:8081/service/rest/v1/repositories/docker/hosted" -H "Content-Type: application/json" -d '{
  "name": "my_repo",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow"
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "httpPort": 5000
  }
}'
```
Expected output
```bash
Note: Unnecessary use of -X or --request, POST is already inferred.
*   Trying 127.0.0.1:8081...
* Connected to localhost (127.0.0.1) port 8081 (#0)
* Server auth using Basic with user 'admin'
> POST /service/rest/v1/repositories/docker/hosted HTTP/1.1
> Host: localhost:8081
> Authorization: Basic YWRtaW46cGFzczEyMzEyMw==
> User-Agent: curl/7.81.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 253
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 201 Created
< Date: Sat, 07 Dec 2024 04:45:44 GMT
< Server: Nexus/3.75.1-01 (OSS)
< X-Content-Type-Options: nosniff
< Content-Length: 0
< 
* Connection #0 to host localhost left intact
```

### docker group
```bash
curl -v -u admin:pass123123 -X POST "http://localhost:8081/service/rest/v1/repositories/docker/group" \ 
-H "Content-Type: application/json" \
-d '{
  "name": "my_group",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "group": {
    "memberNames": [
      "my_repo"
    ]
  },
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": true,
    "subdomain": "docker-a"
  }
}'
```
Expected output
```bash
Note: Unnecessary use of -X or --request, POST is already inferred.
*   Trying 127.0.0.1:8081...
* Connected to localhost (127.0.0.1) port 8081 (#0)
* Server auth using Basic with user 'admin'
> POST /service/rest/v1/repositories/docker/group HTTP/1.1
> Host: localhost:8081
> Authorization: Basic YWRtaW46cGFzczEyMzEyMw==
> User-Agent: curl/7.81.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 294
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 201 Created
< Date: Sat, 07 Dec 2024 04:49:32 GMT
< Server: Nexus/3.75.1-01 (OSS)
< X-Content-Type-Options: nosniff
< Content-Length: 0
< 
* Connection #0 to host localhost left intact
```

