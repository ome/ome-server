/*
 * org.openmicroscopy.remote.RemoteSemanticType
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
//import java.util.ArrayList;
import java.util.Iterator;

public class RemoteSemanticType
    extends RemoteOMEObject
    implements SemanticType
{
    static
    {
        RemoteObject.addClass("OME::SemanticType",
                              RemoteSemanticType.class);
        RemoteObject.addClass("OME::SemanticType::Element",
                              RemoteSemanticType.Element.class);
    }


    public RemoteSemanticType() { super(); }
    public RemoteSemanticType(String reference) { super(reference); }

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

    public List getElements()
    { return getRemoteListElement(Element.class,"semantic_elements"); }

    public Iterator iterateElements()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_semantic_elements");
        i.setClass(Element.class);
        return i;
    }

    public static class Element
        extends RemoteOMEObject
        implements SemanticType.Element
    {
        public Element() { super(); }
        public Element(String reference) { super(reference); }

        public SemanticType getSemanticType()
        { return (SemanticType)
              getRemoteElement(RemoteSemanticType.Element.class,
                               "semantic_element"); }

        public String getElementName()
        { return getStringElement("name"); }
        public void setElementName(String elementName)
        { setStringElement("name",elementName); }

        public String getElementDescription()
        { return getStringElement("description"); }
        public void setElementDescription(String description)
        { setStringElement("description",description); }

        public DataTable.Column getDataColumn()
        { return (DataTable.Column) 
              getRemoteElement(RemoteDataTable.Column.class,
                               "data_column"); }
        public void setDataColumn(DataTable.Column dataColumn)
        { setRemoteElement("data_column",dataColumn); }
    }
}
