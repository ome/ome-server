/*
 * org.openmicroscopy.vis.chains.ome.Modules
 *
 * Copyright (C) 2003 Open Microscopy Environment
 * 		Massachusetts Institute of Technology,
 * 		National Institutes of Health,
 * 		University of Dundee 
 * * Author:  Harry Hochheiser <hsh@nih.gov>
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
 *Lab
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
 
package org.openmicroscopy.vis.ome;

import java.util.HashMap;
import java.util.List;
import java.util.Iterator;
import java.util.Collection;
import org.openmicroscopy.Factory;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
//import org.openmicroscopy.remote.RemoteModuleCategory;

/** 
 * <p>A wrapper class to handle discussion with the OME Database.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Modules extends HashMap {
	
	public Modules(Factory factory) {
	
		super();
		// Get all of the modules that are avialable.
		List mods = factory.findObjects("OME::Module",null);
		
		// populate each of them.
		Iterator iter = mods.iterator();
		while (iter.hasNext()) {
			RemoteModule mod = (RemoteModule) iter.next();
			populateModule(mod);
			Integer id = new Integer(mod.getID());
			put(id,new ModuleInfo(mod));
		}
	}
	
	
	public Iterator iterator() {
		
		Collection c = values();
		return c.iterator();
		
	}
	public void dump() {
		Iterator iter = iterator();
		while (iter.hasNext()) {
			ModuleInfo modinf = (ModuleInfo) iter.next();
			RemoteModule mod = modinf.getModule();
			dumpModule(mod);
		}
	}
	
	/**
	 * Access individual fields of a module. By default, accessing each of 
	 * these fields requires an XMLRPC call to the OME Server. By performing 
	 * each of these calls and ignoring the results, we can lump all of the 
	 * database overhead together in one place, thus removing the possibility
	 * of repeated delays due to database latencies.<p>
	 * 
	 * This code may need to be revisited when OME server and client-side 
	 * caching are reworked.<p>
	 * 
	 * @param mod The module to be populated.
	 */
	private void populateModule(RemoteModule mod) {
				
		mod.getName();
		System.err.println("Loading Module..."+mod.getName());
		mod.getDescription();
		mod.getLocation();
		mod.getNewFeatureTag();
		// get inputs & outputs?
		List params = mod.getInputs();
		//System.err.println("...Inputs...");
		populateParameters(params);
		params = mod.getOutputs();
		//System.err.println("...Outputs..");
		populateParameters(params);
		//System.err.println("category is "+mod.getCategory());
		//RemoteModuleCategory category = mod.getCategory();
		
	}
	
	/**
	 * Populating the list of parameters - formal inputs or outputs.<p> 
	 * 
	 * @param params parameter list to be populated.
	 */
	private void populateParameters(List params) {
		FormalParameter param;
		
		Iterator iter = params.iterator();
		while (iter.hasNext()) {
			param = (FormalParameter) iter.next();
			//System.err.println("Parameter: "+param.getParameterName());
			param.getList();
			param.getOptional();
			SemanticType semType = param.getSemanticType();
			if (semType != null)
				semType.getName();
		}
	}
	
	public ModuleInfo getModuleInfo(int i) {
		return (ModuleInfo) get(new Integer(i));
	}
	
	public void setModuleInfo(int i,ModuleInfo info) {
		Integer id = new Integer(i);
		remove(id);
		put(id,info);	
	}
	/**
	 * Utility procedures for dumping a module and its contents to stderr.<p>
	 * 
	 * @param mod
	 */
	private void dumpModule(RemoteModule mod) {
		System.err.println("MODULE: "+mod.getName());
		System.err.println("Description: "+mod.getDescription());
		System.err.println("Location: "+mod.getLocation());
		System.err.println("Feature Tag: "+mod.getNewFeatureTag());
		List params = mod.getInputs();
		System.err.println("Input Size: "+params.size());
		dumpParams(params);
		params = mod.getOutputs();
		System.err.println("Output Size: "+params.size());
		dumpParams(params);
	}
	
	private void dumpParams(List params) {
		FormalParameter param;
		String sName;
		int i = 0;
		
		Iterator iter = params.iterator();
		while (iter.hasNext()) {
			param = (FormalParameter) iter.next();
			String pName = param.getParameterName();
			SemanticType semType = param.getSemanticType();
			if (semType!= null)
				sName = semType.getName();
			else 
				sName = "";
			System.err.println((i++)+") Parameter Name: "+pName+", Semantic Type: "+sName);
		}
	}
	
}
