/*
 * org.openmicroscopy.vis.chains.ChainFrame
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

package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.piccolo.PChainCanvas;
import org.openmicroscopy.vis.piccolo.PChainLibraryCanvas;
import edu.umd.cs.piccolo.PCanvas;
import javax.swing.BoxLayout;
import java.awt.Rectangle;
import java.awt.event.WindowEvent;
import java.awt.event.WindowAdapter;


/** 
 * <p>An instance of {@link ChainFrameBase} that holds a chain being created<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ChainFrame extends ChainFrameBase {
	
	private ChainToolBar toolBar;
	PChainLibraryCanvas libraryCanvas;
	
	private static int X = 410;
	private static int Y=10;
	private static int WIDTH=400;
	private static int HEIGHT=400;
	
	public ChainFrame(Controller controller,Connection connection,int i,
		PChainLibraryCanvas libraryCanvas) {
		super(controller,connection,new String("OME Chain: "+i));
		layoutFrame();
		show();
		PChainCanvas chainCanvas = (PChainCanvas) canvas;
		chainCanvas.setFrame(this);
		chainCanvas.setLibraryCanvas(libraryCanvas);
	

		addWindowListener(new WindowAdapter() {
			public void windowClosed(WindowEvent e) {
				ChainFrame c = (ChainFrame) e.getWindow();
				Controller control = c.getController();
				control.disposeChainCanvas(c);
			}
			public void windowActivated(WindowEvent e) {
				ChainFrame c = (ChainFrame) e. getWindow();
				Controller control = c.getController();
				control.setCurrentChain(c);				
			}
		});
	
		
	}
	
	/**
	 * The canvas for this frame is an instance of {@link PChainCanvas}
	 * @return a PChainCanvas
	 */
	public PCanvas createCanvas(Connection connection) {
		return new PChainCanvas(connection);
	}
	
	public Rectangle getInitialBounds() {
		return new Rectangle(X,Y,WIDTH,HEIGHT);
	}
	
	/**
	 * This frame contains a toolbar along with the canvas 
	 * @see org.openmicroscopy.vis.chains.ChainFrameBase#layoutFrame()
	 */
	protected void layoutFrame() {
		contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		toolBar = new ChainToolBar(controller.getCmdTable());
		contentPane.add(toolBar);	
		contentPane.add(canvas);
	}
	
	/**
	 * When the user presses "save" on the toolbar, open up a {@link ChainSaveFrame}
	 *
	 */
	public void save() {
		ChainSaveFrame saveFrame  = new ChainSaveFrame(this);
		saveFrame.show();
	}
	
	/**
	 * Complete the saving of a chain
	 * 
	 * @param name the name for the new chain
	 * @param desc it's description
	 */
	public void completeSave(String name,String desc) {
		//System.err.println("finishing save.. "+name+","+desc);		
		PChainCanvas chainCanvas = (PChainCanvas) canvas;
		chainCanvas.save(name,desc);
	}
	
	/** 
	 * Update the status of the "save" button on the toolbar. 
	 * 
	 * @param v true if save should be enabled, else false 
	 */
	public void setSaveEnabled(boolean v) {
		if (toolBar != null)
			toolBar.setSaveEnabled(v);
	}

}