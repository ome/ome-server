/*
 * org.openmicroscopy.remote.RemoteFactory
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

import org.openmicroscopy.Factory;
import org.openmicroscopy.ModuleExecution;
import org.openmicroscopy.Attribute;
import org.openmicroscopy.OMEObject;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteFactory
    extends RemoteObject
    implements Factory
{
    static { addClass("OME::Factory",RemoteFactory.class); }

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
        String newRef = (String) caller.dispatch(this,"newObject",
                                                 new Object[] {
                                                     className,
                                                     data
                                                 });
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public OMEObject maybeNewObject(String className, Map data)
    {
        String newRef = (String) caller.dispatch(this,"maybeNewObject",
                                                 new Object[] {
                                                     className,
                                                     data
                                                 });
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public OMEObject loadObject(String className, int id)
    {
        String newRef = (String) caller.dispatch(this,"loadObject",
                                                 new Object[] { 
                                                     className, 
                                                     new Integer(id) 
                                                 });
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    private Object[] fixCriteria(String className, Map criteria)
    {
        if (criteria == null)
            return new Object[] { className };

        List list = new ArrayList();
        list.add(className);
        Iterator iter = criteria.keySet().iterator();
        while (iter.hasNext())
        {
            Object key = iter.next();
            list.add(key);
            list.add(criteria.get(key));
        }

        Object[] result = new Object[list.size()];
        for (int i = 0; i < result.length; i++)
            result[i] = list.get(i);

        return result;
    }

    public boolean objectExists(String className, Map criteria)
    {
        return (caller.dispatch(this,"objectExists",
				fixCriteria(className,criteria)).toString()
		.equals("1"));
    }

    public OMEObject findObject(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObject",
                                        fixCriteria(className,criteria))
            .toString();
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public List findObjects(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjects",
                                              fixCriteria(className,criteria));
        List objList = new ArrayList();
        if (refList != null)
        {
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(instantiate(getClass(className),
                                        (String) i.next()));
        }
        return objList;
    }

    public Iterator iterateObjects(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) 
            instantiate(getClass("OME::Factory::Iterator"),
                        caller.dispatch(this,"iterateObjects",
                                        fixCriteria(className,criteria)));
        i.setClass(getClass(className));
        return i;
    }

    public OMEObject findObjectLike(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObjectLike",
                                        fixCriteria(className,criteria))
            .toString();
        return (OMEObject) instantiate(getClass(className),newRef);
    }

    public List findObjectsLike(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjectsLike",
                                              fixCriteria(className,criteria));
        List objList = new ArrayList();
        if (refList != null)
        {
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(instantiate(getClass(className),
                                        (String) i.next()));
        }
        return objList;
    }

    public Iterator iterateObjectsLike(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) 
            instantiate(getClass("OME::Factory::Iterator"),
                        caller.dispatch(this,"iterateObjectsLike",
                                        fixCriteria(className,criteria)));
        i.setClass(getClass(className));
        return i;
    }

    public Attribute newAttribute(String typeName,
                                  OMEObject target,
                                  ModuleExecution analysis,
                                  Map data)
    {
        String newRef = (String) caller.dispatch(this,"newAttribute",
                                                 new Object[] {
                                                     typeName,
                                                     target,
                                                     analysis,
                                                     data
                                                 });
        if (newRef == null)
            return null;
        else
            return (Attribute)
                instantiate(getClass("OME::SemanticType::Superclass"),
                            newRef);
    }

    public Attribute loadAttribute(String className, int id)
    {
        String newRef = (String) caller.dispatch(this,"loadAttribute",
                                                 new Object[] {
                                                     className, 
                                                     new Integer(id)
                                                 });
        if (newRef == null)
            return null;
        else
            return (Attribute)
                instantiate(getClass("OME::SemanticType::Superclass"),
                            newRef);
    }

    public List findAttributes(String typeName, OMEObject target)
    {
        List refList = (List) caller.dispatch(this,"findAttributes",
                                              new Object[] {
                                                  typeName,
                                                  target
                                              });
        List objList = new ArrayList();
        if (refList != null)
        {
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(instantiate(getClass("OME::SemanticType::Superclass"),
                                        (String) i.next()));
        }
        return objList;
    }

}
