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

import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.geom.Rectangle2D;
import java.awt.Color;


public class PCategoryBox extends PPath implements PBufferedNode {
	
	private static final Color CATEGORY_COLOR= new Color(255,255,0,100);
	
	public PCategoryBox(float x,float y,float w,float h) {
		super(new Rectangle2D.Float(x,y,w,h));
		setStrokePaint(null);
		setPaint(CATEGORY_COLOR);
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = getFullBoundsReference();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,
			b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER);
	}
} 