/*
 * org.openmicroscopy.vis.piccolo.PChainLibraryCanvas
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

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.PCamera;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ChainInfo;
import org.openmicroscopy.vis.ome.Chains;
import org.openmicroscopy.Chain;
import org.openmicroscopy.vis.dnd.ChainSelection;
import java.util.Iterator;
import java.awt.Font;
import java.awt.dnd.DragSourceAdapter;
import java.awt.dnd.DragSourceEvent;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureEvent;



/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainLibraryCanvas extends PCanvas implements DragGestureListener {
	
	private static float VGAP=20f;
	private static float HGAP=10f;
	private static Font nameFont = new Font("Helvetica",Font.BOLD,18);
	private Connection connection=null;
	private int modCount;
	private PLayer layer;
	
	private float x=HGAP;
	private float y=VGAP;
	
	private PLinkLayer linkLayer;
	
	private float chainHeight= 0;
	private float chainWidth = 0;
	
	
	
	private int selectedChainID;
	private boolean chainSelected;
	
	private DragSourceAdapter dragListener;
	private DragSource dragSource;

	public PChainLibraryCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		linkLayer = new PLinkLayer();
		getCamera().addLayer(linkLayer);
		
		removeInputEventListener(getZoomEventHandler());
		removeInputEventListener(getPanEventHandler());
		addInputEventListener(new PChainLibraryEventHandler(this)); 
		linkLayer.setPickable(false);
		linkLayer.moveToFront();
		
		dragListener = new DragSourceAdapter() {
				public void dragExit(DragSourceEvent dse) {
				}
			};
		dragSource = new DragSource();
		dragSource.createDefaultDragGestureRecognizer(this,
			DnDConstants.ACTION_COPY,this);
		PCamera camera = getCamera();
		camera.addInputEventListener(new PPaletteToolTipHandler(camera));
		populate();		
		
	}
	
	private void populate() {

	
		ChainInfo info;

		Chains chains = connection.getChains();
		
		Iterator iter = chains.iterator();
		
		// draw each of them.
		while (iter.hasNext()) {
			info = (ChainInfo) iter.next();
			drawChain(info);
		}
		
	}
	
	private void drawChain(ChainInfo info) {
		// draw the modules 
		chainHeight = 0;
		chainWidth = 0;
		Chain chain = info.getChain();
		
		
		PText name = new PText(chain.getName());
		name.setFont(nameFont);
		name.setPickable(false);
		layer.addChild(name);
		name.setOffset(x,y);
		name.setScale(2);
		float top=y;
		chainHeight += name.getBounds().getHeight()+VGAP;
		y += VGAP+name.getBounds().getHeight();
		
		PChain p = new PChain(connection,info,layer,linkLayer,0,y);
		
 		y += p.getHeight()+VGAP;
 		decorateChain(chain.getID(),top,y,p.getWidth());
		x= HGAP;
		y += VGAP;
	}
	
	public void decorateChain(int id,float top,float bottom,float width) {
		float height = bottom-top;
		PChainBox box = new PChainBox(id,HGAP,top,width,height);
		layer.addChild(box);
		box.moveToBack();
	}
	
	
	public void scaleToSize() {
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,0);
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX(),b.getY(),b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER); 
	}
	
	public void setSelectedChainID(int id) {
		selectedChainID=id;
		System.err.println("selected chain "+id);
		chainSelected = true;
	}
	
	public int getSelectedChainID() {
		return selectedChainID;
	}
	
	public void clearChainSelected() {
		System.err.println("clear chain selection");
		chainSelected = false;
	}
	
	public boolean isChainSelected() { 
		return chainSelected;
	}
	
	public void dragGestureRecognized(DragGestureEvent event) {
		if (chainSelected == true) {
			Integer id = new Integer(selectedChainID);
			ChainSelection c = new ChainSelection(id);
			System.err.println("dragging.chain.. chain selection."+id);
			dragSource.startDrag(event,DragSource.DefaultMoveDrop,c,dragListener);
		}
	}
}
