/*
 * org.openmicroscopy.vis.chains.ome.ConnectionWorker
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
package org.openmicroscopy.vis.ome;
import org.openmicroscopy.remote.*;
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.*;
import org.openmicroscopy.vis.util.SwingWorker;
import javax.swing.JOptionPane;

/** 
 * <p>A {@link SwingWorker} subclass used to connect to the database and 
 * populate appropriate structures.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ConnectionWorker extends SwingWorker {
	
	private Controller controller;
	private Connection connection;

	private RemoteBindings remote=null;
	private Session session;
	private	Factory factory;
	
	private Modules modules;
	private Chains chains;
	
	private String URL;
	private String userName;
	private String passWord;
	

	
	public ConnectionWorker(Controller controller,Connection connection,
			String URL,String userName,String passWord) {
		this.controller = controller;
		this.connection = connection;
		this.URL = URL;
		this.userName = userName;
		this.passWord = passWord;  
	}
		
	
	/**
	 * The workhorse procedure. Loads the {@link RemoteBinding}, initializes the 
	 * subclasses from the remote framework, logs in, loads Modules, loads 
	 * Chains, and completes the setup
	 * 
	 */
	public Object construct() {
		try {
			//	XmlRpcCaller.TRACE_CALLS=true;
				remote = new RemoteBindings();
				if (remote != null) {
					remote.loginXMLRPC(URL,userName,passWord);
					loadCustomClasses();
					session = remote.getSession();
					factory = remote.getFactory();
					if (remote != null && session != null && factory != null) {
						connection.setSession(session);
						connection.setFactory(factory);
						modules  = new Modules(controller,connection);
						chains = new Chains(controller,connection);
						connection.setModules(modules);
						connection.setChains(chains);
						controller.completeWindows(); 
					}
				}
						
			} catch (Exception e) {
				e.printStackTrace();
				controller.cancelLogin();
			}
			return remote;
	}
	
	private void loadCustomClasses() {
		try {
			Class.forName("org.openmicroscopy.vis.ome.CNode");
			Class.forName("org.openmicroscopy.vis.ome.CModule");
			Class.forName("org.openmicroscopy.vis.ome.CChain");
			Class.forName("org.openmicroscopy.vis.ome.CLink");
			Class.forName("org.openmicroscopy.vis.ome.CChainExecution");
		}
		catch (ClassNotFoundException e) {
			System.err.println("Chains extension classes not found");
			System.exit(0);		
		}
	}
	
	/**
	 * Called after the {@link construct()} call finishes, either to complete 
	 * the connection initailization, or to indicate an error.
	 */
	public void finished() {
		if (remote != null && session != null && factory != null) {
			controller.closeStatusWindow();
		}
		else 
			JOptionPane.showMessageDialog(controller.getMainFrame(),
					"The login was not completed successfully.\nYour username and/or password may be incorrect, or there may be network problems. \n\nPlease try again.",
				"Login Difficulties",JOptionPane.ERROR_MESSAGE);
	}
	
	
}
