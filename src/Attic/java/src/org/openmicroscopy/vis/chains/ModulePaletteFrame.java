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
//import edu.umd.cs.piccolo.util.PBounds;
import javax.swing.JFrame;
import javax.swing.BoxLayout;
import java.awt.Rectangle;
import java.awt.Container;

/** 
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModulePaletteFrame extends JFrame {

	
	private Controller controller;
	private Container contentPane;
	
	public PPaletteCanvas canvas = null;
	

	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	public static int HEIGHT=400;
	public static int WIDTH=400;
	
	//private ChainFrameBase canvasFrame;
	
	public ModulePaletteFrame(Controller controller) {
		super("OME Chains Palette");
		setResizable(true);
		this.controller  = controller;
		contentPane = getContentPane();
		contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		
		CmdTable cmd = controller.getCmdTable();
		buildMenuBar(cmd);
		
		toolBar = new ToolBar(cmd);
		contentPane.add(toolBar);
		
		canvas = new PPaletteCanvas();
		getContentPane().add(canvas);
		setBounds(new Rectangle(10,10,WIDTH,HEIGHT));	
		//canvas.setBounds(10,10,WIDTH,HEIGHT);
		setIconImage(controller.getIcon()); 
		show();	
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
			toolBar.setLoggedIn(connection.getUserName());

			/*
			 * 
			 * This doesn't quite work. How can I find out how much space the 
			 * node/layer takes and resize accordingly?
			 PBounds b = canvas.getBufferedBounds();
			double canvasRatio = b.getWidth()/b.getHeight();
			int mywidth = (int) (canvasRatio*HEIGHT);

			setSize(mywidth,HEIGHT+toolBar.getHeight());
			invalidate(); */
			canvas.scaleToSize();
		}
		else {
			toolBar.setLoggedOut();
			canvas.logout();
			connection = null;
		}
	}
}
	