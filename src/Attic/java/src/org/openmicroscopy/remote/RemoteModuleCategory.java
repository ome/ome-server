/*
 * org.openmicroscopy.remote.RemoteModuleCategory
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

public class RemoteModuleCategory
    extends RemoteOMEObject
    implements ModuleCategory
{
    static
    {
        RemoteObjectCache.addClass("OME::Module::Category",
                                   RemoteModuleCategory.class);
    }

    public RemoteModuleCategory() { super(); }
    public RemoteModuleCategory(RemoteSession session, String reference)
    { super(session,reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public ModuleCategory getParentCategory()
    { return (ModuleCategory) 
            getRemoteElement("OME::Module::Category",
                             "parent_category"); }
    public void setParentCategory(ModuleCategory parentCategory)
    { setRemoteElement("parent_category",parentCategory); }

    public List getChildren()
    { return getCachedRemoteListElement("OME::Module::Category",
                                        "children"); }
    public Iterator iterateChildren()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_children");
        i.setClass("OME::Module::Category");
        return i;
    }

    public List getModules()
    { return getRemoteListElement("OME::Module",
                                  "modules"); }
    public Iterator iterateModules()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement("OME::Factory::Iterator",
                             "iterate_modules");
        i.setClass("OME::Module");
        return i;
    }

    public String toString() { return getName(); }
}
