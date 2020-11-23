# 어플리케이션 빌드 및 도커 이미지 빌드
```
$ ./devops.sh
```

# kubernetes 배포 명령어
```
$ kubectl apply -k ./
```

# 참고
### 정상 동작 여부를 반환하는 api를 구현하며, 10초에 한번 체크하도록 한다. 3번 연속 체크에 실패하면 어플리케이션은 restart 된다.
* spring-petclinic-resource.yaml `livenessProbe` 설정
```
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
```

### 종료 시 30초 이내에 프로세스가 종료되지 않으면 SIGKILL로 강제 종료 시킨다.
* spring-petclinic-resource.yaml `terminationGracePeriodSeconds` 설정
```
      terminationGracePeriodSeconds: 30
```

### 배포 시와 scale in/out 시 유실되는 트래픽이 없어야 한다.
* spring-petclinic-resource.yaml `readinessProbe` 설정
```
        readinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```
* spring-petclinic-resource.yaml `rollingUpdate` 설정
```
  strategy:
    rollingUpdate:
      maxSurge: 50%
      maxUnavailable: 50%
    type: RollingUpdate
```

###  어플리케이션 프로세스는 root 계정이 아닌 uid:1000으로 실행한다.
* dockerfile 설정
```
RUN useradd -u 1000 appuser
USER appuser
COPY --chown=appuser:appuser ./spring-petclinic/target ./target
```
* 어플리케이션 프로세스 uid 확인
```
$ kubectl exec -it spring-petclinic-7558db4f5f-w5hwq -- bash
appuser@spring-petclinic-7558db4f5f-w5hwq:/$ ps -ef
UID         PID   PPID  C STIME TTY          TIME CMD
appuser       1      0  0 14:17 ?        00:00:00 /bin/sh -c java -Dspring.profiles.active=mysql -jar target/*.jar
appuser       6      1  6 14:17 ?        00:00:32 java -Dspring.profiles.active=mysql -jar target/spring-petclinic-2.3.0.BUILD
appuser      53      0  0 14:25 pts/0    00:00:00 bash
appuser      59     53  0 14:25 pts/0    00:00:00 ps -ef
```

### DB도 kubernetes에서 실행하며 재 실행 시에도 변경된 데이터는 유실되지 않도록 설정한다.
* mysql-resource.yaml volume 설정
```
        volumeMounts:
        - name: mysql-volume
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-volume
        hostPath:
          path: /opt/mysql
          type: DirectoryOrCreate
```

### 어플리케이션과 DB는 cluster domain을 이용하여 통신한다.
* kustomication.yaml coreDNS를 통한 서비스 디스커버리
```
  - spring-datasource-url=jdbc:mysql://mysql-petclinic/petclinic?autoReconnect=true&useSSL=false
```

### nginx-ingress-controller를 통해 어플리케이션에 접속이 가능하다
* spring-petclinic-resource.yaml Ingress rule 생성
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spring-petclinic-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: healinyoon.com
    http:
      paths:
      - path: /
        backend:
          serviceName: spring-petclinic
          servicePort: 8080
```

* ingress 확인
```
$ kubectl get ingress
Warning: extensions/v1beta1 Ingress is deprecated in v1.14+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
NAME                       CLASS    HOSTS            ADDRESS     PORTS   AGE
http-go-ingress            <none>   gasbugs.com      10.1.11.9   80      5d7h
spring-petclinic-ingress   <none>   healinyoon.com   10.1.11.9   80      101s
```

* svc 확인
```
$ kubectl get svc
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP          76d
mysql-petclinic    ClusterIP   None             <none>        3306/TCP         2m29s
spring-petclinic   NodePort    10.110.207.204   <none>        8080:31981/TCP   2m29s
```

> (참고) hostname 설정 필요
```
# vi /etc/hosts
{k8s cluster ip} healinyoon.com
```

* Ingress 동작 테스트
```
$ curl -i healinyoon.com:30087/
HTTP/1.1 200
Content-Type: text/html;charset=UTF-8
Content-Language: en
Transfer-Encoding: chunked
Date: Mon, 23 Nov 2020 14:21:18 GMT
```