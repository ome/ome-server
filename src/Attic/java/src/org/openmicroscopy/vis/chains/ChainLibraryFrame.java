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
import org.openmicroscopy.vis.piccolo.PChainLibraryCanvas;
import edu.umd.cs.piccolo.PCanvas;
import java.awt.Rectangle;


/** 
 * <p>An instance of {@link ChainFrameBase} that holds the chain library<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ChainLibraryFrame extends ChainFrameBase {
	
	public ChainLibraryFrame(Controller controller,Connection connection) {
		super(controller,connection,new String("OME Chain Library"));
		layoutFrame();
		show();
		PChainLibraryCanvas libraryCanvas = (PChainLibraryCanvas) canvas;
		libraryCanvas.scaleToSize();
	}
	
	/**
	 * The canvas for this frame is an instance of {@link PChainLibraryCanvas}
	 * @return a PChainLibraryCanvas
	 */
	public PCanvas createCanvas(Connection connection) {
		return new PChainLibraryCanvas(connection);
	}
	
	public Rectangle getInitialBounds() {
		return new Rectangle(10,450,400,400);
	}
	
	protected void layoutFrame() {
		contentPane.add(canvas);
	}
	
	public PChainLibraryCanvas getCanvas() {
		return (PChainLibraryCanvas) canvas;
	}
}