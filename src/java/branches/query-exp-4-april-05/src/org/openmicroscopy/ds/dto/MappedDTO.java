/*
 * org.openmicroscopy.ds.dto.MappedDTO
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




package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.DataException;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.PrimitiveConverters;
import java.util.List;
import java.util.Map;

/**
 * <p>Provides a base implementation of the remote framework DTO
 * classes, backed by a {@link Map}.  Helper methods are provided to
 * retrieve values of specific types from the map.  These methods
 * perform any necessary type-conversions automatically, if possible.
 * In almost all cases, the accessors of the DTO classes only need to
 * delegate to the appropriate helper accessor, called with the
 * appropriate key value.</p>
 *
 * <p>Helper methods are also provided to aid in the parsing of the
 * results of the XML-RPC calls which generate the DTO's.  In the
 * simplest cases, the result of the XML-RPC call is a
 * <code>struct</code> which is suitable to be used directly as the
 * map backing the DTO.  In the more complex cases, though, the helper
 * methods must be used, for instance, to translate the contents of a
 * sublist into the appropriate DTO's.</p>
 * 
 * <p>Requests for fields that are not populated return a "null" response. 
 * This is a departure from earlier code that threw an exception in such cases. 
 * This revision simplifies handlling - allowing the back-end to be more flexible in
 * what is returned, but places more of a burden on the client. Specifically, 
 * clients can no longer distinguish between values that have not been retrieved 
 * and those that do not exist. If this becomes a problem, the excpetion-throwing
 * behavior should be restored.</p>
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public abstract class MappedDTO
    implements DataInterface
{
	
	public static final String  NULL_REFERENCE = "*([-NULL-])*";
	 
    /**
     * This is the {@link Map} used to back the DTO.  All of the data
     * fields of the DTO are stored in the map.  The helper accessor
     * and mutator methods access values in this map.
     */
    protected Map elements;

    /**
     * Indicates whether this object is tainted.  A tainted object is
     * one that has had at least one of its fields modified since it
     * was read from or saved to the database.
     */
    protected boolean tainted;

    /**
     * Indicates whether this object is new.  A new object is one that
     * was created in Java client code and has not been saved to the
     * database yet.
     */
    protected boolean newObject;

    /**
     * Creates a new <code>MappedDTO</code> without an initialized
     * backing map.  Obviously, the new instance won't be useful until
     * it is provided with a backing map via the {@link #setMap}
     * method.
     */
    protected MappedDTO()
    {
        super();
        this.elements = null;
    }

    /**
     * Creates a new <code>MappedDTO</code> with the specified backing
     * map.  This map is usually the result of an XML-RPC call.
     */
    protected MappedDTO(Map elements)
    {
        super();
        setMap(elements);
    }

    // Javadoc inherited from DataInterface
    public abstract String getDTOTypeName();

    // Javadoc inherited from DataInterface
    public abstract Class getDTOType();

    /**
     * Returns a String representation of this DTO.
     */
    public String toString()
    {
        String result = getDTOTypeName();
        if (elements.containsKey("id"))
            result = "["+result+":"+elements.get("id").toString()+"]";
        else
            result = "["+result+":unknown ID]";

        return result;
    }

    /**
     * Compares to DTO's for equality.  Two DTO's are equal if they
     * have the same object type and primary key ID.  If a DTO did not
     * have its primary key ID loaded, it is considered unequal to
     * every other DTO.
     */
    public boolean equals(Object o)
    {
        if (o instanceof MappedDTO)
            return equals((MappedDTO) o);
        else
            return false;
    }

    /**
     * Compares to DTO's for equality.  Two DTO's are equal if they
     * have the same object type and primary key ID.  If a DTO did not
     * have its primary key ID loaded, it is considered unequal to
     * every other DTO.
     */
    public boolean equals(MappedDTO o)
    {
        if (o == this)
            return true;

        if (!getDTOTypeName().equals(o.getDTOTypeName()))
            return false;

        if (!elements.containsKey("id"))
            return false;

        if (!o.elements.containsKey("id"))
            return false;

        return getIntegerElement("id").equals(o.getIntegerElement("id"));
    }

    /**
     * Returns a hash code for this DTO.  The hash code is constructed
     * by returning the hash code of the object's {@link #toString}
     * representation.
     */
    public int hashCode()
    {
        return toString().hashCode();
    }

    /**
     * Returns the backing map for this instance.
     */
    public Map getMap() { return elements; }

    /**
     * <p>Establishes a new backing map for this instance.  The
     * previous backing map is discarded.  Subclasses should override
     * this method to post-process the backing map, if necessary.
     * (For instance, if one of the elements in the map is a list of
     * children objects, this method should be overridden to call
     * {@link #parseListElement} to parse that list into Java
     * objects.)</p>
     *
     * <p>This method is called implicitly during the creation of a
     * DTO object by the {@link DataFactory} class, and should
     * almost never be called directly.</p>
     */
    public void setMap(Map elements) { this.elements = elements; }

    /**
     * Returns whether this object is tainted.  A tainted object is
     * one that has had at least one of its fields modified since it
     * was read from or saved to the database.
     */
    public boolean isTainted() { return tainted; }

    /**
     * Sets the tainted flag for this DTO.  This method should be
     * called by each and every mutator method in subclasses to mark
     * the object as being tainted.  It should almost never be called
     * directly.
     */
    public void setTainted(boolean tainted) { this.tainted = tainted; }

    /**
     * Returns whether this object is new.  A new object is one that
     * was created in Java client code and has not been saved to the
     * database yet.
     */
    public boolean isNew() { return newObject; }

    /**
     * Sets the new object flag for this DTO.  This method will be
     * called automatically by the {@link DataFactory#createNew}
     * method, and should never be called directly.
     */
    public void setNew(boolean newObject) { this.newObject = newObject; }

    /**
     * Helper method for parsing an element which is a child object.
     * This will turn the <code>struct</code> into an instance of the
     * specified DTO class.  (This class must be a subclass of {@link
     * MappedDTO}.)  If the element specified doesn't exist in this
     * DTO (because it wasn't filled in by the XML-RPC method which
     * created this DTO), then nothing happens.
     */
    protected Object parseChildElement(String element, Class dtoClazz)
    {
        // It's an error if the specified class isn't a MappedDTO
        // subclass.
        if (!MappedDTO.class.isAssignableFrom(dtoClazz))
            throw new DataException("Specified class is not a MappedDTO subclass");

        // If the desired element doesn't exist, return silently.
        if (!elements.containsKey(element))
            return null;

        try
        {

            Object o = elements.get(element);
            if (o != null)
            {
                if (dtoClazz.isInstance(o))
                    return o;
		// Strings that match the null reference marker
		// or have zero length
		// should be interpreted as nulls.
                if (o instanceof String && 
               		( (((String) o).compareTo(NULL_REFERENCE) ==0) ||
               		  ((String) o).length() ==0 )){
                		return null;
                }
                else if (!(o instanceof Map))
                    throw new DataException("Illegal type for element "+element);

                Map m = (Map) o;
                MappedDTO dto = (MappedDTO) dtoClazz.newInstance();
                dto.setMap(m);
                elements.put(element,dto);
                return dto;
            }
        } catch (InstantiationException e) {
            throw new DataException("Cannot create instance of "+dtoClazz);
        } catch (IllegalAccessException e) {
            throw new DataException("Cannot create instance of "+dtoClazz);
        }
        return null;
    }

    /**
     * Helper method for parsing an element which is a list.  This
     * will turn the list of <code>struct</code>s into a list of the
     * specified DTO class.  (This class must be a subclass of {@link
     * MappedDTO}.)  If the element specified doesn't exist in this
     * DTO (because it wasn't filled in by the XML-RPC method which
     * created this DTO), then nothing happens.
     */
    protected List parseListElement(String element, Class dtoClazz)
    {
        // It's an error if the specified class isn't a MappedDTO
        // subclass.
        if (!MappedDTO.class.isAssignableFrom(dtoClazz))
            throw new DataException("Specified class is not a MappedDTO subclass");

        // If the desired element doesn't exist, return silently.
        if (!elements.containsKey(element))
            return null;

        try
        {
        		// has it been parsed?
        	   Object obj = elements.get(element);
        	   if (obj instanceof MappedDTOList) 
        	   		return (MappedDTOList) obj;
            
        	   List list = (List) obj;
            MappedDTOList newList = new MappedDTOList();
            for (int i = 0; i < list.size(); i++)
            {
                Object o = list.get(i);
                if (o != null)
                {
                    if (!(o instanceof Map))
                        throw new DataException("Illegal type for element "+
                                                element);

                    Map m = (Map) o;
                    MappedDTO dto = (MappedDTO) dtoClazz.newInstance();
                    dto.setMap(m);
                    newList.add(dto);
                }
            }
            elements.put(element,newList);
            return newList;
        } catch (InstantiationException e) {
            throw new DataException("Cannot create instance of "+dtoClazz);
        } catch (IllegalAccessException e) {
            throw new DataException("Cannot create instance of "+dtoClazz);
        }
    }

    protected int getIntElement(String key)
    {
    	    Integer value = getIntegerElement(key);
        if (value == null)
            throw new DataException(key+" field is null");
        else
            return value.intValue();
    }

    /**
     * Returns an <code>short</code> value from the backing map.  
     * If the value in the backing map is an {@link Short},
     * the <code>short</code> is returned directly.  If the value is a
     * {@link Long}, the <code>long</code> value is cast into an
     * <code>short</code> and returned.  If the value is a {@link
     * Float} or {@link Double}, is it rounded via the {@link
     * Math#round} method, and cast into an <code>short</code>.  If
     * the value is a {@link String} which can be parsed into an
     * <code>short</code>, the parsed value is returned.  In all other
     * cases, an error occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return an <code>short</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into an
     * <code>short</code>
     */
    protected Short getShortElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToShort(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns an <code>int</code> value from the backing map.  
     * If the value in the backing map is an {@link Integer}, the
     * <code>int</code> is returned directly.  If the value is a
     * {@link Long}, the <code>long</code> value is cast into an
     * <code>int</code> and returned.  If the value is a {@link Float}
     * or {@link Double}, is it rounded via the {@link Math#round}
     * method, and cast into an <code>int</code>.  If the value is a
     * {@link String} which can be parsed into an <code>int</code>,
     * the parsed value is returned.  In all other cases, an error
     * occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return an <code>int</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into an
     * <code>int</code>
     */
    protected Integer getIntegerElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToInteger(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns a <code>long</code> value from the backing map.  
     * If the value in the backing map is an {@link Integer} or {@link
     * Long}, the value is returned directly.  If the value is a
     * {@link Float} or {@link Double}, is it rounded via the {@link
     * Math#round} method, and cast into a <code>long</code>.  If the
     * value is a {@link String} which can be parsed into a
     * <code>long</code>, the parsed value is returned.  In all other
     * cases, an error occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return a <code>long</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into a
     * <code>long</code>
     */
    protected Long getLongElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToLong(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns a <code>float</code> value from the backing map.  
     * If the value in the backing map is an {@link Integer}, {@link
     * Long}, {@link Float}, or {@link Double} the value is returned
     * directly, with an appropriate case as necessary.  If the value
     * is a {@link String} which can be parsed into a
     * <code>float</code>, the parsed value is returned.  In all other
     * cases, an error occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return a <code>float</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into a
     * <code>float</code>
     */
    protected Float getFloatElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToFloat(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns a <code>double</code> value from the backing map. 
     * If the value in the backing map is an {@link Integer}, {@link
     * Long}, {@link Float}, or {@link Double} the value is returned
     * directly, with an appropriate case as necessary.  If the value
     * is a {@link String} which can be parsed into a
     * <code>double</code>, the parsed value is returned.  In all other
     * cases, an error occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return a <code>double</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into a
     * <code>double</code>
     */
    protected Double getDoubleElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToDouble(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns a <code>boolean</code> value from the backing map.  
     * If the value in the backing map is a {@link Boolean},
     * the <code>boolean</code> value is returned directly.  If it is
     * an {@link Integer} or {@link Long}, then a <code>false</code>
     * value is returned if the element's value is 0; otherwise
     * <code>true</code> is returned.  If the value is a {@link
     * String}, a <code>true</code> element is returned if the element
     * contains any of the following values (case-insensitive):
     * <code>true</code>, <code>t</code>, <code>yes</code>,
     * <code>y</code>, <code>1</code>.  If it contains any other
     * value, <code>false</code> is returned.  In all other cases, an
     * error occurs.
     *
     * @param key the element of the backing map to retrieve
     * @return a <code>boolean</code> value representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map or if the value cannot be turned into a
     * <code>boolean</code>
     */
    protected Boolean getBooleanElement(String key)
    {
        Object o = elements.get(key);

        try
        {
            return PrimitiveConverters.convertToBoolean(o);
        } catch (NumberFormatException e) {
            throw new DataException(e.getMessage());
        }
    }

    /**
     * Returns a {@link String} value from the backing map. 
     * If the object in the backing map for this key is not a {@link
     * String}, it is transformed into one via the {@link
     * Object#toString} method.
     *
     * @param key the element of the backing map to retrieve
     * @return a {@link String} object representing the specified
     * element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map
     */
    protected String getStringElement(String key)
    {
        Object o = elements.get(key);
        if (o == null)
        		return null;
        String s = o.toString();
        
        if (s.compareTo(NULL_REFERENCE) == 0) { 
        		elements.remove(key);
        		return null;
        }
        return s;
        //return o == null ? null : o.toString();
    }

    /**
     * Returns the value for the specified key.  No type-checking or
     * type-casting is performed; whatever was returned by the XML-RPC
     * layer is returned from this method.  The only error condition
     * is if the key does not exist in the backing map.
     *
     * @param key the element of the backing map to retrieve
     * @return the specified element in the backing map
     * @throws DataException if the specified key does not exist in
     * the backing map
     */
    protected Object getObjectElement(String key)
    {
        return elements.get(key);
    }

    protected void setElement(String key, Object value)
    {
        elements.put(key,value);
        tainted = true;
    }

    /**
     * Returns the number of items for the given key, which must be a
     * {@link List} key.  If the key itself was loaded, the count is
     * retrieved directly from the List via the <code>size</code>
     * method.  If not, a <code>#[key]</code> key is searched for,
     * which should contain the count (allowing the count to be
     * retrieved from the database without reading the entire list).
     * If neither exists, a {@link DataException} is thrown.
     *
     * @param key the List element of the backing map to retrieve
     * @return the number of objects in the list
     * @throws DataException if the specified key does not exist in
     * the backing map
     */
    protected int countListElement(String key)
    {
        if (elements.containsKey(key))
        {
            List list = (List) elements.get(key);
            return list.size();
        } else if (elements.containsKey("#"+key)) {
            Integer count = getIntegerElement("#"+key);
            if (count == null)
                throw new DataException("#"+key+" field is null");
            return count.intValue();
        } else {
            throw new DataException("The "+key+" field was not loaded");
        }
    }

}
