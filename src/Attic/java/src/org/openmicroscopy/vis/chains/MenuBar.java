/*
 * org.openmicroscopy.vis.chains.MenuBar
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

import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import java.awt.event.ActionListener;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import javax.swing.KeyStroke;
import java.awt.Toolkit;

/** 
 * <p>Menu selections for chains application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class MenuBar extends JMenuBar {
	
	public static int COMMAND_MASK=Toolkit.getDefaultToolkit().getMenuShortcutKeyMask();
	private JMenuItem logoutItem;
	
	public MenuBar(CmdTable cmd) {
		JMenu file = createFileMenu(cmd);
		
		this.add(file);
	}
	
	protected JMenu createFileMenu(CmdTable cmd) {
		
		JMenu menu = new JMenu("File");
		
		logoutItem = createMenuItem("Logout..",KeyEvent.VK_L,InputEvent.SHIFT_MASK,
			cmd.lookupActionListener("logout"));
		logoutItem.setEnabled(false);
		menu.add(logoutItem);
		
		JMenuItem quit = createMenuItem("Quit..",KeyEvent.VK_Q,0,cmd.lookupActionListener("quit"));
		menu.add(quit);
		
		return menu;
	}
	
	private JMenuItem createMenuItem(String text,int key,int mask,ActionListener listener) {
		JMenuItem item;
		
		item = new JMenuItem(text);
		item.setAccelerator(KeyStroke.getKeyStroke(key,COMMAND_MASK|mask));
		item.addActionListener(listener);
		
		return item;
	}	
	
	public void setLoginsDisabled(boolean v) {
		// v is true if login should be disabled and logout enabled,
		// false if login should be enabled and logout disabled.
		logoutItem.setEnabled(v);
	}
}
