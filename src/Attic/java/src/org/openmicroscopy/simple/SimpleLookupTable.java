/*
 * org.openmicroscopy.simple.SimpleLookupTable
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

public class SimpleLookupTable
    extends SimpleObject
    implements LookupTable
{
    protected String  name, description;
    protected List    entries;

    public SimpleLookupTable() { super(); }

    public SimpleLookupTable(int id, String name, String description)
    {
        super(id);
        this.name = name;
        this.description = description;
        this.entries = new ArrayList();
    }

    public String getName() 
    { return name; }
    public void setName(String name)
    { this.name = name; }

    public String getDescription() 
    { return description; }
    public void setDescription(String description)
    { this.description = description; }


    public int getNumEntries()
    { return entries.size(); }
    public Entry getEntry(int index)
    { return (Entry) entries.get(index); }
    public Iterator iterateEntries()
    { return entries.iterator(); }
    public List getEntries() { return entries; }

    public Entry addEntry(int id,String value,String label)
    {
        Entry entry;

        entries.add(entry = new SimpleEntry(id,value,label));
        return entry;
    }


    public class SimpleEntry
        extends SimpleObject
        implements LookupTable.Entry, Comparable
    {
        protected String  value, label;

        public SimpleEntry() { super(); }

        public SimpleEntry(int id, String value, String label)
        {
            super(id);
            this.value = value;
            this.label = label;
        }

        public LookupTable getLookupTable() { return SimpleLookupTable.this; }

        public String getValue() 
        { return value; }
        public void setValue(String value)
        { this.value = value; }

        public String getLabel() 
        { return label; }
        public void setLabel(String label)
        { this.label = label; }

        public int compareTo(Object o)
        {
            LookupTable.Entry e = (LookupTable.Entry) o;

            return this.label.compareTo(e.getLabel());
        }
    }
}
