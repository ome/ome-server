/*
 * org.openmicroscopy.vis.piccolo.PThumbnailSelectionHalo.java
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
import edu.umd.cs.piccolo.util.PPaintContext;
import java.awt.BasicStroke;

/** 
 * Popup halo path that can go around PThumbnail for zooming into a Dataset.
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PThumbnailSelectionHalo extends PPath implements PBufferedNode {

	// leave on pixel on either side of border
	public static final int OFFSET=3;
	public static final float BASE_STROKE_WIDTH=PConstants.DATASET_IMAGE_GAP-
		OFFSET;
	private static final BasicStroke stroke = 
		new BasicStroke(BASE_STROKE_WIDTH);
	


	public PThumbnailSelectionHalo() {
		super();
		setVisible(false);
		setPickable(false);
		setStroke(stroke);
		setStrokePaint(PConstants.HALO_COLOR);	
	}
	
	public void hide() {
		setStatus(false);
	}
	
	public void show() {
		setStatus(true);
	}
	
	private void setStatus(boolean v) {
		setVisible(v);
		setPickable(v);
	}
	
	
	public PBounds getBufferedBounds() {
		PBounds b = getGlobalFullBounds();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER*getGlobalScale(),
			b.getY()-PConstants.SMALL_BORDER*getGlobalScale(),
			b.getWidth()+2*PConstants.SMALL_BORDER*getGlobalScale(),
			b.getHeight()+2*PConstants.SMALL_BORDER*getGlobalScale());
	}
	

	public void setPathTo(PBounds b) {
		double scale = getGlobalScale();
		double border =OFFSET*scale;
		PBounds b2 = new PBounds(b.getX()-border,b.getY()-border,
			b.getWidth()+2*border,b.getHeight()+2*border);
		super.setPathTo(b2);
	}
	
	public int compareTo(Object o) {
		if (o instanceof PBufferedNode) {
			PBufferedNode node = (PBufferedNode) o;
			double myArea = getHeight()*getWidth();
			PBounds bounds = node.getBufferedBounds();
			double nodeArea = bounds.getHeight()*bounds.getWidth();
			int res =(int) (myArea-nodeArea);
			return res;
		}
		else
			return -1;
	}
	
	public void paint(PPaintContext aPaintContext) {
		float scale = (float) aPaintContext.getScale();
		float strokeScale = BASE_STROKE_WIDTH/scale;
		setStroke(new BasicStroke(strokeScale));
		super.paint(aPaintContext);
	}
}