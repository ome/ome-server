/*
 * org.openmicroscopy.vis.chains.ome.Connection
 *
 * Copyright (C) 2003 Open Microscopy Environment
 * 		Massachusetts Institute of Technology,
 * 		National Institutes of Health,
 * 		University of Dundee
 * Author:  Harry Hochheiser <hsh@nih.gov>
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
 */
 
package org.openmicroscopy.vis.ome;

import org.openmicroscopy.remote.*;
import org.openmicroscopy.*;
import org.openmicroscopy.vis.util.SwingWorker;

/** 
 * <p>A wrapper class to handle discussion with the OME Database.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Connection {
	
	RemoteBindings remote=null;
	Session session;
	Factory factory;
	
	ModuleList modules;

	
	/***
	 * Creates a new connection to the database via XMLRPC. If successful, gets 
	 * session and factory objects that are used to access data in the database.
	 * This class should be a wrapper around all interactions with OME, insulating
	 * all visualization code from OME code.
	 * 
	 * @param controller The chains controller, which will be notified (via procedure call)
	 * 		when login is complete.
	 * @param URL		 
	 * @param userName
	 * @param passWord
	 */
	public Connection(final ApplicationController controller,
		final String URL,final String userName,final String passWord) {
		
		final SwingWorker worker = new SwingWorker() {
			public Object construct() {
				try {
					remote = new RemoteBindings();
					remote.loginXMLRPC(URL,userName,passWord);
				} catch (Exception e) {
					System.err.println(e);
					controller.cancelLogin();
				}
				return remote;
			}
			public void finished() {
				session = remote.getSession();
				factory = remote.getFactory();
				modules  = new ModuleList(factory);
				controller.completeLogin();
				// dummy
				modules.dump();
				
			}
		};
		worker.start();
	}
	
	public String getUserName() {		
		Attribute user = session.getUser();
		return new String(user.getStringElement("FirstName")+" " +
			user.getStringElement("LastName"));
	}
}
