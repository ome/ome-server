/*
 * org.openmicroscopy.vis.piccolo.ProwserEventHandler
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
import org.openmicroscopy.vis.chains.SelectionState;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import java.awt.event.MouseEvent;

/** 
 * An event handler for the PChainLibraryCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PBrowserEventHandler extends  PGenericZoomEventHandler {
	
	
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	/**
	 * The canvas to which this is attached
	 */
	private PBrowserCanvas canvas;
	
	/**
	 * How far down we have zoomed. Zooming a large browser canvas works on a 
	 * principal of varying zoom levels, rooughly based on exponentially 
	 * smaller steps: starting with zoom level 0 (the full screen), each 
	 * susbsequent zoom lvel zooms to a smaller subset - see 
	 * {@link PDatasetImagesNode} for details on the zooming 
	 */
	private int zoomLevel = 0;
	
	public PBrowserEventHandler(PBrowserCanvas canvas) {
		super(canvas);
		this.canvas = canvas;	
	}

	/**
	 * Handler for entering a node
	 */	
	public void mouseEntered(PInputEvent e) {
		PNode n = e.getPickedNode();

		if (n instanceof PSelectableText) {
			((PSelectableText) n).setHighlighted(true);
			if (n instanceof PChainLabelText) {
				// if I enter the chain labels, show the associated 
				// execution list
				PChainLabelText clt = (PChainLabelText) n;
				canvas.showExecutionList(clt);
			}
		} 
		else {
			// otherwise ,clear the list
			canvas.clearExecutionList();
			if (n instanceof PThumbnail)  {
				// show the halo if I enter a thumbnail
				PThumbnail pt = (PThumbnail) n;
				pt.setHighlightedWithHalo(true,zoomLevel);
			}
			else if (n instanceof PDataset) {
				// if I entered a dataset, rollover
				PDataset dn = (PDataset) n;
				dn.rollover();	
			}
			else if (!(n instanceof PThumbnailSelectionHalo))  {
				// entering anything else means setting selected datset is null
				SelectionState.getState().setRolloverDataset(null);
				zoomLevel = 0;	 
			}
		}
		e.setHandled(true);
	}
	
	/**
	 * Mouse exited handler
	 */
	public void mouseExited(PInputEvent e) {
		PNode n = e.getPickedNode();
		if (n instanceof PThumbnail) {
			// if I exit a thumbnail, turn off the halo
			PThumbnail pt = (PThumbnail) n;
			pt.setHighlightedWithHalo(false,zoomLevel);
		}
		else if (n instanceof PSelectableText) {
			// otherwise, if it's selectable text (like the chain label)
			// turn off the highlight
			((PSelectableText)n).setHighlighted(false);
		} 
		e.setHandled(true);
	}	
	
	/**
	 * Mouse release event can lead to a popup
	 */
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			handlePopup(e);
			e.setHandled(true);
		}
	}
	
	/**
	 * Mouse press event can lead to a popup
	 */
	public void mousePressed(PInputEvent e) {
		mouseReleased(e);
	}
	
	/** 
	 * Right button click
	 */
	public void handlePopup(PInputEvent e) {
		postPopup = true;
		PNode node = e.getPickedNode();
		if (node instanceof PDataset) {
			// right click on a dataset deslects
			SelectionState selectionState = SelectionState.getState();	
			selectionState.setSelectedDataset(null);
			zoomLevel = 0;
		}
		else if (node instanceof PThumbnail) {
			// on a thumbnail, we zoom out
			PThumbnail pt = (PThumbnail) node;
			zoomLevel = pt.zoomOutOfHalo(zoomLevel);
			
		}
		else {
			// otherwise, default behavior.
			super.handlePopup(e);
		}
	}
	
	/**
	 * left-mouse click
	 */
	public void mouseClicked(PInputEvent e) {
		// left button.
		
		// ignore if this is right after a popup
		if (postPopup == true ) {
			postPopup = false;
			e.setHandled(true);
			return; 
		}
		PNode node = e.getPickedNode();
		SelectionState selectionState = SelectionState.getState();
		if ((e.getModifiers() & MouseEvent.BUTTON1_MASK) 
			== MouseEvent.BUTTON1_MASK) {
			if (node instanceof PDataset) { 
				// if it's a dataset, select it and animate to it.
				PDataset d = (PDataset) node;
				selectionState.setSelectedDataset(d.getDataset());
				zoomLevel = 0;
				animateToNode(d);
			}

			else if (node instanceof PExecutionText) {
				//placeholder
			}
			else if (isBackgroundClick(node)) {
				// click on background clears selected dataset
				selectionState.setSelectedDataset(null);
				zoomLevel =0;
			} else if (node instanceof PThumbnail) {
				// click on thumbnail, we zomo in to it and 
				// adjust zoomLevel
				PThumbnail thumb = (PThumbnail)node;
				zoomLevel = thumb.zoomInToHalo(zoomLevel);
			}
			else  // default behavior.
				super.mouseClicked(e);	
		}
		e.setHandled(true);
	}
}