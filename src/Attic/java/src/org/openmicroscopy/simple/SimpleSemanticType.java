/*
 * org.openmicroscopy.simple.SimpleAttributeType
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

package org.openmicroscopy.simple;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import org.openmicroscopy.*;

public class SimpleAttributeType
    extends SimpleObject
    implements AttributeType
{
    protected String  name, description;
    protected int     granularity;
    protected List    columns;

    public SimpleAttributeType() 
    {
        super();
        this.columns = new ArrayList();
    }

    public SimpleAttributeType(int    id,
                               String name,
                               String description,
                               int    granularity)
    {
        super(id);
        this.name = name;
        this.description = description;
        this.granularity = granularity;
        this.columns = new ArrayList();
    }

    public String getName()
    { return name; }
    public void setName(String name)
    { this.name = name; }

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

    public Column addColumn(int              id,
                            String           columnName,
                            String           columnDescription,
                            DataTable.Column dataColumn)
    {
        Column column;

        columns.add(column = new SimpleColumn(id,
                                              columnName,
                                              columnDescription,
                                              dataColumn));
        return column;
    }

    public class SimpleColumn
        extends SimpleObject
        implements AttributeType.Column
    {
        protected String            columnName, columnDescription;
        protected DataTable.Column  dataColumn;

        public SimpleColumn() { super(); }

        public SimpleColumn(int              id,
                            String           columnName,
                            String           columnDescription,
                            DataTable.Column dataColumn)
        {
            super(id);
            this.columnName = columnName;
            this.columnDescription = columnDescription;
            this.dataColumn = dataColumn;
        }

        public AttributeType getAttributeType() { return SimpleAttributeType.this; }

        public String getColumnName()
        { return columnName; }
        public void setColumnName(String columnName)
        { this.columnName = columnName; }

        public String getColumnDescription()
        { return columnDescription; }
        public void setColumnDescription(String columnDescription)
        { this.columnDescription = columnDescription; }

        public DataTable.Column getDataColumn()
        { return dataColumn; }
        public void setDataColumn(DataTable.Column dataColumn)
        { this.dataColumn = dataColumn; }
    }
}
