/*
 * org.openmicroscopy.vis.piccolo.PBrowserEventHandler
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
import edu.umd.cs.piccolo.PCanvas;
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
	
	private PBrowserCanvas canvas;
	
	public PBrowserEventHandler(PBrowserCanvas canvas) {
		super(canvas);
		this.canvas = canvas;	
	}
	
	public void mouseEntered(PInputEvent e) {
		PNode n = e.getPickedNode();
		System.err.println("browser event mouse entered "+n);
		if (n instanceof PSelectableText) {
			((PSelectableText) n).setHighlighted(true);
			if (n instanceof PChainLabelText) {
				PChainLabelText clt = (PChainLabelText) n;
				canvas.showExecutionList(clt);
			}
		} 
		else {
			canvas.clearExecutionList();
			if (n instanceof PThumbnail)  {
				PThumbnail pt = (PThumbnail) n;
				pt.setHighlightedWithHalo(true);
			}
			else if (n instanceof PDataset) {
				PDataset dn = (PDataset) n;
				dn.rollover();	
			}
			else if (!(n instanceof PThumbnailSelectionHalo))  {// entering anything else means setting selected datset is null
				SelectionState.getState().setRolloverDataset(null);	 
			}
		}
		e.setHandled(true);
	}
	
	public void mouseExited(PInputEvent e) {
		PNode n = e.getPickedNode();
		System.err.println("browser event exited.."+n);
		if (n instanceof PThumbnail) {
			PThumbnail pt = (PThumbnail) n;
			pt.setHighlightedWithHalo(false);
		}
		else if (n instanceof PSelectableText) {
			((PSelectableText)n).setHighlighted(false);
		} 
		e.setHandled(true);
	}	
	
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			handlePopup(e);
			e.setHandled(true);
		}
	}
	
	public void mousePressed(PInputEvent e) {
		mouseReleased(e);
	}
	
	public void handlePopup(PInputEvent e) {
		postPopup = true;
		PNode node = e.getPickedNode();
		System.err.println("popup..."+node);
		if (node instanceof PDataset) {
			System.err.println("popup on dataset...");
			SelectionState selectionState = SelectionState.getState();	
			selectionState.setSelectedDataset(null);
			((PDataset) node).enableHalo();
		}
		else if (node instanceof PThumbnail) {
			System.err.println("popup on thumbnail...");
			PThumbnail pt = (PThumbnail) node;
			PDatasetImagesNode pin = pt.getDatasetImagesNode();
			pt.setHighlightedWithHalo(true);
			if (pin != null) {
				pin.enableHalo();
				System.err.println("zooming to halo..");
				pin.zoomToHalo(((PCanvas) canvas).getCamera());	
			}
			else {
				System.err.println("no datasetimagesnode...");
				PBufferedNode bn = pt.getBufferedParentNode();
				animateToBufferedNode(bn);
			}
		}
		else
			super.handlePopup(e);
	}
	public void mouseClicked(PInputEvent e) {
		// left button.
		
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
				//System.err.println("zooming in on dataset");
				PDataset d = (PDataset) node;
				selectionState.setSelectedDataset(d.getDataset());
				animateToNode(d);
			}

			else if (node instanceof PExecutionText) {
				//placeholder
			}
			else if (isBackgroundClick(node)) {
				System.err.println("clicking on layer or camera..");
				selectionState.setSelectedDataset(null);
			}
			else if (node instanceof PThumbnailSelectionHalo) {
				System.err.println("..clicked on halo...");
				super.mouseClicked(e);
			} else if (node instanceof PThumbnail) {
				PThumbnail thumb = (PThumbnail)node;
				if (thumb.isZoomable())
					super.mouseClicked(e);
				else { // zoom to halo?
					System.err.println("zooming in to halo?");
		
					PDatasetImagesNode pin = thumb.getDatasetImagesNode();
					if (pin != null)
						pin.zoomToHalo(((PCanvas) canvas).getCamera());
				}
			}
			else 
				super.mouseClicked(e);	
		}
		e.setHandled(true);
	}
	
}