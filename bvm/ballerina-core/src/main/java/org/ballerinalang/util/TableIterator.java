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

import org.ballerinalang.model.ColumnDefinition;
import org.ballerinalang.model.DataIterator;
import org.ballerinalang.model.types.BStructType;
import org.ballerinalang.model.types.BType;
import org.ballerinalang.model.types.TypeTags;
import org.ballerinalang.model.values.BStruct;
import org.ballerinalang.util.exceptions.BallerinaException;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

/**
 * Iterator implementation for table data types.
 */
public class TableIterator implements DataIterator {
    private ResultSet rs;
    private BStructType type;

    public TableIterator(ResultSet rs, BStructType type) {
        this.rs = rs;
        this.type = type;
    }

    @Override
    public boolean next() {
        if (rs == null) {
            return false;
        }
        try {
            return rs.next();
        } catch (SQLException e) {
            throw new BallerinaException(e.getMessage(), e);
        }
    }

    @Override
    public void close(boolean isInTransaction) {

    }

    @Override
    public String getString(int columnIndex) {
        return null;
    }

    @Override
    public long getInt(int columnIndex) {
        return 0;
    }

    @Override
    public double getFloat(int columnIndex) {
        return 0;
    }

    @Override
    public boolean getBoolean(int columnIndex) {
        return false;
    }

    @Override
    public String getBlob(int columnIndex) {
        return null;
    }

    @Override
    public Object[] getStruct(int columnIndex) {
        return new Object[0];
    }

    @Override
    public Object[] getArray(int columnIndex) {
        return new Object[0];
    }

    @Override
    public BStruct generateNext() {
        BStruct bStruct = new BStruct(type);
        int longRegIndex = -1;
        int doubleRegIndex = -1;
        int stringRegIndex = -1;
        int booleanRegIndex = -1;
        int index = 0;
        BStructType.StructField[] structFields = type.getStructFields();
        for (BStructType.StructField sf : structFields) {
            BType type = sf.getFieldType();
            try {
                ++index;
                switch (type.getTag()) {
                    case TypeTags.INT_TAG:
                        long iValue = rs.getInt(index);
                        bStruct.setIntField(++longRegIndex, iValue);
                        break;
                    case TypeTags.STRING_TAG:
                        String sValue = rs.getString(index);
                        bStruct.setStringField(++stringRegIndex, sValue);
                        break;
                    case TypeTags.FLOAT_TAG:
                        double dalue = rs.getDouble(index);
                        bStruct.setFloatField(++doubleRegIndex, dalue);
                        break;
                    case TypeTags.BOOLEAN_TAG:
                        boolean boolValue = rs.getBoolean(index);
                        bStruct.setBooleanField(++booleanRegIndex, boolValue ? 1 : 0);
                        break;
                }
            } catch (SQLException e) {
                throw new BallerinaException("error in generating next row data :" + e.getMessage());
            }
        }
        return bStruct;
    }

    @Override
    public List<ColumnDefinition> getColumnDefinitions() {
        return null;
    }

    @Override
    public BStructType getStructType() {
        return null;
    }
}
