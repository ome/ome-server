/*
 * org.openmicroscopy.ds.RemoteCaller
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds;

/**
 * Provides an interface for making generic RPC calls.  Currently, the
 * only implementation of this interface is the {@link XmlRpcCaller}
 * class.  If, at some point in the future, the transport protocol of
 * the remote framework changes, that should be the only class which
 * needs rewriting.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public interface RemoteCaller
    extends DataService
{
    public void login(String username, String password);

    public void logout();

    public String getSessionKey();

    /**
     * Invoke an arbitrary remote procedure.
     */
    public Object invoke(String procedure, Object[] params);

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.
     */
    public Object dispatch(String method, Object[] params);

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.  The
     * method is expected to return a result which can be somehow
     * typecast into an {@link Integer}.  If it can't, a {@link
     * RemoteServerErrorException} is thrown.
     */
    public Integer dispatchInteger(String method, Object[] params);

    public void startProfiler();
    public void stopProfiler();
    public void resetProfiler();
    public long getProfiledMilliseconds();
}
