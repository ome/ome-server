/*
 * org.openmicroscopy.remote.RemoteDataTable
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteDataTable
    extends RemoteOMEObject
    implements DataTable
{
    static
    {
        RemoteObject.addClass("OME::DataTable",RemoteDataTable.class);
        RemoteObject.addClass("OME::DataTable::Column",
                              RemoteDataTable.Column.class);
    }

    public RemoteDataTable() { super(); }
    public RemoteDataTable(String reference) { super(reference); }

    public String getTableName()
    { return getStringElement("table_name"); }
    public void setTableName(String tableName)
    { setStringElement("table_name",tableName); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public int getGranularity()
    {
        String granularity = getStringElement("granularity");
        if (granularity.equals("G"))
            return Granularity.GLOBAL;
        else if (granularity.equals("D"))
            return Granularity.DATASET;
        else if (granularity.equals("I"))
            return Granularity.IMAGE;
        else if (granularity.equals("F"))
            return Granularity.FEATURE;
        else
            throw new IllegalArgumentException("Got a bad granularity");
    }
    public void setGranularity(int granularity)
    {
        if (granularity == Granularity.GLOBAL)
            setStringElement("granularity","G");
        else if (granularity == Granularity.DATASET)
            setStringElement("granularity","D");
        else if (granularity == Granularity.IMAGE)
            setStringElement("granularity","I");
        else if (granularity == Granularity.FEATURE)
            setStringElement("granularity","F");
        else
            throw new IllegalArgumentException("Got a bad dependence");
    }

    public List getColumns()
    { return getRemoteListElement(Column.class,"data_columns"); }

    public Iterator iterateColumns()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_data_columns");
        i.setClass(Column.class);
        return i;
    }

    public static class Column
        extends RemoteOMEObject
        implements DataTable.Column
    {
        public Column() { super(); }
        public Column(String reference) { super(reference); }

        public DataTable getDataTable()
        { return (DataTable) getRemoteElement(RemoteDataTable.Column.class,
                                              "data_table"); }

        public String getColumnName()
        { return getStringElement("column_name"); }
        public void setColumnName(String columnName)
        { setStringElement("column_name",columnName); }

        public String getColumnDescription()
        { return getStringElement("description"); }
        public void setColumnDescription(String description)
        { setStringElement("description",description); }

        public String getSQLType()
        { return getStringElement("sql_type"); }
        public void setSQLType(String sqlType)
        { setStringElement("sql_type",sqlType); }

        public AttributeType getReferenceType()
        { return (AttributeType) getRemoteElement(RemoteAttributeType.class,
                                                  "reference_type"); }
        public void setReferenceType(AttributeType referenceType)
        { setRemoteElement("reference_type",referenceType); }
    }
}
