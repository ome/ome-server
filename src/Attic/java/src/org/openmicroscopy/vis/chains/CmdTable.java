/*
 * org.openmicroscopy.vis.chains.CmdTable
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
 
import java.util.Hashtable;
import java.awt.event.*;

/** 
 * <p>Mapping of functionality to code via named strings. Used to separate out
 *  named actions from the code that handles them, thus reducing redundancy in 
 *  handlers for toolbars as opposed to menu bars, etc.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class CmdTable {
	
	protected Hashtable actionMap;
	protected Controller controller;
	
	/**
	 * 
	 * @param c the {@link Controller} object for the current instance
	 */
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
					
		actionMap.put("quit",new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				controller.quit();
			}
		});
					
		actionMap.put("new chain",new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				controller.newChain();
			}
		}); 
		
		actionMap.put("save chain",new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				controller.saveChain();
			}
		});
	}	
	
	/**
	 * 
	 * @param key the name of an action
	 * @return the corresponding {@link ActionListener}
	 */
	public ActionListener lookupActionListener(String key) {
		return (ActionListener)actionMap.get(key);
	}
}