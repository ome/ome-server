/*
 * org.openmicroscopy.vis.piccolo.PLinkTarget
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

import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.Color;
import java.awt.geom.Point2D;
 
/** 
 * A Piccolo widget for a linkable target
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PLinkTarget extends PPath {
	
	public static final Color CIRC_COLOR = new Color(0,225,0);
 	public static final float CIRC_SIZE=10;
 	public static final float CIRC_HALF_SIZE=CIRC_SIZE/2;
 	public static final float  CIRC_BUFFER=3;
 	
 	public PLinkTarget() {
 		super();
 		setPathToEllipse(0,0,CIRC_SIZE,CIRC_SIZE);
 		setPaint(CIRC_COLOR);
 	}	
 	
 	public Point2D getCenter() {
		PBounds b = getFullBoundsReference();
		float x = (float) (b.getX()+b.getWidth()/2);
		float y = (float) (b.getY()+b.getHeight()/2);
		Point2D.Float result = new Point2D.Float(x,y);
		localToGlobal(result);
		return result;
 	}
}


	