/*
 * org.openmicroscopy.vis.chains.Controller
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
import org.openmicroscopy.alligator.LoginDialog;

/** 
 * <p>Control and top-level management for the Chain-building application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Controller implements ApplicationController {
	
	private CmdTable cmd;
	private MainFrame mainFrame;
	private Connection connection = null;

	public Controller() {
		cmd = new CmdTable(this);
	}

	public CmdTable getCmdTable() {
			return cmd;	
	}
	
	public void setMainFrame(MainFrame mf) {
		this.mainFrame = mf;
	}
	
	public void doLogin() {
		System.err.println("login...");
		
		LoginDialog  loginDialog = new LoginDialog(mainFrame);
		loginDialog.show();
		if (loginDialog.isOk()) 
			connection =  new Connection(this,loginDialog.getURL(),loginDialog.getUserName(),loginDialog.getPassword());
	}

	public void cancelLogin() {
			connection = null;	
	}
	
	public void completeLogin() {
		mainFrame.setLoggedIn(true,connection);
	}
	
	public void doLogout() {
		System.err.println("logout...");
		updateDatabase();
		mainFrame.setLoggedIn(false,null);
	}
	
	public void quit() {
		System.exit(0);
	}
	
	private void updateDatabase() {
	}
	
}

