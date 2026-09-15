package com.stratio;

import com.datastax.driver.core.Cluster;
import com.datastax.driver.core.Session;
import com.datastax.driver.core.Statement;
import com.datastax.driver.core.querybuilder.QueryBuilder;
import com.datastax.driver.core.schemabuilder.CreateKeyspace;
import com.datastax.driver.core.schemabuilder.KeyspaceOptions;

import javax.xml.ws.Endpoint;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static java.lang.System.exit;

/**
 * @author Eduardo Alonso {@literal <eduardoalonso@stratio.com>}
 */


public class Writer {

    private static Map<String,String> readArguments(String[] args) {
        HashMap<String, String> result= new HashMap<String, String>();
        int lookingForKey=0;//0 for looking for key, 1 for looking for starting value, 2 for continue a value
        String key="",value="";
        for (int i=0;i<args.length;i++) {
            if (lookingForKey==0) {
                if (args[i].startsWith("-")) {
                    key=args[i].substring(1,args[i].length());
                    lookingForKey=1;
                }
            } else if (lookingForKey==1) {
                if (!args[i].startsWith("-")) {
                    value+=args[i];
                    lookingForKey=2;
                } else {
                    result.put(key,value);
                    key=args[i].substring(1,args[i].length());
                    lookingForKey=1;
                }
            } else if (lookingForKey==2) {
                if (!args[i].startsWith("-")) {
                    value+=" "+args[i];
                } else {
                    result.put(key,value);
                    key=args[i].substring(1,args[i].length());
                    value="";
                    lookingForKey=1;
                }
            }
        }
        result.put(key,value);
        return result;
    }
    private static String getCompulsoryArgument(Map<String,String> arguments, String key) {
        String aux= arguments.get(key);
        if ((aux==null) || (aux.trim().length()==0)) {
            System.out.println(String.format("Argument -%s required",key));
            exit(-1);
        }
        return aux;
    }

    public static void main (String [] args) {
        Map<String,String> arguments= readArguments(args);
        String host=getCompulsoryArgument(arguments,"host");
        String keyspace=getCompulsoryArgument(arguments,"keyspace");
        String table=getCompulsoryArgument(arguments,"table");


        Cluster cluster=Cluster.builder().addContactPoint(host).build();
        Session session  = cluster.connect();

        String createKeyspace=String.format("CREATE KEYSPACE IF NOT EXISTS %s  WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1}  AND durable_writes = true;",keyspace);
        session.execute(createKeyspace);
        String createTable=String.format("CREATE TABLE IF NOT EXISTS %s.%s( pk uuid, mylist list<text>, PRIMARY KEY (pk));",keyspace,table);
        session.execute(createTable);

        Statement insert = QueryBuilder.insertInto(keyspace, table)
                                          .value("pk", UUID.randomUUID())
                                          .value("mylist","blabla");
        session.execute(insert);
        session.close();
        cluster.close();
    }


}
