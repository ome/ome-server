/*
 * org.openmicroscopy.vis.chains.BrowserFrame;
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
import org.openmicroscopy.vis.piccolo.PBrowserCanvas;
import org.openmicroscopy.vis.piccolo.PChainLibraryCanvas;
import edu.umd.cs.piccolo.PCanvas;
import javax.swing.BoxLayout;
import java.awt.Rectangle;
import java.awt.event.WindowEvent;
import java.awt.event.WindowAdapter;



/** 
 * <p>An instance of {@link ChainFrameBase} that holds a view of 
 * analysis results.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class BrowserFrame extends ChainFrameBase {
	
	PChainLibraryCanvas libraryCanvas;
	
	private static int X = 10;
	private static int Y=700;
	private static int WIDTH=400;
	private static int HEIGHT=400;
	
	private ResultToolBar toolbar;
	
	public BrowserFrame(Controller controller,Connection connection) {
		super(controller,connection,new String("OME Images"));
		layoutFrame();
		show();
		PBrowserCanvas browserCanvas = (PBrowserCanvas) canvas;

		addWindowListener(new WindowAdapter() {
			public void windowClosed(WindowEvent e) {
				BrowserFrame b = (BrowserFrame) e.getWindow();
				Controller control = b.getController();
				control.disposeBrowserFrame();
			}
		});
	
		
	}
	
	/**
	 * The canvas for this frame is an instance of {@link PChainCanvas}
	 * @return a PChainCanvas
	 */
	public PCanvas createCanvas() {
		return new PBrowserCanvas(connection);
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
		contentPane.add(canvas);
	}
}