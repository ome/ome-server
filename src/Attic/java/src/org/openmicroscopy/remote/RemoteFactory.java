/*
 * org.openmicroscopy.remote.RemoteFactory
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

import org.openmicroscopy.Factory;
import org.openmicroscopy.OMEObject;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteFactory
    extends RemoteObject
    implements Factory
{
    static { RemoteObject.addClass("OME::Factory",RemoteFactory.class); }

    protected void finalize()
    {
        // RemoteObject will automatically call the freeObject method
        // in the remote server when the object is garbage collected.
        // This should not happen for Factories, so we override
        // finalize to do nothing.
    }

    public RemoteFactory() { super(); }
    public RemoteFactory(String reference) { super(reference); }

    public OMEObject newObject(String className, Map data)
    {
        String newRef = caller.dispatch(this,"newObject",
                                        new Object[] { className,data })
            .toString();
        return (OMEObject) instantiate(getClass(className),reference);
    }

    public OMEObject loadObject(String className, int id)
    {
        String newRef = caller.dispatch(this,"loadObject",
                                        new Object[] { className, 
                                                       new Integer(id) })
            .toString();
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public boolean objectExists(String className, Map criteria)
    {
        return ((Boolean) caller.dispatch(this,"objectExists",
                                          (criteria == null)?
                                          new Object[] { className }:
                                          new Object[] { className,criteria }))
            .booleanValue();
    }

    public OMEObject findObject(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObject",
                                        (criteria == null)?
                                        new Object[] { className }:
                                        new Object[] { className,criteria })
            .toString();
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public List findObjects(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjects",
                                              (criteria == null)?
                                              new Object[] { className }:
                                              new Object[] { className,criteria });
        List objList = new ArrayList();
        Iterator i = refList.iterator();
        while (i.hasNext())
            objList.add(instantiate(getClass(className),(String) i.next()));
        return objList;
    }

    public Iterator iterateObjects(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) RemoteObject.
            instantiate(RemoteIterator.class,
                        caller.dispatch(this,"iterateObjects",
                                        (criteria == null)?
                                        new Object[] { className }:
                                        new Object[] { className,criteria }));
        i.setClass(getClass(className));
        return i;
    }

    public OMEObject findObjectLike(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObjectLike",
                                        (criteria == null)?
                                        new Object[] { className }:
                                        new Object[] { className,criteria })
            .toString();
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public List findObjectsLike(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjectsLike",
                                              (criteria == null)?
                                              new Object[] { className }:
                                              new Object[] { className,criteria });
        List objList = new ArrayList();
        Iterator i = refList.iterator();
        while (i.hasNext())
            objList.add(instantiate(getClass(className),(String) i.next()));
        return objList;
    }

    public Iterator iterateObjectsLike(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) RemoteObject.
            instantiate(RemoteIterator.class,
                        caller.dispatch(this,"iterateObjectsLike",
                                        (criteria == null)?
                                        new Object[] { className }:
                                        new Object[] { className,criteria }));
        i.setClass(getClass(className));
        return i;
    }

}
