/*
*  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing,
*  software distributed under the License is distributed on an
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
*  KIND, either express or implied.  See the License for the
*  specific language governing permissions and limitations
*  under the License.
*/
package org.ballerinalang.util;

import org.ballerinalang.model.types.BStructType;
import org.ballerinalang.model.types.BTableType;
import org.ballerinalang.model.types.BType;
import org.ballerinalang.model.types.TypeTags;
import org.ballerinalang.util.exceptions.BallerinaException;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * {@code TableProvider} creates In Memory database for tables.
 *
 * @since 0.962.0
 */
public class TableProvider {
    private static TableProvider tableProvider = null;
    private Connection connection = null;
    private int tableID;

    private TableProvider() {
        initDatabase();
    }

    public static TableProvider getInstance() {
        if (tableProvider == null) {
            synchronized (TableProvider.class) {
                if (tableProvider == null) {
                    tableProvider = new TableProvider();
                }
            }
        }
        return tableProvider;
    }

    private void initDatabase() {
        try {
            Class.forName(TableConstants.DRIVER_CLASS_NAME);
            String jdbcURL = TableConstants.DB_JDBC_URL;
            connection = DriverManager.getConnection(jdbcURL, TableConstants.DB_USER_NAME, TableConstants.DB_PASSWORD);
        } catch (ClassNotFoundException | SQLException e) {
            throw new BallerinaException("error in initializing database for table types : " + e.getMessage());
        }
    }

    public String createTable(BType constrainedType) {
        Statement st = null;
        String tableName = TableConstants.TABLE_PREFIX + tableID++;
        try {
            st = connection.createStatement();
            String sqlStmt = generateCreateTableStatment(tableName, constrainedType);
            st.executeUpdate(sqlStmt);
        } catch (SQLException e) {
            throw new BallerinaException("error in creating table : " + e.getMessage());
        } finally {
            releaseResources(st);
        }
        return tableName;
    }

    public TableIterator createIterator(String tableName, BStructType type) {
        TableIterator itr;
        Statement st = null;
        try {
            st = connection.createStatement();
            ResultSet rs = st.executeQuery(TableConstants.SQL_SELECT + tableName);
            itr = new TableIterator(rs, type);
        } catch (SQLException e) {
            releaseResources(st);
            throw new BallerinaException("error in creating iterator for table : " + e.getMessage());
        }
        return itr;
    }

    private String generateCreateTableStatment(String tableName, BType constrainedType) {
        StringBuilder sb = new StringBuilder();
        sb.append(TableConstants.SQL_CREATE).append(tableName).append(" (");
        BStructType.StructField[] structFields = ((BStructType) ((BTableType) constrainedType).getConstrainedType())
                .getStructFields();
        String seperator = "";
        for (BStructType.StructField sf : structFields) {
            int type = sf.getFieldType().getTag();
            String name = sf.getFieldName();
            sb.append(seperator).append(name).append(" ");
            switch (type) {
                case TypeTags.INT_TAG:
                    sb.append(TableConstants.SQL_TYPE_BIGINT);
                    break;
                case TypeTags.STRING_TAG:
                    sb.append(TableConstants.SQL_TYPE_VARCHAR);
                    break;
                case TypeTags.FLOAT_TAG:
                    sb.append(TableConstants.SQL_TYPE_DOUBLE);
                    break;
                case TypeTags.BOOLEAN_TAG:
                    sb.append(TableConstants.SQL_TYPE_BOOLEAN);
                    break;
            }
            seperator = ",";
        }
        sb.append(")");
        return sb.toString();
    }

    private void releaseResources(Statement st) {
        try {
            if (st != null) {
                st.close();
            }
        } catch (SQLException e) {
            throw new BallerinaException("error in releasing table resources : " + e.getMessage());
        }
    }
}
