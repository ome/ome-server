/*
 * org.openmicroscopy.ds.InstantiatingCaller
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

import org.openmicroscopy.ds.dto.DataInterface;
import org.openmicroscopy.ds.dto.Attribute;

/**
 * Provides an interface for instantiating the results of RPC calls
 * into instances of one of the DTO interfaces.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class InstantiatingCaller
    extends AbstractService
{
    private Instantiator instantiator;

    public InstantiatingCaller()
    {
        super();
    }

    /**
     * Creates a new <code>InstantiatingCaller</code> which
     * communicates with a data server using the specified {@link
     * RemoteCaller}.
     */
    public InstantiatingCaller(RemoteCaller caller)
    {
        super();
        initializeService(DataServices.getInstance(caller));
    }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        this.instantiator = new Instantiator();
    }

    /**
     * Returns the {@link Instantiator} used by this instance.
     * @return the {@link Instantiator} used by this instance.
     */
    public Instantiator getInstantiator() { return instantiator; }

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.  The
     * result is instantiated into an instance of the specified Java
     * DTO interface.  If the result of the remote method call is not
     * a {@link Map}, a {@link RemoteServerErrorException} is thrown.
     * @param javaClass the {@link Class} object for a DTO interface
     * (not implementing class)
     */
    public DataInterface dispatch(Class javaClass,
                                  String method,
                                  Object[] params)
    {
        Object result = caller.dispatch(method,params);
        return instantiator.instantiateDTO(javaClass,result);
    }

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.  The
     * result is instantiated into an instance of the specified
     * semantic type interface.  If the result of the remote method
     * call is not a {@link Map}, a {@link
     * RemoteServerErrorException} is thrown.
     * @param semanticType the name of the semantic type to
     * instantiate (the name of the type, not the interface or
     * implementing class)
     */
    public Attribute dispatch(String semanticType,
                              String method,
                              Object[] params)
    {
        Object result = caller.dispatch(method,params);
        return instantiator.instantiateDTO(semanticType,result);
    }

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.  The
     * result is instantiated into a {@link List} of instances of the
     * specified Java DTO interface.  If the result of the remote
     * method call is not a {@link List}, a {@link
     * RemoteServerErrorException} is thrown.
     * @param javaClass the {@link Class} object for a DTO interface
     * (not implementing class)
     */
    public List dispatchList(Class javaClass,
                             String method,
                             Object[] params)
    {
        Object result = caller.dispatch(method,params);
        return instantiator.instantiateList(javaClass,result);
    }

    /**
     * Invoke a remote method via the <code>dispatch</code> procedure.
     * The method can receive an arbitrary number of parameters.  The
     * result is instantiated into a {@link List} of instances of the
     * specified semantic type interface.  If the result of the remote
     * method call is not a {@link List}, a {@link
     * RemoteServerErrorException} is thrown.
     * @param semanticType the name of the semantic type to
     * instantiate (the name of the type, not the interface or
     * implementing class)
     */
    public List dispatchList(String semanticType,
                             String method,
                             Object[] params)
    {
        Object result = caller.dispatch(method,params);
        return instantiator.instantiateList(semanticType,result);
    }

}