import ballerina.data.sql;

struct ResultPrimitive {
    int INT_TYPE;
    int LONG_TYPE;
    float FLOAT_TYPE;
    float DOUBLE_TYPE;
    boolean BOOLEAN_TYPE;
    string STRING_TYPE;
}

int iValue = -1;
int lValue = -1;
float fValue = -1;
float dValue = -1;
boolean bValue = false;
string sValue = "";

function testForEachIterationWithPrimitives () (int i, int l, float f, float d, boolean b, string s) {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(sql:DB.HSQLDB_FILE, "./target/tempdb/",
                                   0, "TEST_DATA_TABLE_DB", "SA", "", {maximumPoolSize:1});
    }
    table<ResultPrimitive> dt = testDB.select("SELECT int_type, long_type, float_type, double_type,
              boolean_type, string_type from DataTable where row_id = 1", null, typeof ResultPrimitive);
    dt.foreach (function (ResultPrimitive p) {
                                                iValue = p.INT_TYPE;
                                                lValue = p.LONG_TYPE;
                                                fValue = p.FLOAT_TYPE;
                                                dValue = p.DOUBLE_TYPE;
                                                bValue = p.BOOLEAN_TYPE;
                                                sValue = p.STRING_TYPE;
                                             }
               );
    i = iValue;
    l = lValue;
    f = fValue;
    d = dValue;
    b = bValue;
    s = sValue;
    testDB.close();
    return;
}


function testCountOperation () (int count) {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(sql:DB.HSQLDB_FILE, "./target/tempdb/",
                                   0, "TEST_DATA_TABLE_DB", "SA", "", {maximumPoolSize:1});
    }
    table<ResultPrimitive> dt = testDB.select("SELECT int_type, long_type, float_type, double_type,
              boolean_type, string_type from DataTable where row_id < 3", null, typeof ResultPrimitive);
    count = dt.count();
    //count = dt.count();
    //println("Count:" + count); //TODO: Checke why count twice works, and whether we need to load data into memory
    testDB.close();
    return;
}


function testFilterOperation () (int count) {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(sql:DB.HSQLDB_FILE, "./target/tempdb/",
                                   0, "TEST_DATA_TABLE_DB", "SA", "", {maximumPoolSize:1});
    }
    table<ResultPrimitive> dt = testDB.select("SELECT int_type, string_type from DataTable where row_id < 3", null, typeof ResultPrimitive);
    table<ResultPrimitive> dt2 = dt.filter(filterRow);
    count = dt2.count();
    println("Count:" + count);
    testDB.close();
    return;
}
function filterRow(ResultPrimitive p) (boolean){
    return p.INT_TYPE >=  0;
}