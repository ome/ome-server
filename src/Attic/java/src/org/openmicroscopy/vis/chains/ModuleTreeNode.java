/*
 * org.openmicroscopy.vis.chains.ModuleTreeNode
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
import javax.swing.tree.DefaultMutableTreeNode;
import org.openmicroscopy.OMEObject;
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteModuleCategory;

/* A node in the {@link JTree} list of nodes that we put in the 
 * {@link ModulePaletteFrame}.
* 
* @author Harry Hochheiser
* @version 2.1
* @since OME2.1
*/

public class ModuleTreeNode extends DefaultMutableTreeNode {
	
	
	/**
	 * the name of the node
	 * 
	 */
	private String name;
	
	/**
	 * It's also got an ID. - defaults to -1, meaning not an ome object
	 */
	private int id=-1;
	
	
	/**
	 * The OME Object for which we are building this.
	 *
	 */
	
	private OMEObject object = null;
	
	public ModuleTreeNode() {
		super();
	}
	
	public ModuleTreeNode(String s,int id) {
		super();
		name = s;
		this.id = id;
	}
	
	public ModuleTreeNode(String s) {
		super();
		name = s;
	}
	
	public ModuleTreeNode(OMEObject object) {
		this.object = object;
	}
	
	public int getID() {
		if (object != null)
			return object.getID();
		else
			return -1;
	}
	
	public String toString() {
		if (object != null) {
			if (object instanceof RemoteModule)
				return ((RemoteModule) object).getName();
			else if (object instanceof RemoteModuleCategory)
				return ((RemoteModuleCategory) object).getName();
			else
				return name;
		}
		else
			return name;
	}
	
	public OMEObject getObject() {
		return object;
	}
}