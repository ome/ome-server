/*
 * org.openmicroscopy.OMEObject
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




package org.openmicroscopy;

/**
 * The superclass of all non-attribute OME classes.  It declares the
 * methods available to all OME-controlled objects.
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 * @see Attribute
 */

public interface OMEObject
{
    /**
     * Returns the primary key ID of this object.
     * @return the primary key ID of this object.
     */
    public int getID();

    /**
     * Saves this object's state to the OME database and commits any
     * active database transaction.
     */
    public void writeObject();

    /**
     * Returns the OME session that generated this object.
     * @return the OME session that generated this object.
     * @see Session
     */
    public Session getSession();
}
