/*
 * org.openmicroscopy.ds.RemoteException
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
 * <p>Signifies any problem in the remote communication with the OME
 * data server.  There are three classes on remote exception, each
 * represented by a distinct subclass of
 * <code>RemoteException</code>:</p>
 *
 * <ol>
 *
 * <li>Errors establishing or maintaining a physical connection to the
 * remote server. ({@link RemoteConnectionException})</li>
 *
 * <li>Errors authenticating the user with the remote server.  This
 * can happen when logging in due to an invalid username or password,
 * or during later method calls due to an expired session.  ({@link
 * RemoteAuthenticationException})</li>
 *
 * <li>Runtime errors in the server-side code executed by the data
 * server. ({@link RemoteServerErrorException})</li>
 *
 * </ol>
 *
 * <p>Code using the remote framework can check for all of these
 * exception at once by catching the <code>RemoteException</code>
 * class, or it can check for each class of error separately by
 * catching the subclasses.</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class RemoteException
    extends RuntimeException
{
    /**
     * Constructs a <code>RemoteException</code> with no detail
     * message.
     */
    public RemoteException() { super(); }

    /**
     * Constructs a <code>RemoteException</code> with the specified
     * detail message.
     * @param msg the detail message
     */
    public RemoteException(String msg) { super(msg); }
}
