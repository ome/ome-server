/*
 * org.openmicroscopy.vis.chains.ome.CModule
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
 
 package org.openmicroscopy.vis.ome;
 
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.vis.piccolo.PModule;
import java.util.ArrayList;

 public class CModule extends RemoteModule {
	
	static {
		RemoteObjectCache.addClass("OME::Module",CModule.class);
	}
	
	private ArrayList pModules = new ArrayList();
	
	public CModule() {
		super();
	}
	
	public void addModuleWidget(PModule pMod) {
		pModules.add(pMod);
	}
	
	public ArrayList getModuleWidgets() {
		return pModules;
	}
	
	public void removeModuleWidget(PModule mod) {
		pModules.remove(mod);
	}
}