/*
 * org.openmicroscopy.ds.managers.HistoryManager
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
import org.openmicroscopy.ds.DataException;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.Instantiator;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.dto.ChainExecution;
import org.openmicroscopy.ds.dto.ModuleExecution;


/**
 * A Manager for retrieving data histories for Mexes
 * @author Harry Hochheiser (hsh@nih.gov)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class HistoryManager
    extends AbstractService
{
	
	protected InstantiatingCaller icaller = null;
    protected Instantiator  instantiator = null;

    public HistoryManager() { super(); }
    
    /**
     * Creates a new <code>HistoryManager</code> which communicates
     * with a data server using the specified {@link RemoteCaller}.
     * This {@link RemoteCaller} is first wrapped in an instance of
     * {@link InstantiatingCaller}.
     */
    public HistoryManager(RemoteCaller caller)
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

    public List getMexDataHistory(ModuleExecution mex) 
    {
        if (mex == null)
            throw new IllegalArgumentException("Module execution cannot be null");
        
        Integer mexID = null;

        try
        {
            mexID = new Integer(mex.getID());
        } catch (DataException e) {
            throw new IllegalArgumentException("Module execution must be in the database");
        }
        
        return getMexDataHistory(mexID);
    }
    
    public List getMexDataHistory(Integer mexID) {
        return icaller.dispatchList(ModuleExecution.class,"getMexDataHistory",
                    new Object[] {
                        mexID
                    });
    }
    
    
    public List getMexDataHistory(ModuleExecution mex,
    			FieldsSpecification spec) 
    {
        if (mex == null)
            throw new IllegalArgumentException("Module execution cannot be null");
        
        Integer mexID = null;

        try
        {
            mexID = new Integer(mex.getID());
        } catch (DataException e) {
            throw new IllegalArgumentException("Module execution must be in the database");
        }
        
        return getMexDataHistory(mexID,spec);
    }
    
    public List getMexDataHistory(Integer mexID,FieldsSpecification spec) {
        return icaller.dispatchList(ModuleExecution.class,"getMexDataHistory",
                    new Object[] {
                        mexID,
					   spec
                    });
    }
    
    
    public List getChainDataHistory(ChainExecution chex) 
    {
        if (chex == null)
            throw new IllegalArgumentException("Chain execution cannot be null");
        
        Integer chexID = null;

        try
        {
            chexID = new Integer(chex.getID());
        } catch (DataException e) {
            throw new 
			IllegalArgumentException("Chain execution must be in the database");
        }
        
        return getChainDataHistory(chexID);
    }
    
    public List getChainDataHistory(Integer chexID) {
        return icaller.dispatchList(ModuleExecution.class,"getChainDataHistory",
                    new Object[] {
                        chexID
                    });
    }
    
    
    public List getChainDataHistory(ChainExecution chex,
    			FieldsSpecification spec) 
    {
        if (chex == null)
            throw new IllegalArgumentException("Chain execution cannot be null");
        
        Integer chexID = null;

        try
        {
            chexID = new Integer(chex.getID());
        } catch (DataException e) {
            throw new 
			IllegalArgumentException("Chain execution must be in the database");
        }
        
        return getChainDataHistory(chexID,spec);
    }
    
    public List getChainDataHistory(Integer chainID,FieldsSpecification spec) {
        return icaller.dispatchList(ModuleExecution.class,"getChainDataHistory",
                    new Object[] {
                        chainID,
					   spec
                    });
    }

}