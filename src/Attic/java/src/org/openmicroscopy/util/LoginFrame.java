/*
 * org.openmicroscopy.alligator.LoginFrame;
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>, based on code by 
 * 		Douglas Creager
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.util;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;

/**
 * A simple JFrame for handling the log-in to the OME Remote Server
 *
 * This dialog requires the use of {@link LoginResponder} object,
 * which will calls that will be made when appropriate, based on
 * the user's selection of the "OK" or "Cancel" buttons. 
 *
 * Note that this class contains substantial code from {@ link LoginDialog}. 
 * This redundancy is necessary to support the separate modes of operation 
 * (login as dialog and login as frame). If Java supported multiple inheritance,
 * this redundancy would not be necessary.
 * 
 * @author Harry Hochheiser 
 * @version 2.1
 * @since OME2.1
 *
 */
public class LoginFrame
		extends JFrame
		implements ActionListener
{
	
		private LoginResponder responder;
		
		// From JBuilder
		JPanel panel1 = new JPanel();
		GridBagLayout gridBagLayout2 = new GridBagLayout();
		BorderLayout borderLayout1 = new BorderLayout();
		JLabel jURLLabel = new JLabel();
		public JTextField jURLField = new JTextField();
		JLabel jUsernameLabel = new JLabel();
		public JTextField jUsernameField = new JTextField();
		JLabel jPasswordLabel = new JLabel();
		public JPasswordField jPasswordField = new JPasswordField();
		JPanel jPanel1 = new JPanel();
		FlowLayout flowLayout1 = new FlowLayout();
		JButton jOKButton = new JButton();
		JButton jCancelButton = new JButton();
		Border border1;

		public  boolean  okay;

		public LoginFrame(LoginResponder responder) {
			super("Login to OME");
	
			this.responder = responder;
			try
			{
				jbInit();
				initUI();
				pack();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

	/**
     * Builds the dialog frame
     */ 

		private void jbInit() throws Exception {
			border1 = BorderFactory.createEmptyBorder(8,8,8,8);
			panel1.setLayout(gridBagLayout2);
			this.getContentPane().setLayout(borderLayout1);
			jURLLabel.setHorizontalAlignment(SwingConstants.LEADING);
			jURLLabel.setText("URL");
			jURLField.setMinimumSize(new Dimension(4, 19));
			jURLField.setText("http://localhost:8002/");
			jURLField.setColumns(25);
			jUsernameLabel.setText("Username");
			jUsernameField.setText("");
			jUsernameField.setColumns(25);
			jPasswordLabel.setText("Password");
			jPasswordField.setText("");
			jPasswordField.setColumns(25);
			jPanel1.setLayout(flowLayout1);
			jOKButton.setActionCommand("OK");
			jOKButton.setText("OK");
			jCancelButton.setActionCommand("Cancel");
			jCancelButton.setText("Cancel");
			panel1.setBorder(border1);
			panel1.setDebugGraphicsOptions(0);
			getContentPane().add(panel1, BorderLayout.CENTER);
			panel1.add(jURLField,             new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0
																																 ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 2, 6, 4), 0, 0));
			panel1.add(jURLLabel,            new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0
																																,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(4, 4, 6, 6), 0, 0));
			panel1.add(jUsernameLabel,            new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
																																		 ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(6, 4, 2, 6), 0, 0));
			panel1.add(jUsernameField,           new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0
																																	,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(6, 2, 2, 4), 0, 0));
			panel1.add(jPasswordLabel,     new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
																															,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(2, 4, 6, 6), 0, 0));
			panel1.add(jPasswordField,   new GridBagConstraints(1, 2, 1, 1, 0.0, 0.0
																													,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 2, 6, 4), 0, 0));				panel1.add(jPanel1,   new GridBagConstraints(0, 3, 2, 1, 0.0, 0.0
																										 ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(6, 4, 4, 4), 0, 0));
			jPanel1.add(jOKButton, null);
			jPanel1.add(jCancelButton, null);
		}

		/**
		 * Sets the action listeners and defaults
		 *
		 */
		private void initUI()
		{
			jOKButton.addActionListener(this);
			jCancelButton.addActionListener(this);
			getRootPane().setDefaultButton(jOKButton);
		}

	/**
	 * Calls the appropriate {@link LoginResponder} callback based on the
	 * user action
	 *
	 * @param e The action event to be processed
	 */
		public void actionPerformed(ActionEvent e)
		{
			boolean	okay = e.getActionCommand().equals("OK");
			if (okay)
				responder.loginOK();
			else
				responder.loginCancel();
		}
    
		
    /**
     *
     * @return The contents of the URL field
     */
    
		public String getURL() {
			return jURLField.getText();
		}
    
    /**
     * 
     * @return the contents of the user name field
     */

		public String getUserName() {
			return jUsernameField.getText();
		}
    
    /** 
     *
     * @return the contents of the password field.
     */
		public String getPassword() {
			return new String(jPasswordField.getPassword());
		}
}
