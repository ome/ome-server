/*
 * org.openmicroscopy.remote.RemoteObject
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

import java.util.Map;
import org.openmicroscopy.OMEObject;
import org.openmicroscopy.Session;

public class RemoteOMEObject
    extends RemoteObject
    implements OMEObject
{
    static
    {
        RemoteObjectCache.addClass("OME::DBObject",RemoteOMEObject.class);
    }

    private boolean populated = false;

    public boolean isPopulated() { return populated; }
    public void setPopulated(boolean populated) { this.populated = populated; }

    public RemoteOMEObject() { super(); }
    public RemoteOMEObject(RemoteSession session, String reference)
    { super(session,reference); }

    public int getID()
    { return getIntElement("id"); }

    public void writeObject() 
    { caller.dispatch(this,"writeObject"); }

    public void populate() { populate(true); }

    public void populate(boolean force)
    {
        if (force || !populated)
        {
            Object result = caller.dispatch(this,"populate");

            if (result instanceof Map)
            {
                elementCache = (Map) result;
                populated = true;
            } else {
                System.err.println("Unknown result type: "+result.getClass());
            }
        }
    }

    public Session getSession()
    { return getRemoteSession(); }

    public boolean equals(OMEObject o)
    {
        return getID() == o.getID();
    }

    public boolean equals(Object o)
    {
        return equals((OMEObject) o);
    }
}
