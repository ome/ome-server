/*
 * org.openmicroscopy.vis.piccolo.PChainLabelText
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
import org.openmicroscopy.vis.ome.CChain;
import edu.umd.cs.piccolo.nodes.PText;
import java.awt.Color;


/** 
 * Text nodes for  dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainLabelText extends PText  implements SelectionEventListener{
	
	public static final double LABEL_SCALE=.25;
	private static final Color BASE_COLOR = Color.BLACK;
	
	
	private boolean active = false;
	private boolean selected = false;
	private Color curColor;
	private SelectionState selectionState;
	private CChain chain;
	
	public PChainLabelText(CChain c,SelectionState selectionState) {
		super(c.getName());
		this.chain  = c;
		this.selectionState = selectionState;
		if (selectionState != null) 
			selectionState.addSelectionEventListener(this);
		setScale(LABEL_SCALE);
		setFont(PConstants.LABEL_FONT);
	}
	
	
	private void setActive(boolean v) {	
	}
	
	private void setSelected(boolean v) {
		
	}
	public void selectionChanged(SelectionEvent e) {
		
		if (selectionState.getSelectedChain() == chain) {
			setActive(false);
			setSelected(true);
		}
		else {
			setActive(false);
			setSelected(false);
		}
	} 
	
	public  void doSelection() {
		System.err.println("dataset ..+ is being selected.."+chain.getName());
		selectionState.setSelectedChain(chain);
	}
}
