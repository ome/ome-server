/*
 * org.openmicroscopy.remote.RemoteObject
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

import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.OMEObject;

public class RemoteObject
    implements OMEObject
{
    protected static RemoteCaller caller = null;

    public static void setRemoteCaller(RemoteCaller caller)
    { RemoteObject.caller = caller; }

    protected static Map classes = new HashMap();

    protected static void addClass(String className, Class clazz)
    { classes.put(className,clazz); 
    System.err.println(className+" "+clazz);}

    protected static Class getClass(String className)
    { return (Class) classes.get(className); }

    protected String reference;
    public RemoteObject() { this.reference = null; }
    public RemoteObject(String reference) { this.reference = reference; }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public String toString() { return reference; }
}
