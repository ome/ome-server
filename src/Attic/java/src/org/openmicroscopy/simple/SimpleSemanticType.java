/*
 * org.openmicroscopy.simple.SimpleSemanticType
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
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

public class SimpleSemanticType
    extends SimpleObject
    implements SemanticType
{
    protected String  name, description;
    protected int     granularity;
    protected List    elements;

    public SimpleSemanticType() 
    {
        super();
        this.elements = new ArrayList();
    }

    public SimpleSemanticType(int    id,
                              String name,
                              String description,
                              int    granularity)
    {
        super(id);
        this.name = name;
        this.description = description;
        this.granularity = granularity;
        this.elements = new ArrayList();
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

    public int getNumElements()
    { return elements.size(); }
    public Element getElement(int index)
    { return (Element) elements.get(index); }
    public Iterator iterateElements()
    { return elements.iterator(); }
    public List getElements() { return elements; }

    public Element addElement(int              id,
                              String           elementName,
                              String           elementDescription,
                              DataTable.Column dataColumn)
    {
        Element element;

        elements.add(element = new SimpleElement(id,
                                                 elementName,
                                                 elementDescription,
                                                 dataColumn));
        return element;
    }

    public class SimpleElement
        extends SimpleObject
        implements SemanticType.Element
    {
        protected String            elementName, elementDescription;
        protected DataTable.Column  dataColumn;

        public SimpleElement() { super(); }

        public SimpleElement(int              id,
                             String           elementName,
                             String           elementDescription,
                             DataTable.Column dataColumn)
        {
            super(id);
            this.elementName = elementName;
            this.elementDescription = elementDescription;
            this.dataColumn = dataColumn;
        }

        public SemanticType getSemanticType() { return SimpleSemanticType.this; }

        public String getElementName()
        { return elementName; }
        public void setElementName(String elementName)
        { this.elementName = elementName; }

        public String getElementDescription()
        { return elementDescription; }
        public void setElementDescription(String elementDescription)
        { this.elementDescription = elementDescription; }

        public DataTable.Column getDataColumn()
        { return dataColumn; }
        public void setDataColumn(DataTable.Column dataColumn)
        { this.dataColumn = dataColumn; }
    }
}
