/*
 * org.openmicroscopy.vis.chains.MenuBar
 *
 * Copyright (C) 2003 Open Microscopy Environment, MIT
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

package org.openmicroscopy.vis.chains;

import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import java.awt.event.*;
import javax.swing.KeyStroke;

/** 
 * <p>Menu selections for chains application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class MenuBar extends JMenuBar {
	
	public MenuBar(CmdTable cmd) {
		JMenu file = createFileMenu(cmd);
		
		this.add(file);
	}
	
	protected JMenu createFileMenu(CmdTable cmd) {
		
		JMenu menu = new JMenu("File");
		JMenuItem item = createMenuItem("Login..",KeyStroke.getKeyStroke(KeyEvent.VK_L,0),
			cmd.lookupActionListener("login"));
		menu.add(item);
		
		return menu;
	}
	
	private JMenuItem createMenuItem(String text,KeyStroke k,ActionListener listener) {
		JMenuItem item;
		
		item = new JMenuItem(text);
		item.setAccelerator(k);
		item.addActionListener(listener);
		
		return item;
	}	
}
