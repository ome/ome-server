/*
 * org.openmicroscopy.vis.chains.Toolbar
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

/** 
 * <p>Toolbar for the Chains application<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

import javax.swing.JToolBar;
import javax.swing.JLabel;

public class ToolBar extends JToolBar{
	
	protected JLabel statusLabel;
	
	protected CmdTable cmd;
	
	public ToolBar(CmdTable cmd) {
		super();
		this.cmd=cmd;
		
		//setAlignmentX(Component.RIGHT_ALIGNMENT);
		statusLabel = new JLabel();
		add(statusLabel);
		clearStatus();
	}
	
	public void clearStatus() {
		statusLabel.setText("Not Logged In");
	}
	
	public void setUserName(String s) {
		statusLabel.setText(s);
	}
	
}