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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Iterator;
import java.util.Map;

import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.DataServer;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.ServerVersion;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Project;


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
public class DatasetAnnotationTest {

	/** 
	 * Update the following variables as appropriate for your local installation.
	 */
	private static final String SHOOLA_URL="http://127.0.0.1/shoola";
	private static final String USER ="hsh";
	private static final String PASS = "foobar";
	private static final int UID=1;
	
	private DataServices services;
	private DataFactory factory;
	
	
	public DatasetAnnotationTest() {
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
			getAnnotations();
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
					
	}
	
	
	private void getAnnotations() {
		System.err.println("\n\nOME-JAVA Test: Dataset Annotation Retrieval");
		System.err.println("========================================");
		
		Criteria c = buildUserProjectsCriteria();
		//List projects = get projects./
		List projs = (List) factory.retrieveList(Project.class,c);
		
		List datasetIDs = prepareListDatasetsID(projs);
		// get dataset ids 
		c = getAnnotationsCriteria(UID,datasetIDs);
		List annotations = factory.retrieveList("DatasetAnnotation",c);
		
		
	}
	
	private Criteria buildUserProjectsCriteria() {
		Criteria c = new Criteria();
		 c.addWantedField("name"); 
	     c.addWantedField("datasets"); 
	        //Specify which fields we want for the datasets.
	     c.addWantedField("datasets", "name");
		c.addFilter("owner_id", new Integer(UID));
		return c;
	}
	
	
	private Criteria getAnnotationsCriteria(int uid,List datasetIDs) {
		Criteria c = new Criteria();
		//	Specify which fields we want for the chain.
//		Specify which fields we want for the project.
		c.addWantedField("content");
        c.addWantedField("module_execution");
        c.addWantedField("module_execution", "timestamp");
        c.addWantedField("module_execution", "experimenter");
        //Specify which fields we want for the owner.
        c.addWantedField("module_execution.experimenter", "FirstName");
        c.addWantedField("module_execution.experimenter", "LastName");
	c.addFilter("Valid", Boolean.TRUE);
        c.addWantedField("dataset");
        if (datasetIDs != null) c.addFilter("dataset_id", "IN", datasetIDs);
	    return c;
	}
	
	 /** Return of Object ID corresponding to the dataset ID.  - from project mapper */
    public static List prepareListDatasetsID(List projects)
    {
        Map map = new HashMap();
        Iterator i = projects.iterator(), k;
        List datasets;
        Integer id;
        while (i.hasNext()) {
            datasets = ((Project) i.next()).getDatasets();
            k = datasets.iterator();
            while (k.hasNext()) {
                id = new Integer(((Dataset) k.next()).getID());
                map.put(id, id);
            }
        }
        i = map.keySet().iterator();
        List ids = new ArrayList();
        while (i.hasNext()) 
            ids.add(i.next());

        return ids;
    }
	    
   public static void main(String[] args) {
		new DatasetAnnotationTest();
	}
}
