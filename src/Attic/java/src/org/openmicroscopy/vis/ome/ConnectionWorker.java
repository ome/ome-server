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
import org.openmicroscopy.*;
import org.openmicroscopy.vis.util.SwingWorker;
import javax.swing.JOptionPane;
import javax.swing.JWindow;
import javax.swing.JLabel;
import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.Box;
import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.Rectangle;

public class ConnectionWorker extends SwingWorker {
	
	private ApplicationController controller;
	private Connection connection;

	private RemoteBindings remote=null;
	private Session session;
	private	Factory factory;
	
	private Modules modules;
	private Chains chains;
	
	private String URL;
	private String userName;
	private String passWord;
	
	private JWindow status;
	private JLabel statusLabel;
	
	public ConnectionWorker(ApplicationController controller,Connection connection,
			String URL,String userName,String passWord) {
		this.controller = controller;
		this.connection = connection;
		this.URL = URL;
		this.userName = userName;
		this.passWord = passWord;  
		buildStatusWindow();
	}
		
	private void buildStatusWindow() {
		status = new JWindow();
		JPanel content = (JPanel) status.getContentPane();
		content.setLayout(new BoxLayout(content,BoxLayout.X_AXIS));
		content.add(Box.createRigidArea(new Dimension(5,0)));
		
		JPanel panel = new JPanel();
		panel.setLayout(new BoxLayout(panel,BoxLayout.Y_AXIS));
		content.add(panel);
		
		panel.add(Box.createRigidArea(new Dimension(0,5)));		
		JLabel title = new JLabel("Loading...");
		panel.add(title);
		statusLabel = new JLabel("OME Database Contents               ");
		panel.add(Box.createRigidArea(new Dimension(0,5)));
		panel.add(statusLabel);
		status.pack();
		Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
		Rectangle bounds = status.getBounds();
		int x = (int) (screen.getWidth()-bounds.getWidth())/2;
		int y = (int) (screen.getHeight()-bounds.getHeight())/2;
		status.setBounds(x,y,(int)bounds.getWidth(),(int)bounds.getHeight());
		status.setVisible(true);
			
	}
	
	public Object construct() {
		try {
			//	XmlRpcCaller.TRACE_CALLS=true;
				remote = new RemoteBindings();
				if (remote != null) {
					Class.forName("org.openmicroscopy.vis.ome.CNode");
					Class.forName("org.openmicroscopy.vis.ome.CModule");
					remote.loginXMLRPC(URL,userName,passWord);
					session = remote.getSession();
					factory = remote.getFactory();
					if (session != null && factory != null) {
						modules  = new Modules(this,factory);
						chains = new Chains(this,factory);
						setStatusLabel("Palette and Library");
					}
				}
						
			} catch (Exception e) {
				//System.err.println(e);
				status.setVisible(false);
				controller.cancelLogin();
			}
			return remote;
	}
	
	public void finished() {
		if (remote != null && session != null && factory != null) {
			connection.setSession(session);
			connection.setFactory(factory);
			connection.setModules(modules);
			connection.setChains(chains);
			controller.completeLogin();
			status.setVisible(false);
		}
		else 
			JOptionPane.showMessageDialog(controller.getMainFrame(),
					"The login was not completed successfully.\nYour username and/or password may be incorrect, or there may be network problems. \n\nPlease try again.",
				"Login Difficulties",JOptionPane.ERROR_MESSAGE);
	}
	
	public void setStatusLabel(String s) {
		statusLabel.setText(s);
	}
}
