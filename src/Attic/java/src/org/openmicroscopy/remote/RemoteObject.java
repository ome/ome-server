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
    { classes.put(className,clazz); }

    protected static Class getClass(String className)
    { return (Class) classes.get(className); }

    protected String reference;
    public RemoteObject() { this.reference = null; }
    public RemoteObject(String reference) { this.reference = reference; }

    protected Map elementCache = new HashMap();

    protected void finalize()
    {
        //System.err.println("finalize "+getClass()+"."+reference);
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

    protected Object getCachedElement(String element)
    {
        if (elementCache.containsKey(element))
        {
            //System.err.println("--- cache "+getClass()+" "+element);
            return elementCache.get(element);
        } else {
            //System.err.println("--- NO CACHE "+getClass()+" "+element);
            Object o = caller.dispatch(this,element);
            elementCache.put(element,o);
            return o;
        }
    }

	protected Object getCachedListElement(Class clazz,String element) {
   		if (elementCache.containsKey(element)) {
       	  return elementCache.get(element);
       }
       else {
	   	Object o = caller.dispatch(this,element);
	   	if (o instanceof List)
	   	{
		   List refList = (List) o;
		   List objList = new ArrayList();
		   Iterator i = refList.iterator();
		   while (i.hasNext())
		   	objList.add(instantiate(clazz,(String) i.next()));
			return objList;
		 } else if (o == null) {
			 return null;
		 } else {
			 if (o == null) o = "null";
			 throw new RemoteException(element+": expect List (of "+clazz+"), got "+o.getClass());
		 }
       }
	 }
	   
    private void saveElement(String element, Object value)
    {
        elementCache.put(element,value);
        caller.dispatch(this,element,value);
    }

    protected boolean getBooleanElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            String s = (String) o;
            return
                s.equalsIgnoreCase("true") ||
                s.equalsIgnoreCase("t") ||
                s.equalsIgnoreCase("yes") ||
                s.equalsIgnoreCase("y") ||
                s.equalsIgnoreCase("1");
        } else if (o instanceof Boolean) {
            return ((Boolean) o).booleanValue();
        } else if (o instanceof Integer) {
            return ((Integer) o).intValue() != 0;
        } else if (o == null) {
            return false;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect boolean, got "+o.getClass());
        }
    }
    protected void setBooleanElement(String element, boolean value)
    { saveElement(element,new Boolean(value)); }

    protected int getIntElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            String s = (String) o;
            return Integer.parseInt(s);
        } else if (o instanceof Integer) {
            return ((Integer) o).intValue();
        } else if (o == null) {
            return 0;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect int, got "+o.getClass());
        }
    }
    protected void setIntElement(String element, int value)
    { saveElement(element,new Integer(value)); }

    protected long getLongElement(String element)
    {
        // XML-RPC's only integer type is Integer
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            String s = (String) o;
            return Long.parseLong(s);
        } else if (o instanceof Integer) {
            return (long) ((Integer) o).intValue();
        } else if (o == null) {
            return 0L;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect long, got "+o.getClass());
        }
    }
    protected void setLongElement(String element, long value)
    { saveElement(element,new Integer((int) value)); }

    protected float getFloatElement(String element)
    {
        // XML-RPC's only floating-point type is Double
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            String s = (String) o;
            return Float.parseFloat(s);
        } else if (o instanceof Double) {
            return (float) ((Double) o).doubleValue();
        } else if (o == null) {
            return 0.0F;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect float, got "+o.getClass());
        }
    }
    protected void setFloatElement(String element, float value)
    { saveElement(element,new Double(value)); }

    protected double getDoubleElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            String s = (String) o;
            return Double.parseDouble(s);
        } else if (o instanceof Double) {
            return ((Double) o).doubleValue();
        } else if (o == null) {
            return 0.0D;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect double, got "+o.getClass());
        }
    }
    protected void setDoubleElement(String element, double value)
    { saveElement(element,new Double(value)); }

    protected String getStringElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            return (String) o;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect String, got "+o.getClass());
        }
    }
    protected void setStringElement(String element, String value)
    { saveElement(element,value); }

    protected Object getObjectElement(String element)
    { return getCachedElement(element); }
    protected void setObjectElement(String element, Object value)
    { saveElement(element,value); }

    protected RemoteObject getRemoteElement(Class clazz,
                                            String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            RemoteObject ro =  instantiate(clazz,(String) o);
            elementCache.put(element,ro);
            return ro;
        } else if (o instanceof RemoteObject) {
            return (RemoteObject) o;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect String (ref "+clazz+"), got "+o.getClass());
        }
    }
    protected void setRemoteElement(String element, Object value)
    { saveElement(element,value); }

	/**
	 * getRemoteListElement
	 * <p>This is the uncached version. See {@link #getCachedRemoteListElement 
	 * getCachedRemoteListElement} for the cached version.<p> 
	 * <p>The choice between the cached and uncached will be made as 
	 * appropriate by the subclass of RemoteObject. 
	 * @param clazz - the java class that is the tpe of the element.
	 * @param element - the name of the element
	 * @return List - list of objects of the given class, from the given name.
	 */
    protected List getRemoteListElement(Class clazz,
                                        String element)
    {
    
    	Object o = caller.dispatch(this,element);
        if (o instanceof List)
        {
            List refList = (List) o;
            List objList = new ArrayList();
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(instantiate(clazz,(String) i.next()));
            return objList;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect List (of "+clazz+"), got "+o.getClass());
        }
    }
    
    /**
     * getCachedRemoteListElement
     * <p> The cached version of getRemoteListElement
     * 
     * @param clazz
     * @param element
     * @return List
     */
     protected List getCachedRemoteListElement(Class clazz,String element) {
    	
    	Object o = getCachedListElement(clazz,element);
    	if (o instanceof List) {
    		return (List) o;
    	}
    	else if (o == null) {
    		return null;
    	}
    	else {
    		if (o == null)
    			o=null;
    		throw new RemoteException(element+": expect List, got "+o.getClass());
    	}
     }

    protected Attribute getAttributeElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            Attribute a = (Attribute)
                instantiate(getClass("OME::SemanticType::Superclass"),
                            (String) o);
            elementCache.put(element,a);
            return a;
        } else if (o instanceof Attribute) {
            return (Attribute) o;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect String (Attribute), got "+o.getClass());
        }
    }
    protected void setAttributeElement(String element, Attribute value)
    { saveElement(element,value); }
}
