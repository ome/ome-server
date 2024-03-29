/*
 * org.openmicroscopy.alligator.LoginResponder;
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

 package org.openmicroscopy.util;
 
/**
 * Definition of the callbacks for objecs that use a {@link LoginFrame}.
 * 
 * @author Harry Hochheiser 
 * @version 2.1
 * @since OME2.1
 *
 */

public interface LoginResponder {
 	
 	/**
 	 * The procedure to be called when the user clicks "Cancel"
 	 *
 	 */
 	public void loginCancel();
 	
 	/**
 	 * The procedure to be called when the user clicks "OK"
 	 *
 	 */
 	public void loginOK();
 	
 }