/*
 * org.openmicroscopy.vis.piccolo.PPaletteToolTipHandler
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

import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PText;
import java.awt.Font;

/** 
 *
 * An event handler for tooltips on the {@link PPaletteCanvas} and the
 * {@link PChainLibraryCanvas}
 *  
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PPaletteToolTipHandler extends PToolTipHandler {
	
	protected Font font = new Font("Helvetica",Font.PLAIN,12);
	
	public PPaletteToolTipHandler(PCamera camera) {
		super(camera);
	}
	
	/**
	 * The toolTip String is either the name of the module that the mouse
	 * is on, or it is null. If the scale is too large 
	 * (exceeding {@link PToolTipHandler.SCALE_THRESHOLD),
	 * no tooltip is shown
	 * 
	 * @param event the input event that leads to the change.
	 */
	public PNode setToolTipNode(PInputEvent event) {
		PNode p = (PNode) null;
		String s = "";
		PNode n = event.getInputManager().getMouseOver().getPickedNode();
		double scale = camera.getViewScale();
		if (scale < PToolTipHandler.SCALE_THRESHOLD) {
			if (n instanceof PModule)
				s=((PModule) n).getModule().getName(); 
			else if (n instanceof PFormalParameter) {
				s= ((PFormalParameter) n).getPModule().
					getModule().getName();
			}
		}
		if (s.compareTo("") != 0) {
			PText pt = new PText(s);
			pt.setFont(font);
			p = pt;
		}
		return p;
	}
	
}