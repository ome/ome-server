/*
 * org.openmicroscopy.vis.piccolo.PCategoryBox
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

package org.openmicroscopy.vis.piccolo;


/** 
 * A subclass of {@link PCategoryBox} that is used to provide a colored 
 * background to module categories.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PCategoryBox extends PGenericBox {
	
	private String name;
	
	
	private double area = 0.0;
	
	/*
	 * Store a name for the category instead of an OME object, 
	 * 	as some may have no object - just the name "Uncategorized"
	 */
	public PCategoryBox(String name) {
		super(0,0,0,0);
		this.name = name;
		
	}
	public PCategoryBox() {
		super(0,0,0,0);
	}
	
	public PCategoryBox(float x,float y) {
		super(x,y,0f,0f);
	}
	
	public PCategoryBox(float x,float y,float w,float h) {
		super();
	}
	
	public String getName() {
		return name;
	}
} 