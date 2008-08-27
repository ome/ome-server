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
import java.util.Iterator;

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

    public Map getFieldsWanted() { return fieldsWanted; }

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
     * Adds a {@link FieldsSpecification} of fields which will be
     * accessible in the returned objects.
     */
    public void addWantedFields(FieldsSpecification fields)
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

    /**
     * Adds a {@link FieldsSpecification} of fields which will be
     * accessible in the returned objects.
     */
    public void addWantedFields(String baseHasMany,
                                FieldsSpecification fields)
    {
        // Normalize the base strings so that the concatenation inside
        // of the while loop works properly.

        if (baseHasMany.equals("."))
            baseHasMany = "";
        else if (!baseHasMany.endsWith("."))
            baseHasMany += ".";

        Iterator it = fields.fieldsWanted.entrySet().iterator();

        while (it.hasNext())
        {
            Map.Entry entry = (Map.Entry) it.next();

            // Concatenate the base hasMany with the local hasMany.
            // The normalization above will ensure that the result is
            // one of the following:
            //
            //    1. "."
            //    2. [base]..
            //    3. [base].[local] (with no extra periods)
            //
            // Case 2 requires one extra step of modification, to
            // remove the extra periods.  Cases 1 and 3 require no
            // extra modification.

            String localHasMany = (String) entry.getKey();
            String hasMany = baseHasMany+localHasMany;
            if (hasMany.endsWith(".."))
                hasMany = hasMany.substring(0,hasMany.length()-2);

            List list = (List) entry.getValue();
            List myList = (List) fieldsWanted.get(hasMany);
            if (myList == null)
            {
                myList = new ArrayList(list.size());
                fieldsWanted.put(hasMany,myList);
            }
            myList.addAll(list);
        }
    }

    public void printSpecification()
    {
        Iterator it = fieldsWanted.entrySet().iterator();

        System.err.println();
        while (it.hasNext())
        {
            Map.Entry entry = (Map.Entry) it.next();

            String hasMany = (String) entry.getKey();
            List list = (List) entry.getValue();
            Iterator lit = list.iterator();

            while (lit.hasNext())
            {
                String field = (String) lit.next();
                String fullField =
                    hasMany.equals(".")? field: hasMany+"."+field;
                System.err.println(fullField);
            }
        }
    }
}
