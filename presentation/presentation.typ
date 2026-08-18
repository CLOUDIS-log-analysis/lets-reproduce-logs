#import "@preview/cmarker:0.1.6"
#import "template/slides.typ": slides
#import "@preview/decasify:0.11.3": titlecase

#show: slides.with(
  title: [
    로그 재현 기록
  ],
  authors: (
    (
      name: "김건우",
      avatar: "Portrait_Placeholder.png",
    ),
    (
      name: "김명진",
      avatar: "Portrait_Placeholder.png",
    ),
    (
      name: "김성현",
      avatar: "Portrait_Placeholder.png",
    ),
    (
      name: "이진우",
      avatar: "Portrait_Placeholder.png",
    ),
  ),
)


#let iterate_logs(proj_name, logs) = {
  pagebreak()
  align(horizon + center)[
    #text(size: 8.0em, titlecase(proj_name))
  ]
  for log_name in logs [
    #pagebreak()
    #set page(
      header: [
        #set text(size: 0.5em);
        #log_name
      ],
    )
    #cmarker.render(read("../" + proj_name + "/" + log_name + "/README.md"), scope: (
      image: (source, ..args) => image("../" + proj_name + "/" + log_name + "/" + source, ..args),
    ))
  ]
}

#let cassandra_logs = ("CASSANDRA-8280", "CASSANDRA-8351", "CASSANDRA-13669", "CASSANDRA-15896");
#iterate_logs("cassandra", cassandra_logs)

#let mongodb_logs = ("SERVER-51733", "SERVER-77168", "SERVER-101180", "SERVER-115200");
#iterate_logs("mongodb", mongodb_logs)

#let zookeeper_logs = ("zk2247",);
#iterate_logs("zookeeper", zookeeper_logs)
#pagebreak()
#set page(
  header: [
    #set text(size: 0.5em);
    "ZOOKEEPER-2592"
  ],
)
#cmarker.render(read("../zookeeper/ZOOKEEPER-2592/summary.md"))

#let redis_logs = ("redis-2857", "redis-4356", "redis-13099", "redis-15424");
#iterate_logs("redis", redis_logs)

#pagebreak()

#align(center)[
  마지막 페이지
]

