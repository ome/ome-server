
/*
 * org.openmicroscopy.vis.piccolo.PChainBox
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
import org.openmicroscopy.vis.ome.CDataset;
import edu.umd.cs.piccolo.nodes.PText;
import java.awt.Color;
import java.util.Collection;

/** 
 * Text nodes for  dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PDatasetLabelText extends PText  implements SelectionEventListener{
	
	private static final Color ACTIVE_COLOR= new Color(100,0,100,255);
	private static final Color SELECTED_COLOR = new Color(175,0,175,255);
	public static final double LABEL_SCALE=3;
	private static final Color BASE_COLOR = Color.BLACK;
	
	
	private boolean active = false;
	private boolean selected = false;
	private Color curColor;
	private SelectionState selectionState;
	private CDataset dataset;
	
	public PDatasetLabelText(CDataset ds,SelectionState selectionState) {
		super(ds.getName());
		this.dataset = ds;
		this.selectionState = selectionState;
		if (selectionState != null) 
			selectionState.addSelectionEventListener(this);
		setScale(LABEL_SCALE);
		setFont(PConstants.LABEL_FONT);
		setColor();
	}
	
	public void setActive(boolean v) {
		active = v;
	}
	
	public void setSelected(boolean v) {
		selected =v;
	}
	
	private void setColor() {
		if (active == true) 
			curColor = ACTIVE_COLOR;
		else if (selected == true)
			curColor = SELECTED_COLOR;
		else
			curColor = BASE_COLOR;
		setPaint(curColor);
	}
	
	public void selectionChanged(SelectionEvent e) {
		Collection sets = selectionState.getActiveDatasets();
		if (selectionState.getSelectedDataset() == dataset) {
			setActive(false);
			setSelected(true);
		}
		else if (sets != null && sets.contains(dataset)) {
			setActive(true);
			setSelected(false);
		}
		else {
			setActive(false);
			setSelected(false);
		}
		setColor();
	} 
	
	public  void doSelection() {
		selectionState.setSelectedDataset(dataset);
	}
}
