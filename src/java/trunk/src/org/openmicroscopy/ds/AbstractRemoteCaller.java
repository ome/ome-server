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
 * Provides some base functionality common to most {@link
 * RemoteCaller} implementations.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public abstract class AbstractRemoteCaller
    extends AbstractService
    implements RemoteCaller
{
    protected DataServices services;

    /**
     * Creates a new <code>AbstractRemoteCaller</code> instance.
     */
    public AbstractRemoteCaller() { super(); }

    public void initializeService(DataServices services)
    {
        this.services = services;
    }

    public DataServices getDataServices() { return services; }

    ////////////////////////////////////////////////////////////////////
    // All of the following methods are implemented in terms of
    // the abstract dispatch method.

    // inherited Javadoc
    public Integer dispatchInteger(String method, Object[] params)
    {
        Object result = dispatch(method,params);
        try
        {
            return PrimitiveConverters.convertToInteger(result);
        } catch (NumberFormatException e) {
            throw new RemoteServerErrorException("Invalid return type "+
                                                 e.getMessage());
        }
    }
    
}
