#!/usr/bin/env bash

# create standalone mongod with auth
mongod --port 3000 --dbpath data --logpath /data/mongod.log --wiredTigerCacheSizeGB 1 --auth --fork
mongosh --port 3000 --eval 'rs.initiate()'
mongosh admin --port 3000 --eval "db.createUser({user: 'user', pwd: 'password', roles: ['root']})"

# create & insert data into a time series collection
mongosh --port 3000 --username "user" --password "password" --eval 'db.setLogLevel(5)'
mongosh --port 3000 --username "user" --password "password" --eval 'db.createCollection( "weather", { timeseries: { timeField: "timestamp", metaField: "metadata", granularity: "hours" } } )'
mongosh --port 3000 --username "user" --password "password" --eval 'db.weather.insertOne( { "metadata": { "sensorId": 5578, "type": "temperature" }, "timestamp": ISODate("2021-05-18T00:00:00.000Z"), "temp": 12 } )'

# dump
mongodump --port 3000 --username "user" --password "password"

# restore
mongorestore --port 3000 --drop --username "user" --password "password" dump/test/system.buckets.weather.bson
