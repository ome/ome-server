/*
 * org.openmicroscopy.ds.FieldsSpecification
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

import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

/**
 * <p>Defines fields specifications for use with the {@link
 * DataFactory} class.  These two classes, along with the {@link
 * Criteria} class, provide the ability to retrieve arbitrary data
 * objects from an OME data server.</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class FieldsSpecification
{
    private Map  fieldsWanted = new HashMap();

    /**
     * Creates a new <code>FieldsSpecification</code> object.
     */
    public FieldsSpecification()
    {
        super();
    }

    Map getFieldsWanted() { return fieldsWanted; }

    /**
     * Adds a field which will be accessible in the returned objects.
     */
    public void addWantedField(String field)
    {
        addWantedField(".",field);
    }

    /**
     * Adds an array of fields which will be accessible in the
     * returned objects.
     */
    public void addWantedFields(String[] fields)
    {
        addWantedFields(".",fields);
    }

    /**
     * Adds a {@link List} of fields which will be accessible in the
     * returned objects.
     */
    public void addWantedFields(List fields)
    {
        addWantedFields(".",fields);
    }

    /**
     * Adds a field which will be accessible in an object in the
     * specified has-many field.
     */
    public void addWantedField(String hasMany, String field)
    {
        List list = (List) fieldsWanted.get(hasMany);
        if (list == null)
        {
            list = new ArrayList();
            fieldsWanted.put(hasMany,list);
        }

        list.add(field);
    }

    /**
     * Adds an array of fields which will be accessible in an object
     * in the specified has-many field.
     */
    public void addWantedFields(String hasMany, String[] fields)
    {
        List list = (List) fieldsWanted.get(hasMany);
        if (list == null)
        {
            list = new ArrayList(Arrays.asList(fields));
            fieldsWanted.put(hasMany,list);
        } else {
            list.addAll(Arrays.asList(fields));
        }
    }

    /**
     * Adds a {@link List} of fields which will be accessible in an
     * object in the specified has-many field.
     */
    public void addWantedFields(String hasMany, List fields)
    {
        List list = (List) fieldsWanted.get(hasMany);
        if (list == null)
        {
            list = new ArrayList(fields);
            fieldsWanted.put(hasMany,list);
        } else {
            list.addAll(fields);
        }
    }

}