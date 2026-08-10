# 로그 분석

버그 리포트를 재현하고 로그를 수집할 때 그 과정을 기록하기 위한 리포지토리입니다.

만약 버그 리포트 CASSANDRA-8280에 관한 내용을 작성한다면:
```
└── cassandra
    └── CASSANDRA-8280
        ├── README.md
        ├── expected-log
        ...
```
이런 형식으로 CASSANDRA-8280 디렉토리에 재현에 필요한 파일들을 넣어주시고 README.md에 재현 절차를 기술해 주세요.

expected-log는 버그 시점에서 어떤 로그가 뜨는지 기록한 것으로, 너무 길다면 앞뒤는 제거하고 버그가 난 것을 알 수 있는 로그만 남겨주세요. 

README.md에 쓰여진 절차대로 진행하여 expected-log와 같은 형태의 로그를 얻는 것이 목적입니다.

만약 바이너리 파일을 활용해야 한다면 바로 커밋하지 말고 인터넷에서 받아올 수 있도록 README.md를 작성해주세요. (cassandra/CASSANDRA-8280/README.md 참고)
