/*
 * org.openmicroscopy.ds.DataException
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
 * Signifies an attempt to read an unpopulated portion of a DTO
 * object.  The methods of the OME remote framework allow you to
 * specify which fields of a retrieved object should be filled in.  If
 * a DTO accessor is called to read a field which was not filled in by
 * the remote framework (or by a subsequent call to the field's
 * mutator), this exception is thrown.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

public class DataException
    extends RuntimeException
{
    /**
     * Constructs a <code>DataException</code> with no detail message.
     */
    public DataException() { super(); }

    /**
     * Constructs a <code>DataException</code> with the specified
     * detail message.
     * @param msg the detail message
     */
    public DataException(String msg) { super(msg); }
}
