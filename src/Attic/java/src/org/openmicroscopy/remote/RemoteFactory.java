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

public class RemoteFactory
    extends RemoteObject
    implements Factory
{
    static { RemoteObject.addClass("OME::Factory",RemoteFactory.class); }

    public RemoteFactory() { super(); }
    public RemoteFactory(String reference) { super(reference); }

    public OMEObject loadObject(String className, int id)
    {
        Class clazz = RemoteObject.getClass(className);
        String newRef = caller.dispatch(this,"loadObject",
                                        new Object[] { className, 
                                                       new Integer(id) })
            .toString();

        System.err.println(clazz+" "+newRef);

        if ((clazz != null) && (newRef != null))
        {
            RemoteObject newObj = null;
            try
            {
                newObj = (RemoteObject) clazz.newInstance();
            } catch (InstantiationException e) {
                System.err.println(e);
                return null;
            } catch (IllegalAccessException e) {
                System.err.println(e);
                return null;
            }
            newObj.setReference(newRef);
            System.err.println(newObj);
            return newObj;
        } else {
            return null;
        }
    }
}
