/*
 * org.openmicroscopy.vis.piccolo.ModuleInputEventHandler
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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


import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import org.openmicroscopy.SemanticType;
import java.util.ArrayList;
import java.util.Iterator;



/** 
 * <p>Highlighting of module outputs that correspond to this input.
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModuleInputEventHandler extends PBasicInputEventHandler {
	
	private ModuleInput input;
	private boolean dragging = false;
	
	public ModuleInputEventHandler(ModuleInput input) {
		super();
		this.input = input;	
	}
	
	public void mouseEntered(PInputEvent aEvent) {
		System.err.println("entered input "+input.getName());
		setOutputsHighlighted(true);
	
	}
	
	public void mouseExited(PInputEvent aEvent) {
		System.err.println("exited input "+input.getName());
		if (dragging == false)
			setOutputsHighlighted(false);
	}
	
	
	private void setOutputsHighlighted(boolean v) {
		SemanticType type = input.getSemanticType();
		if (type == null)
			return;
		
		ArrayList list = input.getCanvas().getOutputs(type);
		if (list == null)
			return;
		
		ModuleOutput output;
		Iterator iter = list.iterator();
		
		while (iter.hasNext()) {
			output = (ModuleOutput) iter.next();
			output.setLinkable(v);		
		}
	}
	
	public void mousePressed(PInputEvent aEvent) {
		System.err.println("mouse pressed in input "+input.getName());
		aEvent.setHandled(true);
	}
	
	public void mouseReleased(PInputEvent aEvent) {
		dragging = false;
		System.err.println("mouse released in input "+input.getName());
		if (input.isLinkable())
			System.err.println("target is ok");
		else
			System.err.println("target is no good");
		aEvent.setHandled(true);
		setOutputsHighlighted(false);
	}
	
	public void mouseDragged(PInputEvent aEvent) {
		dragging = true;
		System.err.println("mouse dragged in input " +input.getName());
		aEvent.setHandled(true);
	}
} 