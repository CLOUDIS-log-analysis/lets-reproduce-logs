package com.foo.bar;
import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.CqlSessionBuilder;
import com.datastax.oss.driver.api.core.cql.PreparedStatement;
import com.datastax.oss.driver.api.core.cql.ResultSet;
import com.datastax.oss.driver.api.core.cql.Row;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.net.InetSocketAddress;
import java.net.URI;
import java.util.*;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;

/**
 * @author Domenico Lupinetti <ostico@gmail.com> - 23/06/2020
 */
public class NullPointerExceptionTest {

    protected String uuid;
    protected CqlSession cqlSession;

    @Before
    public void setUp() throws Exception {

        URI node = new URI( "tcp://localhost:9042" );
        final CqlSessionBuilder builder = CqlSession.builder();

        cqlSession = builder.addContactPoint( new InetSocketAddress(
                node.getHost(),
                node.getPort()
        ) ).withLocalDatacenter( "datacenter1" ).build();

        cqlSession.execute( "CREATE KEYSPACE IF NOT EXISTS test_suite WITH replication = {'class':'SimpleStrategy','replication_factor':1};" );

        String sb = "CREATE TABLE IF NOT EXISTS test_suite.test ( id uuid PRIMARY KEY, another_id uuid, subject text );";

        cqlSession.execute( sb );
        PreparedStatement stm = cqlSession.prepare( "INSERT INTO test_suite.test JSON :payload" );

        this.uuid = UUID.randomUUID().toString();

        HashMap<String, String> payload = new HashMap<>();
        payload.put( "id", this.uuid );

        // ******* This exception do not happens if the field is set as NULL
        payload.put( "another_id", "" );  //<------ EMPTY STRING AS UUID
        payload.put( "subject", "Alighieri, Dante. Divina Commedia" );

        ObjectMapper objM = new ObjectMapper();
        cqlSession.execute(
                stm.bind().setString( "payload", objM.writeValueAsString( payload ) )
        );  //<------ serialize as JSON

    }

    @After
    public void tearDown() throws Exception {
        cqlSession.execute( "DROP TABLE IF EXISTS test_suite.test;" );
        cqlSession.execute( "DROP KEYSPACE test_suite;" );
        cqlSession.close();
    }

    @Test
    public void testNullPointer() {

        PreparedStatement stmt       = cqlSession.prepare( "SELECT JSON id, another_id FROM test_suite.test where id = :id;" );
        ResultSet         resultSet  = cqlSession.execute( stmt.bind().setUuid( "id", UUID.fromString( this.uuid ) ) ); // <------ EXCEPTION
        Row               r          = resultSet.one();

        assertNotNull( r );
        assertNotNull( r.getString( "[json]" ) );
        assertFalse( Objects.requireNonNull( r.getString( "[json]" ) ).isEmpty() );

    }

}

