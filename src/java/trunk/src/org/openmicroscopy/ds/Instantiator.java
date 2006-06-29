/*
 * org.openmicroscopy.ds.Instantiator
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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


package org.openmicroscopy.ds;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Vector;

import org.openmicroscopy.ds.dto.MappedDTO;
import org.openmicroscopy.ds.dto.AttributeDTO;

/**
 * Contains the methods for serializing and deserializing DTO methods
 * from their XML-RPC framework representations.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class Instantiator
{
    /**
     * Creates a new <code>Instantiator</code> instance.
     */
    public Instantiator() { super(); }

    private Class getDTOClass(Class javaClass)
    {
        return RemoteTypes.getDTOClass(javaClass);
    }

    private Map semanticTypeClassCache = new HashMap();

    /**
     * Determines which class should be used to instantiate an
     * attribute DTO.  If a specific interface and DTO exists for the
     * attribute's semantic type, it is used.  Otherwise, the DTO will
     * be an instance of the generic Attribute interface.  A cache of
     * the class used for each semantic type is kept, so that the
     * inefficient reflection calls are called as little as possible.
     */
    private Class getSemanticTypeClass(String semanticTypeName)
    {
        if (semanticTypeClassCache.containsKey(semanticTypeName))
            return (Class) semanticTypeClassCache.get(semanticTypeName);

        try
        {
            Class clazz = Class.forName("org.openmicroscopy.ds.st."+
                                        semanticTypeName+"DTO");
            if (clazz == null)
                clazz = AttributeDTO.class;

            semanticTypeClassCache.put(semanticTypeName,clazz);
            return clazz;
        } catch (ClassNotFoundException e) {
            Class clazz = AttributeDTO.class;
            semanticTypeClassCache.put(semanticTypeName,clazz);
            return clazz;
        }
    }

    /**
     * Instantiates a single DTO {@link Map} into an instance of the
     * specified DTO class.
     *
     * @param javaClass the DTO interface to instantiate
     * @param result the result returned from the underlying {@link
     * RemoteCaller}
     * @return an instance of the specified DTO class, with its values
     * filled in from the <code>result</code> map
     */
    public MappedDTO instantiateDTO(Class javaClass, Object result)
    {
        if (result == null)
            return null;
        if (result instanceof String) {
            String s = (String) result;
            if (s.compareTo(MappedDTO.NULL_REFERENCE) == 0 ||
                s.length() ==0)
                return null;
            else
                throw new RemoteServerErrorException("Invalid result type "+
                                                     result.getClass());
        }
        if (result instanceof Map)
        {
            Class dtoClass = getDTOClass(javaClass);
            Map map = (Map) result;

            try
            {
                MappedDTO dto = (MappedDTO) dtoClass.newInstance();
                dto.setMap(map);
                return dto;
            } catch (ClassCastException e) {
                throw new RemoteServerErrorException(dtoClass+" is not a MappedDTO subclass");
            } catch (InstantiationException e) {
                throw new RemoteServerErrorException("Could not create DTO instance: "+
                                                     e.getMessage());
            } catch (IllegalAccessException e) {
                throw new RemoteServerErrorException("Could not create DTO instance: "+
                                                     e.getMessage());
            }

        } else {
            throw new RemoteServerErrorException("Invalid result type "+
                                                 result.getClass());
        }
    }

    /**
     * Instantiates a single DTO {@link Map} into an instance of the
     * specified DTO class.
     *
     * @param semanticType the name of the semantic type to instantiate
     * @param result the result returned from the underlying {@link
     * RemoteCaller}
     * @return an instance of the specified DTO class, with its values
     * filled in from the <code>result</code> map
     */
    public AttributeDTO instantiateDTO(String semanticType, Object result)
    {
        if (result == null)
            return null;

        if (result instanceof String) {
            String s = (String) result;
            if (s.compareTo(MappedDTO.NULL_REFERENCE) == 0 || s.length() ==0)
                return null;
            else
                throw new RemoteServerErrorException("Invalid result type "+
                                                     result.getClass());
        }
        if (result instanceof Map)
        {
            Class dtoClass = getSemanticTypeClass(semanticType);
            Map map = (Map) result;

            try
            {
                MappedDTO dto = (MappedDTO) dtoClass.newInstance();
                dto.setMap(map);
                return (AttributeDTO) dto;
            } catch (ClassCastException e) {
                throw new RemoteServerErrorException(dtoClass+" is not a MappedDTO subclass");
            } catch (InstantiationException e) {
                throw new RemoteServerErrorException("Could not create DTO instance: "+
                                                     e.getMessage());
            } catch (IllegalAccessException e) {
                throw new RemoteServerErrorException("Could not create DTO instance: "+
                                                     e.getMessage());
            }

        } else {
            throw new RemoteServerErrorException("Invalid result type "+
                                                 result.getClass());
        }
    }

    /**
     * Instantiates {@link List} of DTO {@link Map}s into a instances
     * of the specified DTO class.  The list is modified in place,
     * with the maps being replaced with their corresponding DTO
     * instances.  If the list contains any objects which are not
     * {@link Map}s, a {@link RemoteServerErrorException} is thrown.
     * The instantiation of each map is performed by the {@link
     * #instantiateDTO} method.
     *
     * @param javaClass the DTO interface to instantiate
     * @param result the DTO {@link Map} returned from the underlying
     * {@link RemoteCaller}
     */
    public List instantiateList(Class javaClass, Object result)
    {
        if (result == null)
        {
            return null;
        }
        if (result instanceof String) {
            String s = (String) result;
            if (s.compareTo(MappedDTO.NULL_REFERENCE) == 0 || s.length() ==0)
                return null;
            else
                throw new RemoteServerErrorException("Invalid result type "+
                                                     result.getClass());
        }
        if (result instanceof List) {
            List list = (List) result;

            try
            {
                for (int i = 0; i < list.size(); i++)
                {
                    MappedDTO dto = instantiateDTO(javaClass,
                                                   list.get(i));
                    list.set(i,dto);
                }
            } catch (ClassCastException e) {
                throw new RemoteServerErrorException("Remote result can only contain Maps");
            }

            return list;
        } else {
            throw new RemoteServerErrorException("Invalid result type "+
                                                 result.getClass());
        }

    }

    /**
     * Instantiates {@link List} of DTO {@link Map}s into a instances
     * of the specified DTO class.  The list is modified in place,
     * with the maps being replaced with their corresponding DTO
     * instances.  If the list contains any objects which are not
     * {@link Map}s, a {@link RemoteServerErrorException} is thrown.
     * The instantiation of each map is performed by the {@link
     * #instantiateDTO} method.
     *
     * @param semanticType the name of the semantic type to
     * instantiate
     * @param result the DTO {@link Map} returned from the underlying
     * {@link RemoteCaller}
     */
    public List instantiateList(String semanticType, Object result)
    {
        if (result == null)
        {
            return null;
        }
        if (result instanceof String) {
            String s = (String) result;
            if (s.compareTo(MappedDTO.NULL_REFERENCE) == 0 || s.length() ==0)
                return null;
            else
                throw new RemoteServerErrorException("Invalid result type "+
                                                     result.getClass());
        }
        if (result instanceof List) {
            List list = (List) result;

            try
            {
                for (int i = 0; i < list.size(); i++)
                {
                    AttributeDTO dto = instantiateDTO(semanticType,
                                                      list.get(i));
                    list.set(i,dto);
                }
            } catch (ClassCastException e) {
                throw new RemoteServerErrorException("Remote result can only contain Maps");
            }

            return list;
        } else {
            // make a single-element list
            Vector v = new Vector();
            v.add(result);
            return v;
        }

    }

    /**
     * <p>Creates a serialized {@link Map} of the format expected by
     * the <code>updateObject</code> and <code>updateObjects</code>
     * remote server methods.  The <code>newIDs</code> parameter is
     * used to store all of the new objects (i.e., not in the database
     * yet) which had been serialized previously for this remote
     * method call.  It is used to ensure that any object references
     * in the data object refer to existent objects.</p>
     *
     * @param dto the data object to serialize
     * @param newIDs a {@link Map} linking new-ID values to data
     * objects
     * @return a serialized {@link Map} suitable to be sent to the
     * XML-RPC layer
     */
    public Map serializeForUpdate(MappedDTO dto, Map newIDs)
    {
        Map serialized = new HashMap();

        Map elements = dto.getMap();
        Iterator keys = elements.keySet().iterator();

        // Create a Map of the format expected by the updateObject
        // method

        while (keys.hasNext())
        {
            Object key = keys.next();
            Object element = elements.get(key);

            if (element == null)
            {
                // Null values can be saved

                serialized.put(key,element);
            } else if (element instanceof MappedDTO) {
                // References are turned into primary key ID's.  If
                // the referent object is new, then it must have a
                // new-ID specified in the newIDs map in order to be
                // serialized.  If it doesn't, throw an error.

                MappedDTO child = (MappedDTO) element;
                if (child.isNew())
                {
                    Object id;
                    if (newIDs != null &&
                        (id = newIDs.get(child)) != null)
                    {
                        serialized.put(key,id);
                    } else {
                        throw new DataException("Referent object in "+key+" field is new, and has not been assigned a new-ID");
                    }
                } else {
                    serialized.put(key,
                                   "REF:"+
                                   child.getDTOTypeName()+":"+
                                   child.getMap().get("id"));
                }
            } else if (element instanceof List) {
                // Skip List elements
            } else if (element instanceof Map) {
                // Skip Map elements
            } else {
                // Store anything else as is
                serialized.put(key,element);
            }
        }

        // If the object being saved is new, make sure that its "id"
        // field signifies it as such.

        if (dto.isNew())
        {
            if (newIDs == null)
            {
                serialized.put("id","NEW:1");
            } else {
                Object id = newIDs.get(dto);
                if (id == null)
                    throw new DataException("Fatal error -- new object has not been assigned an ID yet");
                else
                    serialized.put("id",id);
            }
        }

        return serialized;
    }


}
