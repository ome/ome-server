/*
 * org.openmicroscopy.remote.RemoteAttributeType
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

public class RemoteAttributeType
    extends RemoteOMEObject
    implements AttributeType
{
    static
    {
        RemoteObject.addClass("OME::AttributeType",
                              RemoteAttributeType.class);
        RemoteObject.addClass("OME::AttributeType::Column",
                              RemoteAttributeType.Column.class);
    }


    public RemoteAttributeType() { super(); }
    public RemoteAttributeType(String reference) { super(reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

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
    { return getRemoteListElement(Column.class,"attribute_columns"); }

    public Iterator iterateColumns()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_attribute_columns");
        i.setClass(Column.class);
        return i;
    }

    public static class Column
        extends RemoteOMEObject
        implements AttributeType.Column
    {
        public Column() { super(); }
        public Column(String reference) { super(reference); }

        public AttributeType getAttributeType()
        { return (AttributeType)
              getRemoteElement(RemoteAttributeType.Column.class,
                               "attribute_column"); }

        public String getColumnName()
        { return getStringElement("name"); }
        public void setColumnName(String columnName)
        { setStringElement("name",columnName); }

        public String getColumnDescription()
        { return getStringElement("description"); }
        public void setColumnDescription(String description)
        { setStringElement("description",description); }

        public DataTable.Column getDataColumn()
        { return (DataTable.Column) 
              getRemoteElement(RemoteDataTable.Column.class,
                               "data_column"); }
        public void setDataColumn(DataTable.Column dataColumn)
        { setRemoteElement("data_column",dataColumn); }
    }
}
