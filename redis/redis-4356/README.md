# Overview
방대한 쓰기요청으로 인한 메모리 파편화 발생 시 기존 키를 방출하여 확보하는 메모리보다 새로 들어오는 메모리 속도가 빠르면 논리적으로 maxmemory 제한을 유지하더라도 실제 물리 메모리 사용량은 제한을 초과하여 OOM killer가 강제종료

# Step to reproduce
sudo chmod 777 log

docker compose up -d
./fragtrigger.sh

docker compose down

# Check
[system log] ./log/baseline.log 에서 virtual memory 104854824 사용중이라는 로그 확인

" - 60 clients connected (0 slaves), 104854824 bytes in use"


[kernel log] sudo dmesg -T | tail -30 으로 메모리 초과로 인한 OOM Killer 개입 확인

"oom-kill:constraint=CONSTRAINT_MEMCG,nodemask=(null),cpuset=docker-adbaf9ae041f921f696bff13a02993c62c53f2eb95f4a9e665ea578c98d4262c.scope,mems_allowed=0,oom_memcg=/system.slice/docker-adbaf9ae041f921f696bff13a02993c62c53f2eb95f4a9e665ea578c98d4262c.scope,task_memcg=/system.slice/docker-adbaf9ae041f921f696bff13a02993c62c53f2eb95f4a9e665ea578c98d4262c.scope,task=redis-server,pid=107327,uid=999"

"Memory cgroup out of memory: Killed process 107327 (redis-server) total-vm:209580kB, anon-rss:133060kB, file-rss:3072kB, shmem-rss:0kB, UID:999 pgtables:416kB oom_score_adj:0"
