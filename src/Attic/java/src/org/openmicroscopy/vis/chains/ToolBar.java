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

import javax.swing.Box;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JToolBar;
import javax.swing.SwingConstants;
import java.awt.Dimension;

/** 
 * Toolbar for a {@link ModulePaletteFrame}. This toolbar contains a 
 * "New Chain" button, and a text label indicating the name of the OME user
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ToolBar extends JFrame{
	
	protected JLabel statusLabel;
	protected JPanel panel;
	
	protected CmdTable cmd;
	protected JButton newChainButton;
	
	protected JButton viewResultsButton;
	
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ToolBar(CmdTable cmd) {
		super("OME Chains: Menu Bar");
		this.cmd=cmd;
		
		JToolBar toolbar = new JToolBar();
		
		toolbar.add(Box.createRigidArea(new Dimension(5,0)));
		toolbar.setFloatable(false);
		newChainButton = new JButton("New Chain");
		newChainButton.addActionListener(cmd.lookupActionListener("new chain"));
		newChainButton.setEnabled(false);
		toolbar.add(newChainButton);
		
		toolbar.add(Box.createRigidArea(new Dimension(5,0)));
		
		viewResultsButton = new JButton("View Results");
		viewResultsButton.
			addActionListener(cmd.lookupActionListener("view results"));
		viewResultsButton.setEnabled(false);
		toolbar.add(viewResultsButton);
		
		toolbar.add(Box.createHorizontalGlue());
		toolbar.add(Box.createRigidArea(new Dimension(40,0)));
		statusLabel = new JLabel();
		statusLabel.setHorizontalAlignment(SwingConstants.RIGHT);
		statusLabel.setMinimumSize(new Dimension(150,30));
		statusLabel.setPreferredSize(new Dimension(150,30));
		toolbar.add(statusLabel);
		
		toolbar.add(Box.createRigidArea(new Dimension(30,0)));
		getContentPane().add(toolbar);
		pack();
		show();
	
		setResizable(false);
		
	}
	
	/**
	 * set the status to be logged in
	 */
	public void setLoggedIn(String s) {
		statusLabel.setText(s);
	}
	
	/**
	 * Set the state of the New chain button
	 * @param v true if button should be enabled. else false.
	 */
	public void setEnabled(boolean v) {
		newChainButton.setEnabled(v);
		viewResultsButton.setEnabled(v);
	}
}