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
import java.util.WeakHashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteFactory
    extends RemoteObject
    implements Factory
{
    static { RemoteObjectCache.addClass("OME::Factory",RemoteFactory.class); }

    private Map populatedLists = new WeakHashMap();

    protected void finalize()
    {
        // RemoteObject will automatically call the freeObject method
        // in the remote server when the object is garbage collected.
        // This should not happen for Factories, so we override
        // finalize to do nothing.
    }

    public RemoteFactory() { super(); }
    public RemoteFactory(RemoteSession session, String reference)
    { super(session,reference); }

    public OMEObject newObject(String className, Map data)
    {
        String newRef = (String) caller.dispatch(this,"newObject",
                                                 new Object[] {
                                                     className,
                                                     data
                                                 });
        return (OMEObject) getRemoteSession().getObjectCache().
            getObject(className,newRef);
    }

    public OMEObject maybeNewObject(String className, Map data)
    {
        String newRef = (String) caller.dispatch(this,"maybeNewObject",
                                                 new Object[] {
                                                     className,
                                                     data
                                                 });
        return (OMEObject) getRemoteSession().getObjectCache().
            getObject(className,newRef);
    }

    public OMEObject loadObject(String className, int id)
    {
        String newRef = (String) caller.dispatch(this,"loadObject",
                                                 new Object[] { 
                                                     className, 
                                                     new Integer(id) 
                                                 });
        return (OMEObject) getRemoteSession().getObjectCache().
            getObject(className,newRef);
    }

    private Object[] fixCriteria(String className, Map criteria)
    {
        if (criteria == null)
            return new Object[] { className };
        else
            return new Object[] { className, criteria };
    }

    public boolean objectExists(String className, Map criteria)
    {
        return (caller.dispatch(this,"objectExistsByCriteriaHash",
                                fixCriteria(className,criteria)).toString()
                .equals("1"));
    }

    public OMEObject findObject(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObjectByCriteriaHash",
                                        fixCriteria(className,criteria))
            .toString();
        return (OMEObject) getRemoteSession().getObjectCache().
            getObject(className,newRef);
    }

    public List findObjects(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjectsByCriteriaHash",
                                              fixCriteria(className,criteria));
        List objList = new ArrayList();
        if (refList != null)
        {
            RemoteObjectCache  cache = getRemoteSession().getObjectCache();
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(cache.getObject(className,(String) i.next()));
        }
        return objList;
    }

    public Iterator iterateObjects(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) 
            getRemoteSession().getObjectCache().
            getObject("OME::Factory::Iterator",
                      (String) caller.dispatch(this,"iterateObjectsByCriteriaHash",
                                               fixCriteria(className,
                                                           criteria)));
        i.setClass(className);
        return i;
    }

    public OMEObject findObjectLike(String className, Map criteria)
    {
        String newRef = caller.dispatch(this,"findObjectLikeByCriteriaHash",
                                        fixCriteria(className,criteria))
            .toString();
        return (OMEObject) getRemoteSession().getObjectCache().
            getObject(className,newRef);
    }

    public List findObjectsLike(String className, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findObjectsLikeByCriteriaHash",
                                              fixCriteria(className,criteria));
        List objList = new ArrayList();
        if (refList != null)
        {
            RemoteObjectCache  cache = getRemoteSession().getObjectCache();
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(cache.getObject(className,(String) i.next()));
        }
        return objList;
    }

    public Iterator iterateObjectsLike(String className, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) 
            getRemoteSession().getObjectCache().
            getObject("OME::Factory::Iterator",
                      (String) caller.dispatch(this,"iterateObjectsLikeByCriteriaHash",
                                               fixCriteria(className,
                                                           criteria)));
        i.setClass(className);
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
                getRemoteSession().getObjectCache().
                getObject("OME::SemanticType::Superclass",
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
                getRemoteSession().getObjectCache().
                getObject("OME::SemanticType::Superclass",
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
            RemoteObjectCache  cache = getRemoteSession().getObjectCache();
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(cache.getObject("OME::SemanticType::Superclass",
                                            (String) i.next()));
        }
        return objList;
    }

    public List findAttributes(String typeName, Map criteria)
    {
        List refList = (List) caller.dispatch(this,"findAttributesByCriteriaHash",
                                              fixCriteria(typeName,criteria));
        List objList = new ArrayList();
        if (refList != null)
        {
            RemoteObjectCache  cache = getRemoteSession().getObjectCache();
            Iterator i = refList.iterator();
            while (i.hasNext())
                objList.add(cache.getObject("OME::SemanticType::Superclass",
                                            (String) i.next()));
        }
        return objList;
    }


    public Iterator iterateAttributes(String typeName, Map criteria)
    {
        RemoteIterator i = (RemoteIterator) 
            getRemoteSession().getObjectCache().
            getObject("OME::Factory::Iterator",
                      (String) caller.dispatch(this,"iterateAttributesByCriteriaHash",
                                               fixCriteria(typeName,
                                                           criteria)));
        i.setClass("OME::SemanticType::Superclass");
        return i;
    }

    public void populateList(List list) { populateList(list,true); }

    public void populateList(List list, boolean force)
    {
        if (force || !populatedLists.containsKey(list))
        {
            Object result = caller.dispatch("OME::DBObject","populate_list",list);

            if (result instanceof List)
            {
                List resultList = (List) result;
                if (list.size() != resultList.size())
                {
                    System.err.println("Return list not of same length!");
                } else {
                    for (int i = 0; i < list.size(); i++) 
                    {
                        Object obj = list.get(i);
                        Object cache = resultList.get(i);
                        if (!(obj instanceof RemoteOMEObject))
                        {
                            System.err.println("Input not a RemoteOMEObject");
                        } else if (!(cache instanceof Map)) {
                            System.err.println("Output not a Map");
                        } else {
                            RemoteOMEObject robj = (RemoteOMEObject) obj;
                            robj.setElementCache((Map) cache);
                            robj.setPopulated(true);
                        }
                    }

                    populatedLists.put(list,null);
                }
            } else {
                System.err.println("Unknown result type: "+result.getClass());
            }
        }
    }
}
