/*
 * org.openmicroscopy.vis.chains.Controller
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
import org.openmicroscopy.vis.ome.ApplicationController;
import org.openmicroscopy.util.LoginDialog;
import javax.swing.JFrame;
import java.util.ArrayList;
import java.util.Iterator;

/** 
 * <p>Control and top-level management for the Chain-building application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Controller implements ApplicationController {
	
	private CmdTable cmd;
	private ModulePaletteFrame mainFrame;
	private ChainLibraryFrame library;
	
	ArrayList canvasFrames = new ArrayList();
	private Connection connection = null;
	private int chainCanvasCount = 0;

	public Controller() {
		cmd = new CmdTable(this);
	}

	public CmdTable getCmdTable() {
			return cmd;	
	}
	
	public void setMainFrame(ModulePaletteFrame mf) {
		this.mainFrame = mf;
	}
	
	public JFrame getMainFrame() {
		return mainFrame;
	}
	
	public ChainLibraryFrame getLibrary() {
			return library;
	}
	
	/**
	 * Creates the database connection via results from a LoginDialog.
	 * This database connecdtion will spawn a thread and call completeLogin(),
	 * below.<p>
	 *
	 */
	public void doLogin() {
		System.err.println("login...");
		
		LoginDialog  loginDialog = new LoginDialog(mainFrame);
		loginDialog.show();
		if (loginDialog.isOk()) 
			connection =  new Connection(this,loginDialog.getURL(),
				loginDialog.getUserName(),loginDialog.getPassword());
	}

	public void cancelLogin() {
			connection = null;	
	}
	
	public void completeLogin() {
		mainFrame.setLoggedIn(true,connection);
		library = new ChainLibraryFrame(this,connection); 
	}
	
	public void doLogout() {
		System.err.println("logout...");
		updateDatabase();
		mainFrame.setLoggedIn(false,connection);
		removeCanvasFrames();
		chainCanvasCount = 0;
	}
	
	private void removeCanvasFrames() {
		Iterator iter = canvasFrames.iterator();

		ChainFrame canvasFrame;
		while (iter.hasNext()) {
			canvasFrame = (ChainFrame) iter.next();
			canvasFrame.dispose();
		}
		canvasFrames = new ArrayList();
	}
	
	public void quit() {
		System.exit(0);
	}
	
	/**
	 * A placeholder (for now) that might eventually be used to make sure that 
	 * the database is updated before the program exits.
	 *
	 */
	public void updateDatabase() {
	}
		
		
	public void newChain() {
		System.err.println("new chain");
		ChainFrame canvasFrame = 
			new ChainFrame(this,connection,chainCanvasCount++);
		canvasFrames.add(canvasFrame);
	}
	
	public void disposeChainCanvas(ChainFrame c) {
		canvasFrames.remove(c);
	}
}

