/*
 * org.openmicroscopy.vis.piccolo.ParameterLocator
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
import edu.umd.cs.piccolox.util.PLocator;
import javax.swing.SwingConstants;
import java.awt.geom.Rectangle2D;

/**
 * Locating of linkage points on module parameters<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */


public class ParameterLocator extends PLocator {

	private ModuleParameter param;
	private int side;
	
	public ParameterLocator(ModuleParameter param,int side) {
		super();
		this.param = param;
		this.side = side;	
	}
	
	public double locateY() {
		Rectangle2D aBounds = param.getBoundsReference();
		return aBounds.getY()+aBounds.getHeight()/2;	
	}
	
	public double locateX() {
		Rectangle2D aBounds = param.getBoundsReference();
		if (side == SwingConstants.EAST) {
			return aBounds.getX()+aBounds.getWidth()+Link.END_BULB_RADIUS;
		}
		else { // must be WEST
			return aBounds.getX()-Link.END_BULB;
		}
	}
}
	