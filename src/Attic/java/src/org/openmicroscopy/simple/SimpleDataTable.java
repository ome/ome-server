/*
 * org.openmicroscopy.simple.SimpleDataTable
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
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
 *
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.simple;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import org.openmicroscopy.*;

public class SimpleDataTable
    extends SimpleObject
    implements DataTable
{
    protected String  tableName, description;
    protected int     granularity;
    protected List    columns;

    public SimpleDataTable() 
    {
        super();
        this.columns = new ArrayList();
    }

    public SimpleDataTable(int    id,
                           String tableName,
                           String description,
                           int    granularity)
    {
        super(id);
        this.tableName = tableName;
        this.description = description;
        this.granularity = granularity;
        this.columns = new ArrayList();
    }

    public String getTableName()
    { return tableName; }
    public void setTableName(String tableName)
    { this.tableName = tableName; }

    public String getDescription()
    { return description; }
    public void setDescription(String description)
    { this.description = description; }

    public int getGranularity()
    { return granularity; }
    public void setGranularity(int granularity)
    { this.granularity = granularity; }

    public int getNumColumns()
    { return columns.size(); }
    public Column getColumn(int index)
    { return (Column) columns.get(index); }
    public Iterator iterateColumns()
    { return columns.iterator(); }
    public List getColumns() { return columns; }

    public Column addColumn(int    id,
                            String columnName,
                            String columnDescription,
                            String sqlType)
    {
        Column column;

        columns.add(column = new SimpleColumn(id,
                                              columnName,
                                              columnDescription,
                                              sqlType));
        return column;
    }

    public class SimpleColumn
        extends SimpleObject
        implements DataTable.Column
    {
        protected String columnName, columnDescription, sqlType;

        public SimpleColumn() { super(); }

        public SimpleColumn(int    id,
                            String columnName,
                            String columnDescription,
                            String sqlType)
        {
            super(id);
            this.columnName = columnName;
            this.columnDescription = columnDescription;
            this.sqlType = sqlType;
        }

        public DataTable getDataTable() { return SimpleDataTable.this; }

        public String getColumnName()
        { return columnName; }
        public void setColumnName(String columnName)
        { this.columnName = columnName; }

        public String getColumnDescription()
        { return columnDescription; }
        public void setColumnDescription(String columnDescription)
        { this.columnDescription = columnDescription; }

        public String getSQLType()
        { return sqlType; }
        public void setSQLType(String sqlType)
        { this.sqlType = sqlType; }

        public SemanticType getReferenceType() { return null; }
        public void setReferenceType(SemanticType type) {}
    }
}
