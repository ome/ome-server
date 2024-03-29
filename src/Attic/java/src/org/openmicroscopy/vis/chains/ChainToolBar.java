/*
 * org.openmicroscopy.vis.chains.ChainToolbar
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
import javax.swing.JToolBar;
import javax.swing.JButton;
import javax.swing.JLabel;
import java.awt.Dimension;

/** 
 * Toolbar for a {@link ChainFrame}. This toolbar contains a "save" button
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ChainToolBar extends JToolBar{
	
	protected JLabel nameLabel;
	
	protected CmdTable cmd;
	protected JButton saveChainButton;
	
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ChainToolBar(CmdTable cmd) {
		super();
		this.cmd=cmd;
		
		add(Box.createRigidArea(new Dimension(5,0)));
		
		saveChainButton = new JButton("Save Chain");
		saveChainButton.addActionListener(cmd.lookupActionListener("save chain"));
		setSaveEnabled(false);
		add(saveChainButton);
		add(Box.createHorizontalGlue());
		
		nameLabel = new JLabel();
		add(nameLabel);
		
		add(Box.createRigidArea(new Dimension(5,0)));
		
	}
	
	/**
	 * Set the state of the save button.
	 * 
	 * @param v true if saves are enabled, else false.
	 */
	public void setSaveEnabled(boolean v) {
		saveChainButton.setEnabled(v);
	}
	
	
}