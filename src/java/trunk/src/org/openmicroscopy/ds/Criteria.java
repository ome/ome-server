/*
 * org.openmicroscopy.ds.Criteria
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

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.ds.dto.MappedDTO;

/**
 * <p>Defines search criteria for use with the {@link DataFactory}
 * class.  These two classes provide the ability to retrieve arbitrary
 * data objects from an OME data server.</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class Criteria
    extends FieldsSpecification
{
    private Map  criteria = new HashMap();
    private List  orderBy = new ArrayList();
    private int  limit = -1;
    private int  offset = -1;

    /**
     * Creates a new <code>Criteria</code> object.
     */
    public Criteria()
    {
        super();
    }

    Map getCriteria() { return criteria; }
    List getOrderBy() { return orderBy; }
    int getLimit() { return limit; }
    int getOffset() { return offset; }

    private Object normalizeValue(Object value)
    {
        if (value instanceof MappedDTO)
            return ((MappedDTO) value).getMap().get("id");
        else
            return value;
    }

    /**
     * Adds a <code>WHERE</code> clause to this criteria; only objects
     * which have the specified value for the specified column will
     * match.
     */
    public void addFilter(String column, Object value)
    {
        criteria.put(column,normalizeValue(value));
    }

    /**
     * Adds a <code>WHERE</code> clause to this criteria using the
     * specified SQL operator.  If the <code>IN</code> operator is
     * used, then the <code>value</code> must be a {@link List}.
     */
    public void addFilter(String column, String operator, Object value)
    {
        List list = new ArrayList(2);
        list.add(operator);
        list.add(normalizeValue(value));
        criteria.put(column,list);
    }

    /**
     * Adds an <code>ORDER BY</code> clause to the criteria.
     */
    public void addOrderBy(String column)
    {
        orderBy.add(column);
    }

    /**
     * Adds a <code>LIMIT</code> clause to the criteria.  This limits
     * the number of rows which will be returned to the specified
     * value.  This clause is mostly useless without an <code>ORDER
     * BY</code> clause, too.
     */
    public void setLimit(int limit)
    {
        this.limit = limit;
    }

    /**
     * Adds a <code>OFFSET</code> clause to the criteria.  This causes
     * the query to skip the specified number of rows.  This clause is
     * mostly useless without an <code>ORDER BY</code> clause, too.
     */
    public void setOffset(int offset)
    {
        this.offset = offset;
    }

}
