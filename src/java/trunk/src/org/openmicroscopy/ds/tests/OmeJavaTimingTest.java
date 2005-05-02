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

import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.DataServer;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.ServerVersion;

import org.openmicroscopy.ds.dto.AnalysisChain;
import org.openmicroscopy.ds.dto.ChainExecution;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Project;
import org.openmicroscopy.ds.dto.Image;
import org.openmicroscopy.ds.dto.Module;


/**
 * 
 *  A test program for evaluating the performance of OME-JAVA. Connect to a 
 *  remote server, retrieve some data, and track how long the requests take.
 * Ideally would be used in conjunction with an instrumented OME server, in order 
 * to split out client time from server time. Of course, finer-grain measurement of 
 * performance of HTTP and XMLRPC libraries might be useful as well..
 * 
 * @author <br>Harry Hochheiser &nbsp;&nbsp;&nbsp;
 * 	<A HREF="mailto:hsh@nih.gov">hsh@nih.gov</A>
 *
 *  @version 2.2
 * <small>
 * </small>
 * @since OME2.2
 */
public class OmeJavaTimingTest {

	/** 
	 * Update the following variables as appropriate for your local installation.
	 */
	private static final String SHOOLA_URL="http://hsh-tibook.local/shoola";
	private static final String USER ="hsh";
	private static final String PASS = "foobar";
	
	private DataServices services;
	private DataFactory factory;
	
	public OmeJavaTimingTest() {
		super();
		
		try {
			// construct connection to omeds
			services = DataServer.getDefaultServices(SHOOLA_URL);
			// doe the basic login
			factory  = initializeFactory(services);
			if (factory == null) {
				System.err.println("Cannot contact Shoola server: "+SHOOLA_URL);
				System.exit(0);
			}
			getChains();
			getModules();
			getProjects();
			getDatasets();
			getImages(); 
			getChexes();
			System.err.println("Done!");
		}
		catch (MalformedURLException e) {
			System.err.println("Improperly specified Shoola URL: "+SHOOLA_URL);
			System.exit(0);
		}	
	}
	
	private DataFactory initializeFactory(DataServices services) {
		System.err.println("trying to get data...");
		//  login 
		RemoteCaller remote = services.getRemoteCaller();
		remote.login(USER,PASS);
		// test with server version
		ServerVersion ver = remote.getServerVersion();
		System.err.println("Server Version "+ ver);
		
		// retrieve the DataFactory which is used for data requests
		return (DataFactory) services.getService(DataFactory.class);
			
	}
	
	private void getChains() {
		System.err.println("\n\nOME-JAVA Timing Test: Chain Retrieval");
		System.err.println("=======================================");
		
		Criteria c = getChainCriteria();
		long start = System.currentTimeMillis();
		List chains = factory.retrieveList(AnalysisChain.class,c);
		double elapsed = getElapsed(start);
		
		System.err.println("# of Chains: "+chains.size());
		System.err.println("Retrieval time: "+elapsed);
		
	}
	
	
	private Criteria getChainCriteria() {
		Criteria c = new Criteria();
		//	Specify which fields we want for the chain.
		c.addWantedField("id");
		c.addWantedField("name");
		c.addWantedField("description");
		c.addWantedField("nodes");
		c.addWantedField("links");
		c.addWantedField("locked");
		c.addWantedField("owner");
		c.addWantedField("owner","FirstName");
		c.addWantedField("owner","LastName");
		
		
		// stuff for nodes
		c.addWantedField("nodes","module");
		c.addWantedField("nodes","id");
		c.addWantedField("nodes.module","id");
		c.addWantedField("nodes.module","name");
		
		// links
		c.addWantedField("links","from_node");
		c.addWantedField("links.from_node","id");
		
		c.addWantedField("links","to_node");
		c.addWantedField("links.to_node","id");
		c.addWantedField("links","from_output");
		c.addWantedField("links","to_input");
		
		c.addWantedField("links.from_output","id");
		c.addWantedField("links.to_output","id");
		
		c.addWantedField("links.from_output","semantic_type");
		c.addWantedField("links.to_input","semantic_type");
		
		c.addWantedField("links.from_output","name");
		c.addWantedField("links.to_input","name");
			
		c.addWantedField("links.from_output.semantic_type","id");
		c.addWantedField("links.to_input.semantic_type","id");
		c.addWantedField("links.from_output.semantic_type","name");
		c.addWantedField("links.to_input.semantic_type","name");
		return c;
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
		c.addWantedField("category", "name");
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
		return c;
	}
	private void getProjects() {
		System.err.println("\n\nOME-JAVA Timing Test: Project Retrieval");
		System.err.println("=========================================");
		Criteria c = getProjectCriteria();
		long start = System.currentTimeMillis();
		List projects = factory.retrieveList(Project.class,c);
		double elapsed = getElapsed(start);
		System.err.println("# of projects: "+projects.size());
		System.err.println("Retrieval time: "+elapsed);
	}
	
	private Criteria getProjectCriteria() {
		Criteria c = new Criteria();
		//Specify which fields we want for the project.
		c.addWantedField("id");
		c.addWantedField("name");
		c.addWantedField("description");
		c.addWantedField("owner");
		c.addWantedField("datasets"); 

		//Specify which fields we want for the owner.
		c.addWantedField("owner", "id");
		c.addWantedField("owner", "FirstName");
		c.addWantedField("owner", "LastName");
		c.addWantedField("owner", "Email");
		c.addWantedField("owner", "Institution");
		c.addWantedField("owner", "Group");

		//Specify which fields we want for the owner's group.
		c.addWantedField("owner.Group", "id");
		c.addWantedField("owner.Group", "Name");

		//Specify which fields we want for the datasets.
		c.addWantedField("datasets", "id");
		c.addWantedField("datasets", "name");
		return c;		
	}
	
	private void getDatasets() {
		System.err.println("\n\nOME-JAVA Timing Test: Dataset Retrieval");
		System.err.println("=========================================");
		Criteria c = getDatasetCriteria();
		long start = System.currentTimeMillis();
		List datasets = factory.retrieveList(Dataset.class,c);
		double elapsed = getElapsed(start);
		System.err.println("# of datasets (without images) : "+datasets.size());
		System.err.println("Retrieval time: "+elapsed);
		
		addImageCriteria(c);
		start = System.currentTimeMillis();
		datasets = factory.retrieveList(Dataset.class,c);
		elapsed = getElapsed(start);
		System.err.println("# of datasets (with images) : "+datasets.size());
		System.err.println("Retrieval time: "+elapsed);
		
	}

	private Criteria getDatasetCriteria() {
		Criteria c = new Criteria();
		
//		Specify which fields we want for the dataset.
		c.addWantedField("id");
		c.addWantedField("name");
		c.addWantedField("description");
		c.addWantedField("owner");

		//Specify which fields we want for the owner.
		c.addWantedField("owner", "id");
		c.addWantedField("owner", "FirstName");
		c.addWantedField("owner", "LastName");
		c.addWantedField("owner", "Email");
		c.addWantedField("owner", "Institution");
		c.addWantedField("owner", "Group");

		//Specify which fields we want for the owner's group.
		c.addWantedField("owner.Group", "id");
		c.addWantedField("owner.Group", "Name");

		return c;		
	}
	
	private void addImageCriteria(Criteria c) {
	    //		Specify which fields we want for the images.

	        c.addWantedField("images");
		c.addWantedField("images", "id");
		c.addWantedField("images", "name");
	}
	
	private void getImages() {
		System.err.println("\n\nOME-JAVA Timing Test: Image Retrieval");
		System.err.println("=======================================");
		Criteria c = getImageCriteria();
		long start = System.currentTimeMillis();
		List images = factory.retrieveList(Image.class,c);
		
		double elapsed = getElapsed(start);
		System.err.println("# of images: "+images.size());
		System.err.println("Retrieval time "+elapsed);

		addPixelsCriteria(c);
		start = System.currentTimeMillis();
		images = factory.retrieveList(Image.class,c);
		elapsed = getElapsed(start);
		System.err.println("# of  images (w/pixels): "+images.size());
		System.err.println("Retrieval time " +elapsed);


		addDatasetsCriteria(c);
		start = System.currentTimeMillis();
		images = factory.retrieveList(Image.class,c);
		elapsed = getElapsed(start);
		System.err.println("# of  images (w/pixels and dataset): "
				   +images.size());
		System.err.println("Retrieval time " +elapsed);

	}
	
        
	private Criteria getImageCriteria() {
		Criteria c = new Criteria();
		
		c.addWantedField("id");
  		c.addWantedField("name");
  		c.addWantedField("description"); 
		c.addWantedField("inserted"); 
		c.addWantedField("created"); 
  		return c;		
	}

        private void addPixelsCriteria(Criteria c) {
		c.addWantedField("default_pixels");
			
		//Specify which fields we want for the pixels.
		c.addWantedField("default_pixels", "id");
		c.addWantedField("default_pixels", "SizeX");
		c.addWantedField("default_pixels", "SizeY");
		c.addWantedField("default_pixels", "SizeZ");
		c.addWantedField("default_pixels", "SizeC");
		c.addWantedField("default_pixels", "SizeT");
		c.addWantedField("default_pixels", "PixelType");
		c.addWantedField("default_pixels", "Repository");
		c.addWantedField("default_pixels", "ImageServerID");
		c.addWantedField("default_pixels.Repository", "ImageServerURL");
	}

        private void addDatasetsCriteria(Criteria c) {

	    c.addWantedField("datasets");
	    c.addWantedField("datasets","id");
	    c.addWantedField("datasets","name");
        }


	private void getChexes() {
		System.err.println("\n\nOME-JAVA Timing Test: Chex Retrieval");
		System.err.println("=======================================");
		
		Criteria c = getChainExecutionCriteria();
		long start = System.currentTimeMillis();
		List execs = factory.retrieveList(ChainExecution.class,
						   c);
		double elapsed = getElapsed(start);
		
		System.err.println("# of Chain Executions: "+execs.size());
		System.err.println("Retrieval time: "+elapsed);
		
	}
	
	
	private Criteria getChainExecutionCriteria() {
		Criteria c = new Criteria();
//Specify which fields we want for the chain.
		c.addWantedField("id");
		c.addWantedField("analysis_chain");
		c.addWantedField("dataset");
		c.addWantedField("node_executions");
		c.addWantedField("timestamp");
		
		// stuff for dataset
		c.addWantedField("dataset","id");
		c.addWantedField("dataset","name");
		c.addWantedField("dataset","owner_id");
		
		// stuff for chains
		c.addWantedField("analysis_chain","id");
		c.addWantedField("analysis_chain","name");
		
		// stuff for node executions
		c.addWantedField("node_executions","id");
		
		c.addWantedField("node_executions","module_execution");
		c.addWantedField("node_executions.module_execution","id");
		c.addWantedField("node_executions.module_execution","timestamp");
		
		c.addWantedField("node_executions.module_execution","module");
		
		c.addWantedField("node_executions.module_execution.module","id");
		c.addWantedField("node_executions.module_execution.module","name");
	
		
		//	c.addFilter("dataset.name", "NOT LIKE", "ImportSet");
		return c;
	}
	

    private double getElapsed(long start) {
	return ((double) (System.currentTimeMillis()-start))/1000.0;
    }
    
   public static void main(String[] args) {
		new OmeJavaTimingTest();
	}
}
