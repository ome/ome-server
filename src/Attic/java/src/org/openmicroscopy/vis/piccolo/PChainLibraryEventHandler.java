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

import org.openmicroscopy.vis.chains.events.ChainSelectionEvent;
import org.openmicroscopy.vis.chains.events.ChainSelectionEventListener;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.chains.Controller;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import javax.swing.event.EventListenerList;
import javax.swing.Timer;
import java.awt.event.MouseEvent;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

/** 
 * An event handler for the PChainLibraryCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLibraryEventHandler extends  PGenericZoomEventHandler 
	implements ActionListener
 {

	private PChainLibraryCanvas canvas;
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	private PModule lastEntered;

	private EventListenerList chainListeners = new EventListenerList();
	
	private CChain selectedChain;
	
	
	// needed for handling of double click. basically, two clicks
	// within 300ms are a double click. by definition from this code.
	private final Timer timer = new Timer(300, this);
	
	private PInputEvent cachedEvent;

			
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
	
	/*
	 * As this is the action listener for the timer, it will be called
	 * when the timer has expired. If this is the case, the cachedEvent
	 * is a single click, so process it as such, and stop the timer.
	 */
	public void actionPerformed(ActionEvent e) {
		
		if (cachedEvent != null) {
			super.mouseClicked(cachedEvent);
		}
		cachedEvent = null;
		timer.stop();
	}
	
	/* When I get a mouse event, there are two possibilities:
	 * 1) if the timer is not running, it's the start of a new set of clicks.
	 *   restart the timer and store the event
	 * 2) if the timer is running, this means that this is a second click,
	 * 		as the first click started the timer. Stop the timer,
	 *  	and treat the click like a double click
	 */
	public void mouseClicked(PInputEvent e) {
		if (timer.isRunning()) {// it's a double click
			timer.stop();
			mouseDoubleClicked(e);
			cachedEvent = null;
		}
		else {
			timer.restart();
			cachedEvent = e;
		}
	}
	
	private void mouseDoubleClicked(PInputEvent e) {
		PNode n = e.getPickedNode();
		if (n instanceof PChainBox) { 
			PChainBox cb = (PChainBox) n;
			cb.setSelected(true);
			selectedChain=cb.getChain();
			// this will cause dataset selection to change,
			// which should cause other chains to be cleared.
			fireSelectionEvent();
			
		}
		else if (n instanceof PModule) {
			PChainBox cb = (PChainBox) n.getParent();
			cb.setSelected(true);
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