/*
 * org.openmicroscopy.vis.chains.Chains
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
package org.openmicroscopy.vis.chains;

/** 
 * <p>The main class for the Chain-building application. This class
 * is just a shell that will instantiate appropriate classes for
 * display, control, and other functionality.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class Chains {

    public static String VERSION="0.1";
    public static String TIMESTAMP="094304082003";
    
    public static String INFO = "OME Chains, Version "+VERSION+", "+TIMESTAMP;


    public static void main(String[] args) {
		System.out.println(INFO);
		
		// These property calls should fail silently if the given things aren't there.
		
		System.setProperty("com.apple.mrj.application.apple.menu.about.name",
								  "OME Chains");
		System.setProperty("com.apple.mrj.application.live-resize","true");
		System.setProperty("com.apple.mrj.application.growbox.intrudes","true");
		System.setProperty("apple.laf.useScreenMenuBar","true");
		
		Controller controller = new Controller();
		

    }
    
   
}
    
