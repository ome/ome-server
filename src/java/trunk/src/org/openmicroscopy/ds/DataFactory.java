/*
 * org.openmicroscopy.ds.DataFactory
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


package org.openmicroscopy.ds;

import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.ds.dto.MappedDTO;

/**
 * <p>Provides a higher-level interface to the data server than that
 * provided by the {@link RemoteCaller} class.  A
 * <code>RemoteCaller</code> does not know anything about the DTO
 * classes provided in the <code>org.openmicroscopy.ds.dto</code>
 * package; it can make remote method calls involving the primitive
 * Java object types ({@link Integer}, {@link String}, etc.) and the
 * collection classes {@link List} and {@link Map}.  This class
 * provides a means of retrieving arbitrary DTO instances from the
 * data server.  It relies heavily on the {@link Criteria} class to
 * specify which objects to retrieve.</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

public class DataFactory
{
    private RemoteCaller caller;

    /**
     * Creates a new <code>DataFactory</code> which communicates with
     * a data server using the specified {@link RemoteCaller}.
     */
    public DataFactory(RemoteCaller caller)
    {
        super();
        this.caller = caller;
    }

    /**
     * Creates a criteria {@link Map} in the format expected by the
     * remote server from the given {@link Criteria} object.
     */
    private Map createCriteriaMap(Criteria criteria)
    {
        if (criteria == null) return null;

        Map map = new HashMap(criteria.getCriteria());

        List orderBy = criteria.getOrderBy();
        if (orderBy != null && orderBy.size() > 0)
            map.put("__order",new ArrayList(orderBy));

        int limit = criteria.getLimit();
        if (limit >= 0)
            map.put("__limit",new Integer(limit));

        int offset = criteria.getOffset();
        if (offset >= 0)
            map.put("__offset",new Integer(offset));

        return map;
    }

    /**
     * Instantiates a single DTO {@link Map} into an instance of the
     * specified DTO class.
     *
     * @param dtoClass the DTO class to instantiate
     * @param result the DTO {@link Map} returned from the underlying
     * {@link RemoteCaller}
     * @return an instance of the specified DTO class, with its values
     * filled in from the <code>result</code> map
     */
    private MappedDTO instantiateDTO(Class dtoClass, Map result)
    {
        try
        {
            MappedDTO dto = (MappedDTO) dtoClass.newInstance();
            dto.setMap(result);
            return dto;
        } catch (ClassCastException e) {
            throw new RemoteException(dtoClass+" is not a MappedDTO subclass");
        } catch (InstantiationException e) {
            throw new RemoteException("Could not create DTO instance: "+
                                      e.getMessage());
        } catch (IllegalAccessException e) {
            throw new RemoteException("Could not create DTO instance: "+
                                      e.getMessage());
        }
    }

    /**
     * Instantiates {@link List} of DTO {@link Map}s into a instances
     * of the specified DTO class.  The list is modified in place,
     * with the maps being replaced with their corresponding DTO
     * instances.  If the list contains any objects which are not
     * {@link Map}s, a {@link RemoteException} is thrown.  The
     * instantiation of each map is performed by the {@link
     * #instantiateDTO} method.
     *
     * @param dtoClass the DTO class to instantiate
     * @param result the DTO {@link Map} returned from the underlying
     * {@link RemoteCaller}
     */
    private void instantiateDTOList(Class dtoClass, List list)
    {
        try
        {
            for (int i = 0; i < list.size(); i++)
            {
                MappedDTO dto = instantiateDTO(dtoClass,(Map) list.get(i));
                list.set(i,dto);
            }
        } catch (ClassCastException e) {
            throw new RemoteException("Remote result can only contain Maps");
        }
    }

    /**
     * Returns the number of objects in the database which match the
     * given criteria.  This version of the method is used to count
     * core data types; the data type desired should be specified by
     * the <code>targetClass</code> parameter.  It should correspond
     * to one of the data interfaces in the
     * <code>org.openmicroscopy.ds.dto</code> package.  Since no
     * objects are actually retrieved from the database, the
     * fields-wanted, order-by, limit, and offset portions of the
     * <code>criteria</code> are ignored.
     *
     * @param targetClass the core data type to count
     * @param criteria the search criteria to use
     * @return the number of objects in the OME database which match
     * the specified criteria
     */
    public int count(Class targetClass, Criteria criteria)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map crit = createCriteriaMap(criteria);

        Object result = caller.dispatch("countObjects",remoteType,crit);
        if (result instanceof Integer)
            return ((Integer) result).intValue();
        else
            throw new RemoteException("Invalid result type "+result.getClass());
    }

    /**
     * Retrieves the of object in the database with the specified
     * primary key ID.  This version of the method is used to retrieve
     * core data types; the data type desired should be specified by
     * the <code>targetClass</code> parameter.  It should correspond
     * to one of the data interfaces in the
     * <code>org.openmicroscopy.ds.dto</code> package.  Since at most
     * one object is ever returned, the filter, order-by, limit, and
     * offset portions of the <code>criteria</code> are ignored.  The
     * fields-wanted portion is used to fill in the values for the DTO
     * object which is returned.  If the fields-wanted section
     * instructs the server to return has-ony and has-many references,
     * a tree of objects will be returned.
     *
     * @param targetClass the core data type to count
     * @param id the primary key ID value to retrieve
     * @param criteria the search criteria to use
     * @return the DTO object matching with the given primary key ID
     */
    public Object load(Class targetClass, int id, Criteria criteria)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map fields = criteria.getFieldsWanted();

        Object result = caller.dispatch("loadObject",remoteType,fields);
        if (result instanceof Map)
        {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            Map map = (Map) result;
            return instantiateDTO(dtoClass,map);
        } else
            throw new RemoteException("Invalid result type "+result.getClass());
    }

    /**
     * Retrieves the one object in the database which matches the
     * specified search criteria.  If more than one object matches,
     * the first match is returned.  Unless an order-by clause is
     * specified in the criteria, it will be undefined which object
     * will be returned.  This version of the method is used to
     * retrieve core data types; the data type desired should be
     * specified by the <code>targetClass</code> parameter.  It should
     * correspond to one of the data interfaces in the
     * <code>org.openmicroscopy.ds.dto</code> package.  The
     * fields-wanted portion of the criteria is used to fill in the
     * values for the DTO object which is returned.  If the
     * fields-wanted section instructs the server to return has-ony
     * and has-many references, a tree of objects will be returned.
     *
     * @param targetClass the core data type to count
     * @param criteria the search criteria to use
     * @return the DTO object matching the specified criteria
     */
    public Object retrieve(Class targetClass, Criteria criteria)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map crit = createCriteriaMap(criteria);
        Map fields = criteria.getFieldsWanted();

        Object result = caller.dispatch("retrieveObject",
                                        new Object[] {remoteType,crit,fields});
        if (result instanceof Map)
        {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            Map map = (Map) result;
            return instantiateDTO(dtoClass,map);
        } else
            throw new RemoteException("Invalid result type "+result.getClass());
    }

    /**
     * Retrieves all of the objects in the database which match the
     * specified search criteria.  Unless an order-by clause is
     * specified in the criteria, the order of the returned object
     * will be undefined.  This version of the method is used to
     * retrieve core data types; the data type desired should be
     * specified by the <code>targetClass</code> parameter.  It should
     * correspond to one of the data interfaces in the
     * <code>org.openmicroscopy.ds.dto</code> package.  The
     * fields-wanted portion of the criteria is used to fill in the
     * values for the DTO object which is returned.  If the
     * fields-wanted section instructs the server to return has-ony
     * and has-many references, a tree of objects will be returned.
     *
     * @param targetClass the core data type to count
     * @param criteria the search criteria to use
     * @return the DTO object matching the specified criteria
     */
    public List retrieveList(Class targetClass, Criteria criteria)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map crit = createCriteriaMap(criteria);
        Map fields = criteria.getFieldsWanted();

        Object result = caller.dispatch("retrieveObjects",
                                        new Object[] {remoteType,crit,fields});
        if (result instanceof List)
        {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            List list = (List) result;
            instantiateDTOList(dtoClass,list);
            return list;
        } else
            throw new RemoteException("Invalid result type "+result.getClass());
    }

    /**
     * <b>Coming soon</b>: Sends a DTO back to the data server to be
     * stored in the database.
     */
    public void update(Class targetClass, Object object)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
    }

    /**
     * <b>Coming soon</b>: Sends a list of DTO's back to the data
     * server to be stored in the database.
     */
    public void updateList(Class targetClass, List list)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
    }
}
