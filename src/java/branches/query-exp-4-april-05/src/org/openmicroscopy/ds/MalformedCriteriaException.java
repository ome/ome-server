/*
 * org.openmicroscopy.ds.MalformedCriteriaException
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

/**
 * Signifies an invalid criteria.  All of the criteria-building
 * methods in {@link Criteria} throw this exception if the result of
 * the method call would be an invalid criteria.  Examples of invalid
 * criteria are if two limits are specified, or if a filter is added
 * for a non-existing field.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class MalformedCriteriaException
    extends RuntimeException
{
    /**
     * Constructs a <code>MalformedCriteriaException</code> with no
     * detail message.
     */
    public MalformedCriteriaException() { super(); }

    /**
     * Constructs a <code>MalformedCriteriaException</code> with the
     * specified detail message.
     * @param msg the detail message
     */
    public MalformedCriteriaException(String msg) { super(msg); }
}
