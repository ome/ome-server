/*
 * org.openmicroscopy.vis.chains.ChainFrameBase
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


import javax.swing.JFrame;
import javax.swing.WindowConstants;
import java.awt.Container;
import java.awt.Rectangle;
import edu.umd.cs.piccolo.PCanvas;
import org.openmicroscopy.vis.ome.Connection;


/** 
 * <p>Main operational frame  for the Chain-building application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public abstract class ChainFrameBase extends JFrame {
	
	protected final Controller controller;
	protected final Connection connection;
	protected Container contentPane;
	protected PCanvas canvas;
	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	public ChainFrameBase(Controller controller,Connection connection,
		String title){
		super(title);
		setResizable(true);
		
		this.controller = controller;
		this.connection =  connection;

		contentPane = getContentPane();
		// create a chain canvas and add it to this frame.
		canvas = createCanvas(connection);
		layoutFrame();
		//contentPane.add(canvas);
		
		setBounds(getInitialBounds());
		setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
		setIconImage(controller.getIcon());	
	}

	public Controller getController() {
			return controller;
	}
	
	public abstract PCanvas createCanvas(Connection connection);
	
	public abstract Rectangle getInitialBounds();
	
	protected abstract void layoutFrame();
}
