/*
 * org.openmicroscopy.ds.DataFactory
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
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.ds.dto.DataInterface;
import org.openmicroscopy.ds.dto.SemanticType;
import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.UserState;
import org.openmicroscopy.ds.dto.MappedDTO;
import org.openmicroscopy.ds.dto.AttributeDTO;

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
    extends AbstractService
{
    protected InstantiatingCaller icaller = null;

    private List markedForUpdate = new ArrayList();

    private static class EqualsWrapper
    {
        private DataInterface ref;

        private EqualsWrapper(DataInterface ref)
        {
            super();
            this.ref = ref;
        }

        public boolean equals(Object o)
        {
            if (o instanceof EqualsWrapper)
            {
                EqualsWrapper ew = (EqualsWrapper) o;
                return ref == ew.ref;
            } else {
                return ref == o;
            }
        }
    }

    public DataFactory()
    {
        super();
    }

    /**
     * Creates a new <code>DataFactory</code> which communicates with
     * a data server using the specified {@link RemoteCaller}.  This
     * {@link RemoteCaller} is first wrapped in an instance of {@link
     * InstantiatingCaller}.
     */
    public DataFactory(RemoteCaller caller)
    {
        super();
        initializeService(DataServices.getInstance(caller));
    }

    /**
     * Creates a new <code>DataFactory</code> which communicates with
     * a data server using the specified {@link InstantiatingCaller}.
     */
    public DataFactory(InstantiatingCaller caller)
    {
        super();
        initializeService(DataServices.
                          getInstance(caller.getRemoteCaller()));
    }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        icaller = (InstantiatingCaller)
            services.getService(InstantiatingCaller.class);
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
        return (UserState)
            icaller.dispatch(UserState.class,
                             "getUserState",
                             new Object[] { fields });
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
        Integer result = caller.
            dispatchInteger("countObjects",
                            new Object[] {
                                remoteType,
                                crit
                            });
        if (result == null)
            return 0;
        else
            return result.intValue();
    }

    /**
     * Returns the number of attributes in the database which match
     * the given criteria.  This version of the method is used to
     * count semantically typed attributed; the semantic type desired
     * should be specified by the <code>semanticType</code> parameter.
     * The semantic type parameter should have its <code>name</code>
     * parameter loaded, otherwise a {@link DataException} will be
     * thrown.  Since no objects are actually retrieved from the
     * database, the fields-wanted, order-by, limit, and offset
     * portions of the <code>criteria</code> are ignored.
     *
     * @param semanticType the semantic type to count
     * @param criteria the search criteria to use
     * @return the number of attributes in the OME database which
     * match the specified criteria
     */
    public int count(SemanticType semanticType, Criteria criteria)
     {
        return count(semanticType.getName(),criteria);
    }

    /**
     * Returns the number of attributes in the database which match
     * the given criteria.  This version of the method is used to
     * count semantically typed attributed; the semantic type desired
     * should be specified by the <code>semanticType</code> parameter.
     * Since no objects are actually retrieved from the database, the
     * fields-wanted, order-by, limit, and offset portions of the
     * <code>criteria</code> are ignored.
     *
     * @param semanticType the semantic type to count
     * @param criteria the search criteria to use
     * @return the number of attributes in the OME database which
     * match the specified criteria
     */
    public int count(String semanticType, Criteria criteria)
    {
        Map crit = createCriteriaMap(criteria);
        Integer result = caller.
            dispatchInteger("countObjects",
                            new Object[] {
                                "@"+semanticType,
                                crit
                            });
        if (result == null)
            return 0;
        else
            return result.intValue();
    }

    /**
     * Retrieves the object in the database with the specified primary
     * key ID.  This version of the method is used to retrieve core
     * data types; the data type desired should be specified by the
     * <code>targetClass</code> parameter.  It should correspond to
     * one of the data interfaces in the
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
        return icaller.dispatch(targetClass,
                                "loadObject",
                                new Object[] {
                                    remoteType,
                                    new Integer(id),
                                    fields
                                });
    }

    /**
     * <p>Retrieves the attribute in the database with the specified
     * primary key ID.  This version of the method is used to retrieve
     * semantically typed attributed; the semantic type desired should
     * be specified by the <code>semanticType</code> parameter.  The
     * semantic type parameter should have its <code>name</code>
     * parameter loaded, otherwise a {@link DataException} will be
     * thrown.  The <code>fieldSpec</code> parameter is used to
     * specifiy which values in the returned DTO object should be
     * filled in.  If the specification instructs the server to return
     * has-ony and has-many references, a tree of objects will be
     * returned.</p>
     *
     * <p>If there is a specific interface defined in the
     * <code>org.openmicroscopy.ds.st</code> package for the specified
     * semantic type, the return value will be an instance of that
     * interface.  If not, it will be an instance of the {@link
     * Attribute} interface.</p>
     *
     * @param semanticType the semantic typo to count
     * @param id the primary key ID value to retrieve
     * @param fieldSpec the fields specification for the returned DTO
     * object
     * @return the DTO object matching with the given primary key ID
     */
    public Attribute load(SemanticType semanticType, int id,
                          FieldsSpecification fieldSpec)
    {
        return load(semanticType.getName(),id,fieldSpec);
    }

    /**
     * <p>Retrieves the attribute in the database with the specified
     * primary key ID.  This version of the method is used to retrieve
     * semantically typed attributed; the semantic type desired should
     * be specified by the <code>semanticType</code> parameter.  The
     * <code>fieldSpec</code> parameter is used to specifiy which
     * values in the returned DTO object should be filled in.  If the
     * specification instructs the server to return has-ony and
     * has-many references, a tree of objects will be returned.</p>
     *
     * <p>If there is a specific interface defined in the
     * <code>org.openmicroscopy.ds.st</code> package for the specified
     * semantic type, the return value will be an instance of that
     * interface.  If not, it will be an instance of the {@link
     * Attribute} interface.</p>
     *
     * @param semanticType the semantic typo to count
     * @param id the primary key ID value to retrieve
     * @param fieldSpec the fields specification for the returned DTO
     * object
     * @return the DTO object matching with the given primary key ID
     */
    public Attribute load(String semanticType, int id,
                          FieldsSpecification fieldSpec)
    {
        Map fields = fieldSpec.getFieldsWanted();
        return icaller.dispatch(semanticType,
                                "loadObject",
                                new Object[] {
                                    "@"+semanticType,
                                    new Integer(id),
                                    fields
                                });
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
        return icaller.dispatch(targetClass,
                                "retrieveObject",
                                new Object[] {remoteType,crit,fields});
    }

    public Attribute retrieve(SemanticType semanticType, Criteria criteria)
    {
        return retrieve(semanticType.getName(),criteria);
    }

    public Attribute retrieve(String semanticType, Criteria criteria)
    {
        Map crit = createCriteriaMap(criteria);
        Map fields = criteria.getFieldsWanted();
        return icaller.dispatch(semanticType,
                                "retrieveObject",
                                new Object[] {
                                    "@"+semanticType,
                                    crit,
                                    fields
                                });
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
        return icaller.dispatchList(targetClass,
                                    "retrieveObjects",
                                    new Object[] {remoteType,crit,fields});
    }

    public List retrieveList(SemanticType semanticType, Criteria criteria)
    {
        return retrieveList(semanticType.getName(),criteria);
    }

    public List retrieveList(String semanticType, Criteria criteria)
    {
        Map crit = createCriteriaMap(criteria);
        Map fields = criteria.getFieldsWanted();
        return icaller.dispatchList(semanticType,
                                    "retrieveObjects",
                                    new Object[] {
                                        "@"+semanticType,
                                        crit,
                                        fields
                                    });
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
        MappedDTO dto = icaller.getInstantiator().
            instantiateDTO(targetClass,new HashMap());
        dto.setNew(true);
        return dto;
    }

    public Attribute createNew(SemanticType semanticType)
    {
        return createNew(semanticType.getName());
    }

    public Attribute createNew(String semanticType)
    {
        MappedDTO dto = icaller.getInstantiator().
            instantiateDTO(semanticType,new HashMap());
        dto.setNew(true);
        return (Attribute) dto;
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
    private Map serializeForUpdate(MappedDTO dto, Map newIDs)
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
     * org.openmicroscopy.ds.managers.ProjectManager} and {@link
     * org.openmicroscopy.ds.managers.DatasetManager}.</p>
     *
     * <p>New objects which are being saved to the database for the
     * first time will have their ID field (<code>id</code>) filled in
     * with the object's new primary key.</p>
     *
     * <p>Note that this is not a deep update.  If any of the DTO's
     * fields are references to another DTO, then the reference is
     * updated.  The referent DTO must already be in the database, and
     * have a valid primary key ID.  If it is a new object, it must
     * have been saved previously.  If the referent DTO has been
     * modified, <i>it is not saved</i>.</p>
     *
     * <p>After the object is saved to the database, the database
     * transaction is committed.  If multiple objects needs to be
     * saved atomically, use the {@link #updateList} method.</p>
     *
     * @param object the data object to save to the database
     * @throws IllegalArgumentException if the object was not created
     * by the {@link #createNew}, {@link #retrieve}, or {@link
     * #retrieveList} method
     * @throws DataException if the object contains a reference to a
     * DTO which is new (i.e., which has not been stored in the
     * database yet), or to a DTO which does not contain its primary
     * key value
     */
    public void update(DataInterface object)
    {
        if (object == null)
            return;

        // Verify that this is a MappedDTO

        if (!(object instanceof MappedDTO))
            throw new IllegalArgumentException("That DTO was not created by createNew, retrieve, or retrieveList");

        // Serialize the DTO

        MappedDTO dto = (MappedDTO) object;
        Map serialized = serializeForUpdate(dto,null);

        // Make the remote call

        String remoteType = object.getDTOTypeName();
        Object result = caller.
            dispatch("updateObject",new Object[] { remoteType,serialized });

        // If this was a new object, we should have gotten back a
        // primary key ID

        int realID = -1;

        if (result == null)
        {
        } else if (result instanceof Number) {
            realID = ((Number) result).intValue();
        } else if (result instanceof String) {
            realID = Integer.parseInt((String) result);
        } else {
            throw new RemoteServerErrorException("Server returned an invalid type "+
                                                 result.getClass());
        }

        // If the object was new, save the ID that was returned from
        // the remote server

        if (dto.isNew())
        {
            if (realID < 0)
                throw new RemoteServerErrorException("Server did not return an ID for the new object");

            dto.setNew(false);
            dto.getMap().put("id",new Integer(realID));
        }
    }

    /**
     * <p>Sends a list of DTO's back to the data server to be saved.
     * Each DTO must have been instantiated by the {@link #createNew},
     * {@link #retrieve}, or {@link #retrieveList} methods.  If not,
     * an {@link IllegalArgumentException} is thrown.  If a DTO was
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
     * org.openmicroscopy.ds.managers.ProjectManager} or {@link
     * org.openmicroscopy.ds.managers.DatasetManager} classes.
     *
     * <p>New objects which are being saved to the database for the
     * first time will have their ID field (<code>id</code>) filled in
     * with the object's new primary key.</p>
     *
     * <p>Note that this is not a deep update.  If any of the DTO's
     * fields are references to another DTO, then the reference is
     * updated.  The referent DTO must already be in the database, and
     * have a valid primary key ID.  If it is a new object, it must
     * have been saved previously.  If the referent DTO has been
     * modified, <i>it is not saved</i>.</p>
     *
     * <p>The objects are saved in the order that they appear in the
     * list.  This has implications on the restrictions of the
     * previous paragraph.  New objects can appear as a reference in a
     * DTO, as long as the new object appears in before the referring
     * DTO in this method's <code>list</code> parameter.</p>
     *
     * <p>After the objects are saved to the database, the database
     * transaction is committed.</p>
     *
     * @param list a list of data objects to save to the database
     * @throws IllegalArgumentException if any object was not created
     * by the {@link #createNew}, {@link #retrieve}, or {@link
     * #retrieveList} method
     * @throws DataException if the object contains a reference to a
     * DTO which is new (i.e., which has not been stored in the
     * database yet), or to a DTO which does not contain its primary
     * key value
     */
    public void updateList(List list)
    {
        if (list == null)
            return;

        List serialized = new ArrayList(list.size()*2);
        Iterator iter;

        Map newIDs = new HashMap();
        int nextNew = 1;

        // First we must go through verify that each object is a
        // MappedDTO and assign new-IDs to each of the new objects in
        // the list.

        iter = list.iterator();
        while (iter.hasNext())
        {
            Object object = iter.next();

            // Verify that this is a DTO that we know how to save
            if (!(object instanceof MappedDTO))
                throw new IllegalArgumentException("That DTO was not created by createNew, retrieve, or retrieveList");

            MappedDTO dto = (MappedDTO) object;
            if (dto.isNew())
            {
                int newID = nextNew++;
                System.err.println("New object "+dto.getClass().getName()+" "+newID);
                newIDs.put(dto,"NEW:"+newID);
            }
        }

        // Now we go through and serialize the DTO's.  We can't do
        // this in one pass because we have to know all of the
        // new-ID's before we can serialize anything.

        iter = list.iterator();
        while (iter.hasNext())
        {
            MappedDTO dto = (MappedDTO) iter.next();
            serialized.add(dto.getDTOTypeName());
            serialized.add(serializeForUpdate(dto,newIDs));
        }

        // Make the remote call

        Object result = caller.
            dispatch("updateObjects",new Object[] { serialized });

        // We should get back a map of the primary key ID's for each
        // of the objects which was new.

        Map realIDs;

        if (result == null)
        {
            realIDs = new HashMap();
        } else if (result instanceof Map) {
            realIDs = (Map) result;
        } else {
            throw new RemoteServerErrorException("Server returned an invalid type "+
                                                 result.getClass());
        }

        // Go through each of the new objects, and populate it with
        // its actual primary key ID.

        iter = newIDs.keySet().iterator();
        while (iter.hasNext())
        {
            MappedDTO newObject = (MappedDTO) iter.next();
            String newID = (String) newIDs.get(newObject);
            Object realID = realIDs.get(newID);

            if (realID == null)
                throw new RemoteServerErrorException("Server did not return an ID for the new object "+newID);

            newObject.setNew(false);
            newObject.getMap().put("id",realID);
        }
    }

    public void markForUpdate(DataInterface object)
    {
        if (!markedForUpdate.contains(object))
            markedForUpdate.add(new EqualsWrapper(object));
    }

    public void updateMarked()
    {
        for (int i = 0; i < markedForUpdate.size(); i++)
        {
            EqualsWrapper ew = (EqualsWrapper) markedForUpdate.get(i);
            markedForUpdate.set(i,ew.ref);
        }

        updateList(markedForUpdate);

        markedForUpdate.clear();
    }
}
