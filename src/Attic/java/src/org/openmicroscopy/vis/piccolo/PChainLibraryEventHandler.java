/*
 * org.openmicroscopy.vis.piccolo.PChainLibraryEventHandler
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

import org.openmicroscopy.vis.ome.events.ChainSelectionEvent;
import org.openmicroscopy.vis.ome.events.ChainSelectionEventListener;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.chains.Controller;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import javax.swing.event.EventListenerList;
import java.awt.event.MouseEvent;

/** 
 * An event handler for the PChainLibraryCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLibraryEventHandler extends  PGenericZoomEventHandler {

	private PChainLibraryCanvas canvas;
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	private PModule lastEntered;

	private EventListenerList chainListeners = new EventListenerList();
	
	private CChain selectedChain;
			
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	public PChainLibraryEventHandler(PChainLibraryCanvas canvas,
		Controller controller) {
		super(canvas);
		this.canvas = canvas;
		this.addChainSelectionEventListener(controller.getControlPanel());	
	}
	
	
	public void mouseClicked(PInputEvent e) {
		super.mouseClicked(e);
		PNode n = e.getPickedNode();
		if (n instanceof PChainBox) { 
			PChainBox cb = (PChainBox) n;
			selectedChain=cb.getChain();
			fireSelectionEvent();
			
		}
		else if (n instanceof PModule) {
			PChainBox cb = (PChainBox) n.getParent();
			selectedChain = cb.getChain();
			fireSelectionEvent(); 
		}
		else 
			fireDeselectionEvent();
	} 
	
	/**
	 * When the user presses the mouse on a {@link PChainBox}, tell the
	 * {@link PChainLibraryCanvas} which chain has been selected.
	 * Or, if it's a popup, handle it as such.
	 */
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		if (e.isPopupTrigger()) {
			handlePopup(e);
		}
		else if (node instanceof PChainBox) {
			PChainBox box = (PChainBox) node;
			//canvas.setSelectedChainID(box.getChainID());
			canvas.setSelectedChain(box.getChain());
		}
	}
	
	/**
	 * When the mouse is released, tell the canvas that there is no longer
	 * a selected chain.
	 */
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			handlePopup(e);
		}
		else
			canvas.clearChainSelected();
	}
	
	
	
	public void fireSelectionEvent() {
		ChainSelectionEvent chainEvent = new 
			ChainSelectionEvent(selectedChain,ChainSelectionEvent.SELECTED);
		fireChainSelectionEvent(chainEvent);
	}
	
	public void fireDeselectionEvent() {
		if (selectedChain == null) 
			return;
		ChainSelectionEvent chainEvent = new 
			ChainSelectionEvent(selectedChain,ChainSelectionEvent.DESELECTED);
		fireChainSelectionEvent(chainEvent);
		selectedChain = null;
	}
	
		
	public void addChainSelectionEventListener(ChainSelectionEventListener
			listener) {
		chainListeners.add(ChainSelectionEventListener.class,
				listener);
	}
	
		public void removeChainSelectionEventListener(ChainSelectionEventListener
			listener) {
				chainListeners.remove(ChainSelectionEventListener.class,
					listener);
		}
	
		public void fireChainSelectionEvent(ChainSelectionEvent e) {
			Object[] listeners=chainListeners.getListenerList();
			for (int i = listeners.length-2; i >=0; i-=2) {
				if (listeners[i] == ChainSelectionEventListener.class) {
					((ChainSelectionEventListener) listeners[i+1]).
						chainSelectionChanged(e);
				}
			}
		}
}