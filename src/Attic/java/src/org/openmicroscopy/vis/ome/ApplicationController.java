/*
 * org.openmicroscopy.vis.chains.ome.ApplicationController
 *
 * Copyright (C) 2003 Open Microscopy Environment
 * 		Massachusetts Institute of Technology,
 * 		National Institutes of Health,
 * 		University of Dundee
 * Author:  Harry Hochheiser <hsh@nih.gov>
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
 */
 
package org.openmicroscopy.vis.ome;


/** 
 * <p>Applications that interfact with the OME databse must
 *  implement this interface.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */


public interface ApplicationController {


	public void doLogin();
	
	public void doLogout();
	
	/**
	 * <p>Callback for when login is complete
	 * 
	 *
 	 * @author Harry Hochheiser
     * @version 0.1
     * @since OME2.0
	 */
	public void completeLogin();
	
	
	/**
	 * <p>Callback for when login is complete
 	 * 
 	 *
     * @author Harry Hochheiser
     * @version 0.1
     * @since OME2.0
     */
	public void cancelLogin();
	
	public void updateDatabase();
}
