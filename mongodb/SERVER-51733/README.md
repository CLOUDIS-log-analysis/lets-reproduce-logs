# SERVER-51733
# 1 -> 2 -> 3
https://jira.mongodb.org/browse/SERVER-51733

# 1. 컨테이너 실행
``` bash
sudo docker compose up -d
``` 

# 2. 이후 MongoDB shell에서 진행필요
``` bash
sudo docker exec -it mongo51733 \
mongo localhost:27019 \
--authenticationDatabase "admin" \
-u "root" \
-p "DontTryThis1satHome"
```

# 3. config서버 인증을 활성화 -> 크래시발생!
``` javascript
rs.initiate({
    _id:"configs",
    configsvr:true,
    members:[
        {
            _id:0,
            host:"localhost:27019"
        }
    ]
})
```
