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

import org.openmicroscopy.ds.dto.DataInterface;
import org.openmicroscopy.ds.dto.UserState;
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
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
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
        if (result == null)
            return null;

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
        if (list == null)
            return;

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
     * Returns a {@link UserState} object for the current session's
     * active user.  The <code>fieldSpec</code> parameter is used to
     * specify which fields in the {@link UserState} object are filled
     * in.
     *
     * @param fieldSpec the fields specification for the returned DTO
     * object
     */
    public UserState getUserState(FieldsSpecification fieldSpec)
    {
        Map fields = fieldSpec.getFieldsWanted();

        Object result = caller.dispatch("getUserState",fields);
        if (result instanceof Map)
        {
            Class dtoClass = RemoteTypes.getDTOClass(UserState.class);
            Map map = (Map) result;
            return (UserState) instantiateDTO(dtoClass,map);
        } else
            throw new RemoteException("Invalid result type "+result.getClass());
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
     * <code>org.openmicroscopy.ds.dto</code> package.  The
     * <code>fieldSpec</code> parameter is used to specifiy which
     * values in the returned DTO object should be filled in.  If the
     * specification instructs the server to return has-ony and
     * has-many references, a tree of objects will be returned.
     *
     * @param targetClass the core data type to count
     * @param id the primary key ID value to retrieve
     * @param fieldSpec the fields specification for the returned DTO
     * object
     * @return the DTO object matching with the given primary key ID
     */
    public DataInterface load(Class targetClass, int id,
                              FieldsSpecification fieldSpec)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map fields = fieldSpec.getFieldsWanted();

        Object result = caller.dispatch("loadObject",
                                        new Object[] {
                                            remoteType,
                                            new Integer(id),
                                            fields
                                        });
        if (result == null)
        {
            return null;
        } else if (result instanceof Map) {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            Map map = (Map) result;
            return instantiateDTO(dtoClass,map);
        } else {
            throw new RemoteException("Invalid result type "+result.getClass());
        }
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
    public DataInterface retrieve(Class targetClass, Criteria criteria)
    {
        String remoteType = RemoteTypes.getRemoteType(targetClass);
        Map crit = createCriteriaMap(criteria);
        Map fields = criteria.getFieldsWanted();

        Object result = caller.dispatch("retrieveObject",
                                        new Object[] {remoteType,crit,fields});
        if (result == null)
        {
            return null;
        } else if (result instanceof Map) {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            Map map = (Map) result;
            return instantiateDTO(dtoClass,map);
        } else {
            throw new RemoteException("Invalid result type "+result.getClass());
        }
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
        if (result == null)
        {
            return null;
        } else if (result instanceof List) {
            Class dtoClass = RemoteTypes.getDTOClass(targetClass);
            List list = (List) result;
            instantiateDTOList(dtoClass,list);
            return list;
        } else {
            throw new RemoteException("Invalid result type "+result.getClass());
        }
    }

    /**
     * Creates an empty instance of the specified data interface.
     * This method is used to create new data objects; after receiving
     * the empty instance, the object's mutators should be used to
     * fill in its fields.  After this, calling the {@link #update}
     * method with this object will save it to the database.
     */
    public DataInterface createNew(Class targetClass)
    {
        Class dtoClass = RemoteTypes.getDTOClass(targetClass);
        Map emptyMap = new HashMap();
        return instantiateDTO(dtoClass,emptyMap);
    }

    /**
     * <p>Sends a DTO back to the data server to be saved.  The DTO
     * must have been instantiated by the {@link #createNew}, {@link
     * #retrieve}, or {@link #retrieveList} methods.  If not, an
     * {@link IllegalArgumentException} is thrown.  If the DTO was
     * created by {@link #createNew}, then the update will cause a
     * database <code>INSERT</code>; otherwise it will cause a
     * database <code>UPDATE</code>.</p>
     *
     * <p>The DTO objects do not have to ability for their {@link
     * List} accessor to be modified, so those has-many relationships
     * cannot be modified by this method.  One-to-many relationships
     * can be modified by editing and updating the DTO on the inverse
     * side of the relationship.  Many-to-many relationships must be
     * updated by one of the specialized methods in the {@link
     * ProjectManager}, {@link DatasetManager}, or {@link
     * ImageManager} classes.</p>
     *
     * <p>Note that this is not a deep update.  If any of the DTO's
     * fields are references to another DTO, then the reference is
     * updated.  If the referent DTO has also been modified or is new,
     * <i>it is not saved</i>.</p>
     *
     * <p>After the object is saved to the database, the database
     * transaction is committed.  If multiple objects needs to be
     * saved atomically, use the {@link #updateList} method.</p>
     *
     * @param object the data object to save to the database
     * @throws IllegalArgumentException if the object was not created
     * by the {@link #createNew}, {@link #retrieve}, or {@link
     * #retrieveList} method
     */
    public void update(DataInterface object)
    {
        if (object == null)
            return;

        if (!(object instanceof MappedDTO))
            throw new IllegalArgumentException("That DTO was not created by createNew or retrieve");

        String remoteType = object.getDTOTypeName();

        Map serialized = new HashMap();
        Map elements = ((MappedDTO) object).getMap();
        Iterator keys = elements.keySet().iterator();
        while (keys.hasNext())
        {
            Object key = keys.next();
            Object element = elements.get(key);

            if (element == null)
            {
            }
        }
    }

    /**
     * <b>Coming soon</b>: Sends a list of DTO's back to the data
     * server to be stored in the database.
     */
    public void updateList(List list)
    {
        //String remoteType = RemoteTypes.getRemoteType(targetClass);
    }
}
