/*
 * org.openmicroscopy.vis.chains.ModulePaletteFrame
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

import org.openmicroscopy.vis.piccolo.PPaletteCanvas;
import org.openmicroscopy.vis.ome.Connection;
import edu.umd.cs.piccolo.PCanvas;
import javax.swing.BoxLayout;
import java.awt.Rectangle;

/** 
 * <p>The {@link ChainFrameBase} instance that holds the palette of modules.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ModulePaletteFrame extends ChainFrameBase {

	
	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	public static int X=10;
	public static int Y=10;
	public static int HEIGHT=400;
	public static int WIDTH=400;
	
	
	
	public ModulePaletteFrame(Controller controller,Connection connection) {
		super(controller,connection,"OME Chains Palette");
		setIconImage(controller.getIcon()); 
		getCanvas().setConfig(connection,controller);
		menuBar.setLoginsDisabled(true);
		toolBar.setLoggedIn(connection.getUserName());
		show();	
		getCanvas().scaleToSize();
	}
	
	public Rectangle getInitialBounds() {
		return new Rectangle(X,Y,WIDTH,HEIGHT);
	}
	
	/**
	 * The canvas for this frame is an instance of {@link PPaletteCanvas}
	 * @return a PPaletteCanvas
	 */
	public PCanvas createCanvas(Connection connection) {
		return new PPaletteCanvas();
	}

	public PPaletteCanvas getCanvas() {
		return (PPaletteCanvas) canvas;
	}
	
	/**
	 * Build a menu bar based on  a {@link CmdTable}
	 * @param cmd hash associating tags with actions
	 */
	private void buildMenuBar(CmdTable cmd) {
		menuBar = new MenuBar(cmd);
		setJMenuBar(menuBar);
	}

	/**
	 * This frame has a toolbar along with the canvas
	 */
	protected void layoutFrame() {
		contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		CmdTable cmd = controller.getCmdTable();
		buildMenuBar(cmd);
		
		toolBar = new ToolBar(cmd);
		contentPane.add(toolBar);
		
		contentPane.add(canvas);
	}
}
	