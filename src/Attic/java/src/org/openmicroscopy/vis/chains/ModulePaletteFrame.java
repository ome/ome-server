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
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModulePaletteFrame extends ChainFrameBase {

	
	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	public static int HEIGHT=400;
	public static int WIDTH=400;
	
	//private ChainFrameBase canvasFrame;
	
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
		return new Rectangle(10,10,WIDTH,HEIGHT);
	}
	
	public PCanvas createCanvas(Connection connection) {
		return new PPaletteCanvas();
	}

	public PPaletteCanvas getCanvas() {
		return (PPaletteCanvas) canvas;
	}
	
	private void buildMenuBar(CmdTable cmd) {
		menuBar = new MenuBar(cmd);
		setJMenuBar(menuBar);
	}

	protected void layoutFrame() {
		contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		CmdTable cmd = controller.getCmdTable();
		buildMenuBar(cmd);
		
		toolBar = new ToolBar(cmd);
		contentPane.add(toolBar);
		
		contentPane.add(canvas);
	}
}
	