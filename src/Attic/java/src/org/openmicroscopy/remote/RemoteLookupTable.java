/*
 * org.openmicroscopy.remote.RemoteLookupTable
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




package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.util.List;
//import java.util.ArrayList;
import java.util.Iterator;

public class RemoteLookupTable
    extends RemoteOMEObject
    implements LookupTable
{
    static
    {
        RemoteObjectCache.addClass("OME::LookupTable",RemoteLookupTable.class);
        RemoteObjectCache.addClass("OME::LookupTable::Entry",
                                   RemoteLookupTable.Entry.class);
    }

    public RemoteLookupTable() { super(); }
    public RemoteLookupTable(RemoteSession session, String reference)
    { super(session,reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public List getEntries()
    { return getRemoteListElement("OME::LookupTable::Entry",
                                  "all_features"); }

    public Iterator iterateEntries()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_all_features");
        i.setClass("OME::LookupTable::Entry");
        return i;
    }

    public static class Entry
        extends RemoteOMEObject
        implements LookupTable.Entry
    {
        public Entry() { super(); }
        public Entry(RemoteSession session, String reference)
        { super(session,reference); }

        public LookupTable getLookupTable()
        { return (LookupTable)
                getRemoteElement("OME::LookupTable",
                                 "lookup_table"); }

        public String getValue()
        { return getStringElement("value"); }
        public void setValue(String value)
        { setStringElement("value",value); }

        public String getLabel()
        { return getStringElement("label"); }
        public void setLabel(String label)
        { setStringElement("label",label); }
    }
}
