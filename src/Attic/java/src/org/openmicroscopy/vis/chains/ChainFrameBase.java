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
 * <p>Abstract superclass for functionality common to all JFrames 
 * in chain-building tool<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
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
		
		canvas = createCanvas(connection);
		
		setBounds(getInitialBounds());
		setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
		setIconImage(controller.getIcon());	
	}

	/**
	 * @return the {@link Controller} associated with the window
	 */
	public Controller getController() {
			return controller;
	}
	
	/**
	 * Build the piccolo canvas that is placed in this frame
	 * 
	 * @param connection The {@link Connection} to the database
	 * @return a piccolo canvas of the appropriate subclass of {@link PCanvas}
	 */
	public abstract PCanvas createCanvas(Connection connection);
	
	/**
	 * @return the initial bounds of the frame
	 */
	public abstract Rectangle getInitialBounds();
	
	/**
	 * Adds the desired elements to the frame and lays them out.
	 *
	 */
	protected abstract void layoutFrame();
}
