/*
 * org.openmicroscopy.ds.managers.ModuleRetrievalManager
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


package org.openmicroscopy.ds.managers;

import java.util.List;

import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.Instantiator;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.dto.Module;


/**
 * A Manager for retrieving chains
 * @author Harry Hochheiser (hsh@nih.gov)
 * @version 2.4 <small><i>(Internal:
 *  $Revision$ $Date$)</i></small>
 * @since OME2.4
 */

public class ModuleRetrievalManager
    extends AbstractService
{
	
	protected InstantiatingCaller icaller = null;
    protected Instantiator  instantiator = null;

    public ModuleRetrievalManager() { super(); }
    
    /**
     * Creates a new <code>ChainRetrievalManager</code> which communicates
     * with a data server using the specified {@link RemoteCaller}.
     * This {@link RemoteCaller} is first wrapped in an instance of
     * {@link InstantiatingCaller}.
     */
    public ModuleRetrievalManager(RemoteCaller caller)
    {
        super();
        initializeService(DataServices.getInstance(caller));
    }
    
    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        icaller = (InstantiatingCaller)
            services.getService(InstantiatingCaller.class);
        instantiator = icaller.getInstantiator();
    }

    /**
     * Retrieve all of the modules in the database
     * @return A list of module objects
     */
    public List retrieveModules() {
        return icaller.dispatchList(Module.class,"retrieveModules",
        			null);
    }
}