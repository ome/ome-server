/*
 * org.openmicroscopy.vis.chains.CanvasFrame
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

import java.awt.Rectangle;
import javax.swing.JFrame;
import javax.swing.BoxLayout;
import java.awt.Container;

import org.openmicroscopy.vis.piccolo.PChainCanvas;
import org.openmicroscopy.vis.ome.Connection;

/** 
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class CanvasFrame extends JFrame {
	
	private Controller controller;
	private Container contentPane;
	private PChainCanvas canvas;
	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	private ModulePaletteFrame paletteFrame;
	
	public CanvasFrame(Controller c) {
		super("OME Chains");
		setResizable(true);
		this.controller = c;
		contentPane = getContentPane();
		
		contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		
		CmdTable cmd = controller.getCmdTable();	
		buildMenuBar(cmd);
		
		toolBar = new ToolBar(cmd);
		contentPane.add(toolBar);
		
		// create a chain canvas and add it to this frame.
		canvas = new PChainCanvas();
		contentPane.add(canvas);
		
		setBounds(new Rectangle(10,10,700,700));		
	}
	
	private void buildMenuBar(CmdTable cmd) {
		menuBar = new MenuBar(cmd);
		setJMenuBar(menuBar);
	}
		
	/**
	 * Called by the Controller object after the connection has 
	 * completed the database initialization
	 * 
	 * @param v  true if the login was successsful, otherwise false
	 * @param connection the databse connection object.
	 */
	public void setLoggedIn(boolean v,Connection connection) {
		menuBar.setLoginsDisabled(v);
		if (v == true) {
			canvas.setConnection(connection);
			toolBar.setUserName(connection.getUserName());
			// create a pallete, show it on the screen, make it visible.
			paletteFrame = new ModulePaletteFrame(connection);
			paletteFrame.setJMenuBar(menuBar);
		}
		else {
			canvas.logout();
			paletteFrame.dispose();
			paletteFrame = null;
			connection = null;
			toolBar.clearStatus();
		}
	}
}
