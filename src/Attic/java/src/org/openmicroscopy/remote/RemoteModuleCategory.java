/*
 * org.openmicroscopy.remote.RemoteModuleCategory
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

public class RemoteModuleCategory
    extends RemoteOMEObject
    implements ModuleCategory
{
    static
    {
        RemoteObject.addClass("OME::Module::Category",
                              RemoteModuleCategory.class);
    }

    public RemoteModuleCategory() { super(); }
    public RemoteModuleCategory(String reference) { super(reference); }

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
            getRemoteElement(RemoteModuleCategory.class,"parent_category"); }
    public void setParentCategory(ModuleCategory parentCategory)
    { setRemoteElement("parent_category",parentCategory); }

    public List getChildren()
    { return getRemoteListElement(RemoteModuleCategory.class,"children"); }
    public Iterator iterateChildren()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_children");
        i.setClass(RemoteModuleCategory.class);
        return i;
    }

    public List getModules()
    { return getRemoteListElement(RemoteModule.class,"modules"); }
    public Iterator iterateModules()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_modules");
        i.setClass(RemoteModule.class);
        return i;
    }

    public String toString() { return getName(); }
}
