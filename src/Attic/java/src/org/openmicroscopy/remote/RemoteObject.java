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

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;

import org.openmicroscopy.*;

public class RemoteObject
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

    protected void finalize()
    {
        System.err.println("finalize "+getClass()+"."+reference);
        if (caller != null)
            caller.freeObject(this);
    }

    public String getReference() { return reference; }
    public void setReference(String reference) { this.reference = reference; }

    public String toString() { return reference; }

    static RemoteObject instantiate(Class clazz, Object reference)
    {
        return instantiate(clazz,(String) reference);
    }

    static RemoteObject instantiate(Class clazz, String reference)
    {
        if (clazz == null)
            throw new IllegalArgumentException("Cannot find class!");

        if ((reference != null) && (!reference.equals("")))
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
            newObj.setReference(reference);
            //System.err.println(newObj);
            return newObj;
        } else {
            return null;
        }
    }


    protected boolean getBooleanElement(String element)
    { return ((Boolean) caller.dispatch(this,element)).booleanValue(); }
    protected void setBooleanElement(String element, boolean value)
    { caller.dispatch(this,element,new Boolean(value)); }

    protected int getIntElement(String element)
    { return ((Integer) caller.dispatch(this,element)).intValue(); }
    protected void setIntElement(String element, int value)
    { caller.dispatch(this,element,new Integer(value)); }

    protected long getLongElement(String element)
    { return ((Long) caller.dispatch(this,element)).longValue(); }
    protected void setLongElement(String element, long value)
    { caller.dispatch(this,element,new Long(value)); }

    protected float getFloatElement(String element)
    { return ((Float) caller.dispatch(this,element)).floatValue(); }
    protected void setFloatElement(String element, float value)
    { caller.dispatch(this,element,new Float(value)); }

    protected double getDoubleElement(String element)
    { return ((Double) caller.dispatch(this,element)).doubleValue(); }
    protected void setDoubleElement(String element, double value)
    { caller.dispatch(this,element,new Double(value)); }

    protected String getStringElement(String element)
    { return (String) caller.dispatch(this,element); }
    protected void setStringElement(String element, String value)
    { caller.dispatch(this,element,value); }

    protected Object getObjectElement(String element)
    { return caller.dispatch(this,element); }
    protected void setObjectElement(String element, Object value)
    { caller.dispatch(this,element,value); }

    protected RemoteObject getRemoteElement(Class clazz,
                                            String element)
    { return instantiate(clazz,caller.dispatch(this,element)); }
    protected void setRemoteElement(String element, Object value)
    { caller.dispatch(this,element,value); }

    protected List getRemoteListElement(Class clazz,
                                        String element)
    {
        List refList = (List) caller.dispatch(this,element);
        List objList = new ArrayList();
        Iterator i = refList.iterator();
        while (i.hasNext())
            objList.add(instantiate(clazz,(String) i.next()));
        return objList;
    }

    protected Attribute getAttributeElement(String element)
    { return (Attribute)
          instantiate(RemoteAttribute.class,
                      caller.dispatch(this,element)); }
    protected void setAttributeElement(String element, Attribute value)
    { caller.dispatch(this,element,value); }
}
