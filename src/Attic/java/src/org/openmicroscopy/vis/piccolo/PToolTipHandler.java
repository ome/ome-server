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
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.geom.Point2D;
import java.awt.Color;
import java.awt.Font;


/** 
 *
 * An event handler for tooltips. Borrows heavily from the code
 * in the Piccolo example files. 
 *  
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public abstract class PToolTipHandler extends PBasicInputEventHandler {

	/**
	 * if the scale exceeds SCALE_THRESHOLD, the tooltip might be distracting,
	 *  as the object is already large. Therefore, we don't show it.
	 * 
	 */
	protected static double 	SCALE_THRESHOLD=0.8;
	protected static Color BORDER_COLOR = new Color(102,102,153);
	protected static Color FILL_COLOR = new Color(153,153,204);
	protected PCamera camera;
	
	
	
	protected Font font = new Font("Helvetica",Font.PLAIN,12);
	
	protected PPath tooltip;
	protected PText tooltipText;
	
	protected boolean displayed = false;

	/**
	 * Initializes the tool tip handler
	 * @param camera the camera that will display the tooltip
	 */
	PToolTipHandler(PCamera camera) {
		this.camera = camera;
		tooltip = new PPath();
		tooltip.setPaint(FILL_COLOR);
		tooltip.setStrokePaint(BORDER_COLOR);
		tooltipText = new PText();
		tooltipText.setFont(font);
		tooltip.addChild(tooltipText);
	}
	
	
	/**
	 * update the tooltip when the mouse is moved
	 * 
	 
	 */
	public void mouseMoved(PInputEvent event) {
		updateToolTip(event);
	}
	
	/**
	 * also update when the mouse is dragged
	 *
	 * * @param event the mouse event 
	 */
	public void mouseDragged(PInputEvent event) {
		updateToolTip(event);
	}
		
	/**
	 * Update the tooltip text and position it, with an
	 * offset appropraite for the display.
	 * 
	 * @param event the input event leading to the update. 
	 */
	public void updateToolTip(PInputEvent event) {
		setToolTipString(event);
			
		Point2D p = event.getCanvasPosition();
		
			//eseentially, this converts p to
			//camera coordinates.
			// layers can be in the way, so we
				//can't go localToGlobal.
		event.getPath().canvasToLocal(p, camera);
		tooltip.setOffset(p.getX() + 8, p.getY() - 8);
	}
	
	/**
	 * Called when the tool tip must be updated, this procedure generally
	 * chooses the appropriate text and then calls {@link setToolTipString}
	 * 
	 * @param event the input event leading to the change
	 */
	public abstract void  setToolTipString(PInputEvent event);
	
	/**
	 * Set the tool tip text - if the new string is null,
	 * remove the node from the camera's scenegraph. Otherwise,
	 * set the text and adjust the position
	 * @param s
	 */
	public void setToolTipText(String s) {
		if (s.compareTo("") ==0) {
			if (displayed == true)
				camera.removeChild(tooltip);
			displayed = false;   
		}
		else {
			if (displayed == false)
				camera.addChild(tooltip);
			displayed = true;
			tooltipText.setText(s);
			PBounds b = tooltipText.getFullBounds();
			PBounds newBounds = new PBounds(0,0,b.getWidth(),b.getHeight());
			tooltip.setPathTo(newBounds);
		}	
	}
	
}

