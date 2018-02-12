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

/**
 * This file contains a list of constant values used by Table implementation.
 */
public class TableConstants {

    static final String DRIVER_CLASS_NAME = "org.h2.Driver";
    static final String DB_JDBC_URL = "jdbc:h2:mem:TESTDB";
    static final String DB_USER_NAME = "sa";
    static final String DB_PASSWORD = "";

    static final String TABLE_PREFIX = "TABLE_";

    static final String SQL_SELECT = "SELECT * FROM ";
    static final String SQL_CREATE = "CREATE TABLE ";

    static final String SQL_TYPE_VARCHAR = "VARCHAR(50)";
    static final String SQL_TYPE_BIGINT = "BIGINT";
    static final String SQL_TYPE_DOUBLE = "DOUBLE";
    static final String SQL_TYPE_BOOLEAN = "BOOLEAN";
}
