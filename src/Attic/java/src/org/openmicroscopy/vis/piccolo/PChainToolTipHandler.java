/*
 * org.openmicroscopy.vis.piccolo.PChainToolTipHandler
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
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PNode;
import java.awt.Font;


/** 
 *
 * An event handler for tooltips on the {@link PChainCanvas} and
 * {@link PResultCanvas}.
 *  
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainToolTipHandler extends PPaletteToolTipHandler {
	
	protected Font font = new Font("Helvetica",Font.PLAIN,12);
	
	public PChainToolTipHandler(PCamera camera) {
		super(camera);
	}
	
	/**
	 * The text of the tooltip is either the name of a module,
	 * the name of a parameter, or (if the mouse goes over a link) the name
	 * of the parameters at the ends of a link.
	 * 
	 * @param event the event that caused the update of the tool tip 
	 */
	public PNode setToolTipNode(PInputEvent event) {
		
		double scale = camera.getViewScale();
		if (scale >= PToolTipHandler.SCALE_THRESHOLD)
			return (PNode) null;
		
		PNode n = event.getInputManager().getMouseOver().getPickedNode();
			
		if (n instanceof PParamLink) {
			PFormalInput in = ((PParamLink) n).getInput();
			PFormalOutput out = ((PParamLink) n).getOutput();
			String s = in.getName()+"-"+out.getName();
			if (s.compareTo("") == 0)
				return (PNode) null;
			else {
				PText p = new PText(s);
				p.setFont(font);
				return p;
			}
		}
		else
			return super.setToolTipNode(event);
	}
}
