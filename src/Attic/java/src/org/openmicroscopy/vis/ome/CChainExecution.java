/*
 * org.openmicroscopy.vis.chains.ome.CChainExecution
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */
 
 package org.openmicroscopy.vis.ome;

import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.remote.RemoteChainExecution;
import org.openmicroscopy.remote.RemoteSession;



/** 
 * <p>A subclass of {@link RemoteChainExecution} with additional calls to 
 * streamline retrieval of execution results.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CChainExecution extends RemoteChainExecution  {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChainExecution",
			CChainExecution.class);
	}
	
	
	public CChainExecution() {
		super();
	}
	
	public CChainExecution(RemoteSession session,String reference) {
		super(session,reference);
	}	
 }