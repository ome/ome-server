/*
 * org.openmicroscopy.vis.piccolo.PRemoteObjectLabelText
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
package org.openmicroscopy.vis.piccolo;

import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;

import java.awt.Color;


/** 
 * Text nodes for  object names
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public abstract class PRemoteObjectLabelText extends PSelectableText
	implements SelectionEventListener{
	
	protected static final Color ACTIVE_COLOR= new Color(100,0,100,255);
	protected static final Color SELECTED_COLOR = new Color(175,0,175,255);

	
	protected boolean active = false;
	protected boolean selected = false;
	protected Color curColor;
	
	
	public PRemoteObjectLabelText() {
		super();
		SelectionState selectionState = SelectionState.getState();
		
		if (selectionState != null) 
			selectionState.addSelectionEventListener(this);
	}
	
	
	public void setActive(boolean v) {
		active = v;
	}
	
	public void setSelected(boolean v) {
		selected =v;
	}
	
	protected void setColor() {
		if (active == true) 
			curColor = ACTIVE_COLOR;
		else if (selected == true)
			curColor = SELECTED_COLOR;
		else
			curColor = PConstants.DEFAULT_COLOR;
		setColor(curColor);
	}
	
	public abstract void selectionChanged(SelectionEvent e);
	 
	
	public  abstract void doSelection();
}
