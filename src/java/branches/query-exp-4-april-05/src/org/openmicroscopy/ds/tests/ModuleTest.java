/*
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
package org.openmicroscopy.ds.tests;

import java.net.MalformedURLException;
import java.util.List;
import java.util.Iterator;

import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.DataServer;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.ServerVersion;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.FormalInput;
import org.openmicroscopy.ds.dto.FormalOutput;
import org.openmicroscopy.ds.dto.SemanticType;
import org.openmicroscopy.ds.managers.ModuleRetrievalManager;


/**
 * 
 *  A test program for evaluating the performance of OME-JAVA performance on 
 * retrieving modules.
 * @author <br>Harry Hochheiser &nbsp;&nbsp;&nbsp;
 * 	<A HREF="mailto:hsh@nih.gov">hsh@nih.gov</A>
 *
 *  @version 2.2
 * <small>
 * </small>
 * @since OME2.2
 */
public class ModuleTest {

	/** 
	 * Update the following variables as appropriate for your local installation.
	 */
	private static final String SHOOLA_URL="http://127.0.0.1/shoola";
	private static final String USER ="hsh";
	private static final String PASS = "foobar";
	
	private DataServices services;
	private DataFactory factory;
	private ModuleRetrievalManager manager;
	
	public ModuleTest() {
		super();
		
		try {
			// construct connection to omeds
			services = DataServer.getDefaultServices(SHOOLA_URL);
			// doe the basic login
			initializeFactory(services);
			if (factory == null) {
				System.err.println("Cannot contact Shoola server: "+SHOOLA_URL);
				System.exit(0);
			}
			getModules();
			if (manager != null)
				getManagerModules();
			System.err.println("Done!");
		}
		catch (MalformedURLException e) {
			System.err.println("Improperly specified Shoola URL: "+SHOOLA_URL);
			System.exit(0);
		}	
	}
	
	
	private void initializeFactory(DataServices services) {
		System.err.println("trying to get data...");
		//  login 
		RemoteCaller remote = services.getRemoteCaller();
		remote.login(USER,PASS);
		// test with server version
		ServerVersion ver = remote.getServerVersion();
		System.err.println("Server Version "+ ver);
		
		// retrieve the DataFactory which is used for data requests
		factory =  (DataFactory) services.getService(DataFactory.class);
		manager = (ModuleRetrievalManager) services.getService(
				ModuleRetrievalManager.class);
			
	}
	
	
	private void getModules() {
		System.err.println("\n\nOME-JAVA Timing Test: Module Retrieval");
		System.err.println("========================================");
		
		Criteria c = getModulesCriteria();
		long start = System.currentTimeMillis();
		List mods = factory.retrieveList(Module.class,c);
		double elapsed = getElapsed(start);
		
		System.err.println("# of modules : "+mods.size());
		System.err.println("Retrieval time: "+elapsed);
		
	}
	
	
	private Criteria getModulesCriteria() {
		Criteria c = new Criteria();
		//	Specify which fields we want for the chain.
//		Specify which fields we want for the project.
		c.addWantedField("id");
		c.addWantedField("name");
		c.addWantedField("description");
		c.addWantedField("category");
		c.addWantedField("inputs");
		c.addWantedField("outputs");
	
		//Specify which fields we want for the datasets.
		c.addWantedField("category", "id");
	//	c.addWantedField("category", "name");
		// what do we want about inputs and outputs 
		c.addWantedField("inputs","id");
		c.addWantedField("inputs","name");
		c.addWantedField("inputs","semantic_type");
		c.addWantedField("inputs.semantic_type","id");
		c.addWantedField("inputs.semantic_type","name");
		c.addWantedField("outputs","id");
		c.addWantedField("outputs","name");
		c.addWantedField("outputs","semantic_type");
		c.addWantedField("outputs.semantic_type","id");
		c.addWantedField("outputs.semantic_type","name");
		
		c.addOrderBy("name");
		return c;
	}
	
	private void getManagerModules() {
		System.err.println("=============================");
		System.err.println("starting module retrieval via manager..");
		long start = System.currentTimeMillis();
		List modules = manager.retrieveModules();
		long elapsed = System.currentTimeMillis()-start;
		double time = ((double) elapsed)/1000.0;
		System.err.println(modules.size()+ " modules retrieved in "+time+" seconds.");
		//dumpModuleList(modules);
		
	}
	
	private void dumpModuleList(List modules) {
		Iterator iter = modules.iterator();
		while (iter.hasNext()) {
			Module mod = (Module) iter.next();
			System.err.println("=============");
			System.err.println(mod.getID()+"," +mod.getName());
			System.err.println(mod.getDescription());
			/*if (mod.getCategory() != null)
				System.err.println("Category: "+mod.getCategory().getID());
			List inputs = mod.getFormalInputs();
			if (inputs != null && inputs.size() > 0) {
				System.err.println("Inputs: ");
				dumpInputs(inputs);
			}
			List outputs = mod.getFormalOutputs();
			if (outputs != null && outputs.size() > 0) {
				System.err.println("Outputs: ");
				dumpOutputs(outputs);
			}*/			
		}
	}

    private double getElapsed(long start) {
	return ((double) (System.currentTimeMillis()-start))/1000.0;
    }
    
    private void dumpInputs(List inputs) {
    	 	Iterator iter = inputs.iterator();
    	 	while (iter.hasNext()) {
    	 		FormalInput fin = (FormalInput) iter.next();
    	 		System.err.println(fin.getID()+", "+fin.getName());
    	 		SemanticType st = fin.getSemanticType();
    	 		if (st != null) {
    	 			System.err.println("Semantic Type: "+st.getID()+", "+st.getName());
    	 		}
    	 	}
    }
    
    private void dumpOutputs(List outputs) {
    		Iterator iter = outputs.iterator();
	 	while (iter.hasNext()) {
	 		FormalOutput fout = (FormalOutput) iter.next();
	 		System.err.println(fout.getID()+", "+fout.getName());
	 		SemanticType st = fout.getSemanticType();
	 		if (st != null) {
	 			System.err.println("Semantic Type: "+st.getID()+", "+st.getName());
	 		}
	 	}
    }
    
   public static void main(String[] args) {
		new ModuleTest();
	}
}
