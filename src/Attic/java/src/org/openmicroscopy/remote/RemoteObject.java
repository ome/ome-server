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

/**
 * <p>Represents any remote object returned from a remote method call.
 * Most of its state is maintained as a remote object reference.
 * There are accessor helper methods which subclasses can use to
 * implement the necessary accessor methods defined by their
 * interfaces.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public class RemoteObject
{
    /**
     * The delegate used to make remote procedure calls.
     */
    protected static RemoteCaller caller = null;

    /**
     * The {@link Session} that created this object.
     */
    protected static RemoteSession session = null;

    /**
     * Sets the delegate used to make remote procedure calls.
     * Currently only one implementation of {@link RemoteCaller} is
     * provided -- {@link XmlRpcCaller}.
     * @param caller the RPC delegate to use
     */
    public static void setRemoteCaller(RemoteCaller caller)
    { RemoteObject.caller = caller; }

    /**
     * The remote object reference that this <code>RemoteObject</code>
     * represents.
     */
    protected String reference;

    /**
     * Creates a new <code>RemoteObject</code> instance with no
     * reference.  This is provided so that calls to {@link
     * Class#newInstance} succeed; the {@link #setReference} should
     * immediately be called on the instance which is returned..
     */
    public RemoteObject() { this.reference = null; }

    /**
     * Creates a new <code>RemoteObject</code> instance with the given
     * reference.
     * @param reference the remote reference for this object
     */
    public RemoteObject(RemoteSession session, String reference)
    {
        this.reference = reference;
        this.session = session;
    }

    /**
     * Caches the fields of this object, to eliminate unnecessary
     * remote calls.
     */
    protected Map elementCache = new HashMap();

    /**
     * Empties the local element cache for this object.  The next time
     * each accessor method is called, it will make an RPC call.
     */
    public void refresh() { elementCache.clear(); }

    /**
     * Removes the object from the remote server cache when the
     * garbage collector determines that this object is no longer in
     * scope.
     */
    protected void finalize()
    {
        //System.err.println("finalize "+getClass()+"."+reference);
        if (caller != null)
            caller.freeObject(this);
    }

    /**
     * Returns the {@link RemoteSession} that created this object.
     * @return the {@link RemoteSession} that created this object
     */
    public RemoteSession getRemoteSession() { return session; }

    /**
     * Sets this object's session.  This should almost never be called
     * -- its main purpose is to finish setting the object's state
     * after calling the no-parameter constructor (usually via {@link
     * Class#newInstance}).
     * @param reference this object's session
     */
    public void setRemoteSession(RemoteSession session)
    { this.session = session; }

    /**
     * Returns this object's remote reference.
     * @return this object's remote reference
     */
    public String getReference() { return reference; }

    /**
     * Sets this object's remote reference.  This should almost never
     * be called -- its main purpose is to finish setting the object's
     * state after calling the no-parameter constructor (usually via
     * {@link Class#newInstance}).
     * @param reference this object's remote reference
     */
    public void setReference(String reference) { this.reference = reference; }

    public String toString() { return reference; }

    /**
     * Returns the result of calling the <code>element</code> method
     * on this remote object.  The first time this element is loaded,
     * the actual RPC call is made, and its result is cached.  On
     * subsequent invocations, the cached value is returned without
     * making the RPC call.
     * @param element the element to return
     */
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

    /**
     * Calls the <code>element</code> method as a mutator, and updates
     * the local element cache to reflect this new value.
     * @param element the element whose value is to be set and cache
     * @param value the element's value
     */
    private void saveElement(String element, Object value)
    {
        elementCache.put(element,value);
        caller.dispatch(this,element,value);
    }

    /**
     * An accessor helper method to retrieve <code>boolean</code>
     * values with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set <code>boolean</code> values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setBooleanElement(String element, boolean value)
    { saveElement(element,new Boolean(value)); }

    /**
     * An accessor helper method to retrieve <code>int</code> values
     * with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set <code>int</code> values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setIntElement(String element, int value)
    { saveElement(element,new Integer(value)); }

    /**
     * An accessor helper method to retrieve <code>long</code> values
     * with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set <code>long</code> values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setLongElement(String element, long value)
    { saveElement(element,new Integer((int) value)); }

    /**
     * An accessor helper method to retrieve <code>float</code> values
     * with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set <code>float</code> values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setFloatElement(String element, float value)
    { saveElement(element,new Double(value)); }

    /**
     * An accessor helper method to retrieve <code>double</code>
     * values with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set <code>double</code> values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setDoubleElement(String element, double value)
    { saveElement(element,new Double(value)); }

    /**
     * An accessor helper method to retrieve {@link String} values
     * with caching.
     * @param element the element to retrieve
     */
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

    /**
     * A mutator helper method to set {@link String} values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setStringElement(String element, String value)
    { saveElement(element,value); }

    /**
     * An accessor helper method to retrieve {@link Object} values
     * with caching.  This method does not try to resolve the object
     * into a more restrictive class -- it returns whatever is
     * returned by the RPC caller.
     * @param element the element to retrieve
     */
    protected Object getObjectElement(String element)
    { return getCachedElement(element); }

    /**
     * A mutator helper method to set {@link Object} values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setObjectElement(String element, Object value)
    { saveElement(element,value); }

    /**
     * An accessor helper method to retrieve remote object values with
     * caching.  The value is assumed to be an instance of the
     * <code>perlClass</code> remote class.  The session's object
     * cache is used to ensure that only one Java instance is created
     * for each remote object reference.
     * @param perlClass the remote class of the return value
     * @param element the element to retrieve
     */
    protected RemoteObject getRemoteElement(String perlClass,
                                            String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            RemoteObject object =
                getRemoteSession().getObjectCache().
                getObject(perlClass,(String) o);
            elementCache.put(element,object);
            return object;
        } else if (o instanceof RemoteObject) {
            return (RemoteObject) o;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect String (ref "+perlClass+"), got "+o.getClass());
        }
    }

    /**
     * A mutator helper method to set remote object values with
     * caching.  This is effectively the same as calling {@link
     * #setStringElement} with <code>value</code>'s object reference
     * as the value.
     * @param element the element to set
     * @param value the new value
     */
    protected void setRemoteElement(String element, Object value)
    { saveElement(element,value); }

    /**
     * Returns the result of calling the <code>element</code> method
     * on this remote object, and assumes that the result is a list of
     * <code>perlClass</code> objects.  No caching is done.
     * @param perlClass the name of the Perl class that the list
     * should contain
     * @param element the name of the element to retrieve
     */
    protected List getRemoteListElement(String perlClass,
                                        String element)
    {
	   	Object o = caller.dispatch(this,element);
	   	if (o instanceof List)
	   	{
            List refList = (List) o;
            List objList = new ArrayList();
            Iterator i = refList.iterator();
            RemoteObjectCache cache = getRemoteSession().getObjectCache();
            while (i.hasNext())
                objList.add(cache.getObject(perlClass,(String) i.next()));
			return objList;
        } else if (o == null) {
            return null;
        } else {
            if (o == null) o = "null";
            throw new RemoteException(element+": expect List (of "+perlClass+"), got "+o.getClass());
        }
    }

    /**
     * Returns the result of calling the <code>element</code> method
     * on this remote object, and assumes that the result is a list of
     * <code>perlClass</code> objects.  The first time this element is
     * loaded, the actual RPC call is made, and its result is cached.
     * On subsequent invocations, the cached value is returned without
     * making the RPC call.
     * @param perlClass the name of the Perl class that the list
     * should contain
     * @param element the name of the element to retrieve
     */
    protected List getCachedRemoteListElement(String perlClass,
                                              String element)
    {
   		if (elementCache.containsKey(element))
        {
            return (List) elementCache.get(element);
        } else {
            List list = getRemoteListElement(perlClass,element);
            elementCache.put(element,list);
            return list;
        }
     }

    /**
     * An accessor helper method to retrieve {@link Attribute} values
     * with caching.
     * @param element the element to retrieve
     */
    protected Attribute getAttributeElement(String element)
    {
        Object o = getCachedElement(element);
        if (o instanceof String)
        {
            Attribute a = (Attribute)
                getRemoteSession().getObjectCache().
                getObject("OME::SemanticType::Superclass",(String) o);
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

    /**
     * A mutator helper method to set {@link Attribute} values with
     * caching.
     * @param element the element to set
     * @param value the new value
     */
    protected void setAttributeElement(String element, Attribute value)
    { saveElement(element,value); }
}
