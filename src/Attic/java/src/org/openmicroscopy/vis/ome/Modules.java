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
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.Module;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import org.openmicroscopy.ModuleCategory;
import org.openmicroscopy.vis.chains.Controller;


/** 
 * <p>A class to handle the modules in the OME database
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class Modules {
	
	
	private HashMap byId = new HashMap();

	/**
	 * all of the modules that don't have categories
	 */
	private ArrayList uncategorizedModules = new ArrayList();
	
	/**
	 * The root categories in the database
	 */
	private ArrayList rootCategories = new ArrayList();
		
	public Modules(Controller  controller,Connection connection) {
		Module mod;
		Integer id;
		ModuleCategory cat;
		
		// Get all of the modules that are avialable.
		List mods = connection.loadModules();
		
		
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
		
		// load the categories
		List cats = connection.loadCategories();
		iter = cats.iterator();
		while (iter.hasNext()) {
			cat = (ModuleCategory) iter.next();
			controller.setStatusLabel("Module.."+cat.getName());
			if (cat.getParentCategory() == null) {
				rootCategories.add(cat);
			}
				
		}
		
		
	}
	
	/**
	 * 
	 * @return an iterator over the list of modules
	 */
	public Iterator iterator() {
		
		Collection c = byId.values();
		return c.iterator();
		
	}
	
	/**
	 * 
	 * @return an iterator specifically returning uncategorized modules
	 */
	public Iterator uncategorizedModuleIterator() {
		return uncategorizedModules.iterator();
	}
	
	/**
	 * 
	 * @return an iterator over all root categories
	 */
	public Iterator rootCategoryIterator() {
		return rootCategories.iterator();
	}
	
	/**
	 * A debug dump of a module
	 *
	 */
	public void dump() {
		Iterator iter = iterator();
		while (iter.hasNext()) {
			Module mod = (Module) iter.next();
			dumpModule(mod);
		}
	}
	
	/**
	 * Access individual fields of a module.  By performing 
	 * each of these calls and ignoring the results, we can lump all of the 
	 * database overhead together in one place, thus removing the possibility
	 * of repeated delays due to database latencies.<p>
	 * 
	 * @param mod The module to be populated.
	 */
	private void populateModule(Module mod) {
				
		mod.populate();
		List params = mod.getInputs();
		params = mod.getOutputs();
	}
	
	/**
	 * Get a module by ID
	 * @param i the ID of the desired module
	 * @return the module
	 */
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
