/*
 * org.openmicroscopy.ds.managers.AbstractManager
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds;

/**
 * The abstract superclass of all data service classes which perform
 * medium- to high-level interactions with the remote server.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class AbstractManager
{
    protected InstantiatingCaller caller;

    /**
     * Creates a new <code>AbstractManager</code> which communicates
     * with a data server using the specified {@link RemoteCaller}.
     * This {@link RemoteCaller} is first wrapped in an instance of
     * {@link InstantiatingCaller}.
     */
    public AbstractManager(RemoteCaller caller)
    {
        super();
        this.caller = new InstantiatingCaller(caller);
    }

    /**
     * Creates a new <code>AbstractManager</code> which communicates
     * with a data server using the specified {@link
     * InstantiatingCaller}.
     */
    public AbstractManager(InstantiatingCaller caller)
    {
        super();
        this.caller = caller;
    }

    /**
     * Returns the {@link RemoteCaller} used by this data factory.
     * @return the {@link RemoteCaller} used by this data factory.
     */
    public RemoteCaller getRemoteCaller()
    { return caller.getRemoteCaller(); }

    /**
     * Returns the {@link InstantiatingCaller} used by this data
     * factory.
     * @return the {@link InstantiatingCaller} used by this data
     * factory.
     */
    public InstantiatingCaller getInstantiatingCaller() { return caller; }

}