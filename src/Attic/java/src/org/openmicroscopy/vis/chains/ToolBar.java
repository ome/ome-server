/*
 * org.openmicroscopy.vis.chains.Toolbar
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

/** 
 * <p>Toolbar for the Chains application<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

import javax.swing.Box;
import javax.swing.JToolBar;
import javax.swing.JButton;
import javax.swing.JLabel;
import java.awt.Dimension;

public class ToolBar extends JToolBar{
	
	protected JLabel statusLabel;
	
	protected CmdTable cmd;
	protected JButton newChainButton;
	
	public ToolBar(CmdTable cmd) {
		super();
		this.cmd=cmd;
		
		add(Box.createRigidArea(new Dimension(5,0)));
		
		newChainButton = new JButton("New Chain");
		newChainButton.addActionListener(cmd.lookupActionListener("new chain"));
		newChainButton.setEnabled(false);
		add(newChainButton);
		add(Box.createHorizontalGlue());
		
		statusLabel = new JLabel();
		add(statusLabel);
		
		setLoggedOut();
		add(Box.createRigidArea(new Dimension(5,0)));
		
	}
	
	public void setLoggedOut() {
		statusLabel.setText("Not Logged In");
		newChainButton.setEnabled(false);
	}
	
	public void setLoggedIn(String s) {
		statusLabel.setText(s);
		newChainButton.setEnabled(true);
	}
	
}