/*
 * org.openmicroscopy.vis.piccolo.ModuleOutputEventHandler
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
import java.util.Iterator;
import java.util.ArrayList;
import org.openmicroscopy.SemanticType;


/** 
 * <p>Highlighting of ModuleInputs with same semantic type as this output<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModuleOutputEventHandler extends PBasicInputEventHandler {
	
	private ModuleOutput output;
	private boolean dragging = false;
	
	public ModuleOutputEventHandler(ModuleOutput output) {
		super();
		this.output = output;	
	}
	
	public void mouseEntered(PInputEvent aEvent) {
		System.err.println("entered output "+output.getName());
		setInputsHighlighted(true);		
	}
	
	public void mouseExited(PInputEvent aEvent) {
		System.err.println("exited output "+output.getName());
		if (dragging == false)
			setInputsHighlighted(false);
	}
	
	private void setInputsHighlighted(boolean v) {
		SemanticType type = output.getSemanticType();
		if (type == null)
			return;
		
		ArrayList list = output.getCanvas().getInputs(type);
		if (list == null)
			return;
		
		ModuleInput input;
		Iterator iter = list.iterator();
		
		while (iter.hasNext()) {
			input = (ModuleInput) iter.next();
			input.setLinkable(v);		
		}
	}
	
	public void mousePressed(PInputEvent aEvent) {
		System.err.println("mouse pressed in output "+output.getName());
		aEvent.setHandled(true);
	}
	
	public void mouseReleased(PInputEvent aEvent) {
		dragging = false;
		System.err.println("mouse released in output "+ output.getName());
		if (output.isLinkable())
			System.err.println("target is ok");
		else
			System.err.println("target is no good");
		
		aEvent.setHandled(true);
		setInputsHighlighted(false);
	
	}
	
	public void mouseDragged(PInputEvent aEvent) {
		System.err.println("mouse dragged in output " +output.getName());
		aEvent.setHandled(true);
		dragging = true;
	}
}