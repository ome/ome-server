/*
 * org.openmicroscopy.vis.chains.ome.Modules
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
 */
 
package org.openmicroscopy.vis.ome;

import java.util.HashMap;
import java.util.List;
import java.util.Iterator;
import java.util.Collection;
import java.util.ArrayList;
import org.openmicroscopy.Factory;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.Module;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import org.openmicroscopy.ModuleCategory;
import org.openmicroscopy.vis.chains.Controller;


/** 
 * <p>A class to handle the modules in the OME database
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Modules {
	
	
	private HashMap byId = new HashMap();

	// all of the modules that don't have categories
	private ArrayList uncategorizedModules = new ArrayList();
	
	private ArrayList rootCategories = new ArrayList();
		
	public Modules(Controller  controller,Factory factory) {
		Module mod;
		Integer id;
		ModuleCategory cat;
		
		// Get all of the modules that are avialable.
		List mods = factory.findObjects("OME::Module",null);
		
		// populate each of them.
		Iterator iter = mods.iterator();
		while (iter.hasNext()) {
			mod = (Module) iter.next();
			populateModule(mod);
			id = new Integer(mod.getID());
			controller.setStatusLabel("Module.."+mod.getName());
			byId.put(id,mod);

			cat = mod.getCategory();
			if (cat == null) {
				uncategorizedModules.add(mod);
			}
		}
		
		List cats = factory.findObjects("OME::Module::Category",null);
		iter = cats.iterator();
		while (iter.hasNext()) {
			cat = (ModuleCategory) iter.next();
			//connection.setStatusLabel("Category... "+cat.getName());
			controller.setStatusLabel("Module.."+cat.getName());
			if (cat.getParentCategory() == null) {
				rootCategories.add(cat);
			}
				
		}
		
		
	}
	
	
	public Iterator iterator() {
		
		Collection c = byId.values();
		return c.iterator();
		
	}
	
	public Iterator uncategorizedModuleIterator() {
		return uncategorizedModules.iterator();
	}
	
	public Iterator rootCategoryIterator() {
		return rootCategories.iterator();
	}
	
	public void dump() {
		Iterator iter = iterator();
		while (iter.hasNext()) {
			Module mod = (Module) iter.next();
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
	private void populateModule(Module mod) {
				
		mod.populate();
		//System.err.println("Loading Module..."+mod.getName());
		// get inputs & outputs?
		List params = mod.getInputs();
		//populateParameters(params);
		params = mod.getOutputs();
		//populateParameters(params);
	}
	
	/**
	 * Populating the list of parameters - formal inputs or outputs. Deprecated.
	 * Calling this procedure leads to some bugs, without any obvious gain. 
	 * This call will hopefully soon be replaced by a call that caches the 
	 * whole list.
	 * <p> 
	 * 
	 * @param params parameter list to be populated.
	 */
	private void populateParameters(List params) {
		FormalParameter param;
		
		Iterator iter = params.iterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
		//	System.err.println("parameter object is "+obj);
			param = (FormalParameter) obj;
		//	System.err.println("Parameter: "+param.getParameterName());
			param.getList();
			param.getOptional();
			SemanticType semType = param.getSemanticType();
			//System.err.println("semantic type is "+semType);
			if (semType != null &&
				semType.toString().compareTo(">>OBJ:NULL") !=0 )
				semType.getName();
		//	else 
		//		System.err.println("got a null semantic type");
		}
	}
	
	public CModule getModule(int i) {
		return (CModule) byId.get(new Integer(i));
	}
	
	

	/**
	 * Utility procedures for dumping a module and its contents to stderr.<p>
	 * 
	 * @param mod
	 */
	private void dumpModule(Module mod) {
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
		//	System.err.println((i++)+") Parameter Name: "+pName+", Semantic Type: "+sName);
		}
	}
	
}
