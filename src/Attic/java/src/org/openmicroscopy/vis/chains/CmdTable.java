/*
 * org.openmicroscopy.vis.chains.CmdTable
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
 
import java.util.Hashtable;
import java.awt.event.*;

/** 
 * <p>Mapping of functions to code via command strings.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class CmdTable {
	
	protected Hashtable actionMap;
	protected Controller controller;
	
	public CmdTable(Controller c) {
			this.controller = c;
			
			actionMap = new Hashtable();
			
			actionMap.put("login",new ActionListener() {
				public void actionPerformed(ActionEvent e) {
						controller.doLogin();
				}
			}); 
			
			actionMap.put("logout",new ActionListener() {
				public void actionPerformed(ActionEvent e) {
						controller.doLogout();
				}
			});
	}	
	
	public ActionListener lookupActionListener(String key) {
		return (ActionListener)actionMap.get(key);
	}
}