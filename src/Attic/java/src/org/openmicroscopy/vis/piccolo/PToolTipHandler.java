/*
 * org.openmicroscopy.vis.piccolo.PToolTipHandler
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
 
import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.nodes.PText;
import java.awt.geom.Point2D;
import java.awt.Color;
import java.awt.Font;

/**
 * A handler for toolips. This borrows heavily from the tooltip example
 * in the piccolo distribution.
 */

public abstract class PToolTipHandler extends PBasicInputEventHandler {

	protected static double 	SCALE_THRESHOLD=0.8;
	protected static Color	TIP_COLOR = Color.BLUE;
	protected PCamera camera;
	protected PText tooltipNode;
	protected Font font = new Font("Helvetica",Font.BOLD,14);
	

	PToolTipHandler(PCamera camera) {
		this.camera = camera;
		tooltipNode = new PText();
		tooltipNode.setFont(font);
		camera.addChild(tooltipNode);
		tooltipNode.setPaint(TIP_COLOR);
	}
	
	
	
	public void mouseMoved(PInputEvent event) {
		updateToolTip(event);
	}
	
	public void mouseDragged(PInputEvent event) {
		updateToolTip(event);
	}
		
	public void updateToolTip(PInputEvent event) {
		setToolTipString(event);
			
		Point2D p = event.getCanvasPosition();
		
			//eseentially, this converts p to
			//camera coordinates.
			// layers can be in the way, so we
				//can't go localToGlobal.
		event.getPath().canvasToLocal(p, camera);
		tooltipNode.setOffset(p.getX() + 8, p.getY() - 8);
	}
	
	public abstract void  setToolTipString(PInputEvent event);
	
	
}

