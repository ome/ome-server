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

import java.util.List;
import java.util.Map;
import java.util.HashMap;

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
        } else if (result instanceof List) {
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
        } else if (result instanceof List) {
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
            throw new RemoteServerErrorException("Invalid result type "+
                                                 result.getClass());
        }

    }


}
