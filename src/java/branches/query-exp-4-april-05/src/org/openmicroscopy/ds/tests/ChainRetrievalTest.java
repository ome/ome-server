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
import java.util.Iterator;
import java.util.List;

import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.DataServer;
import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.ServerVersion;
import org.openmicroscopy.ds.dto.AnalysisChain;
import org.openmicroscopy.ds.dto.AnalysisLink;
import org.openmicroscopy.ds.dto.AnalysisNode;
import org.openmicroscopy.ds.dto.FormalOutput;
import org.openmicroscopy.ds.dto.FormalInput;
import org.openmicroscopy.ds.dto.SemanticType;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.managers.ChainRetrievalManager;
import org.openmicroscopy.ds.st.Experimenter;
/**
 * 
 *
 * @author <br>Harry Hochheiser &nbsp;&nbsp;&nbsp;
 * 	<A HREF="mailto:hsh@nih.gov">hsh@nih.gov</A>
 *
 *  @version 2.2
 * <small>
 * </small>
 * @since OME2.2
 */
public class ChainRetrievalTest {

	/** 
	 * Update the following variables as appropriate for your local installation.
	 */
	private static final String SHOOLA_URL="http://hsh-tibook.local/shoola";
	private static final String USER ="hsh";
	private static final String PASS = "foobar";
	
	private static final int MEX_ID=4211;
	private static final int CHEX_ID=36;
	
	private DataServices services;
	private ChainRetrievalManager chainRetrievalManager;
	private DataFactory factory;
	
	public ChainRetrievalTest() {
		super();
		
		try {
			// construct connection to omeds
			services = DataServer.getDefaultServices(SHOOLA_URL);
			// doe the basic login
			initializeChainRetrievalManager(services);
			criteriaGetChains();
			if (chainRetrievalManager != null) {
			    getChains();
			}
		}
		catch (MalformedURLException e) {
			System.err.println("Improperly specified Shoola URL: "+SHOOLA_URL);
			System.exit(0);
		}	
	}
	
	private void initializeChainRetrievalManager(DataServices services) {
		System.err.println("trying to get data...");
		//  login 
		RemoteCaller remote = services.getRemoteCaller();
		remote.login(USER,PASS);
		// test with server version
		ServerVersion ver = remote.getServerVersion();
		System.err.println("Server Version "+ ver);
		
		// retrieve the HistoryManager which is used for data requests
		chainRetrievalManager =  
			(ChainRetrievalManager) services.getService(ChainRetrievalManager.class);
		factory =  (DataFactory) services.getService(DataFactory.class);
	}
	
	
	private void getChains() {
		System.err.println("=============================");
		System.err.println("starting chain retrieval via manager..");
		long start = System.currentTimeMillis();
		List chains = chainRetrievalManager.retrieveChains();
		long elapsed = System.currentTimeMillis()-start;
		double time = ((double) elapsed)/1000.0;
		System.err.println(chains.size()+ " chains retrieved in "+time+" seconds.");
		dumpChainList(chains);
	}
	
	private void criteriaGetChains() {
		Criteria criteria =new Criteria();
		criteria.addWantedField("id");
		criteria.addWantedField("name");
		criteria.addWantedField("description");
		criteria.addWantedField("nodes");
		criteria.addWantedField("links");
		criteria.addWantedField("locked");
		criteria.addWantedField("owner");
		criteria.addWantedField("owner","FirstName");
		criteria.addWantedField("owner","LastName");
		
		
		// stuff for nodes
		criteria.addWantedField("nodes","module");
		criteria.addWantedField("nodes","id");
		criteria.addWantedField("nodes.module","id");
		criteria.addWantedField("nodes.module","name");
		
		// links
		criteria.addWantedField("links","from_node");
		criteria.addWantedField("links.from_node","id");
		
		criteria.addWantedField("links","to_node");
		criteria.addWantedField("links.to_node","id");
		criteria.addWantedField("links","from_output");
		criteria.addWantedField("links","to_input");
		
		criteria.addWantedField("links.from_output","id");
		criteria.addWantedField("links.to_output","id");
		
		criteria.addWantedField("links.from_output","semantic_type");
		criteria.addWantedField("links.to_input","semantic_type");
		
		criteria.addWantedField("links.from_output","name");
		criteria.addWantedField("links.to_input","name");
			
		criteria.addWantedField("links.from_output.semantic_type","id");
		criteria.addWantedField("links.to_input.semantic_type","id");
		criteria.addWantedField("links.from_output.semantic_type","name");
		criteria.addWantedField("links.to_input.semantic_type","name");
		System.err.println("========");
		System.err.println("retrieving chains via data factory.");
		long start = System.currentTimeMillis();
		List chains = factory.retrieveList(AnalysisChain.class,criteria);
		long elapsed = System.currentTimeMillis()-start;
		double time = ((double) elapsed)/1000.0;
		System.err.println(chains.size()+ " chains retrieved in "+time+" seconds.");
		//		dumpChainList(chains);
	}
	
	private void dumpChainList(List chains) {
		Iterator iter = chains.iterator();
		AnalysisChain chain;
		while (iter.hasNext()) {
			chain = (AnalysisChain)iter.next();
			System.err.println("Chain: "+chain.getID()+", "+chain.getName());
			dumpChain(chain);
		}
	}
	
	private void dumpChain(AnalysisChain chain) {
	        if (chain == null ){
		   System.err.println("null chain? but how?");
	    	   return;
		}
		Experimenter exp = chain.getOwner();
		System.err.println("owner: "+exp.getFirstName()+" "+exp.getLastName());
		
   	        Iterator iter;
		List links = chain.getLinks();
		if (links == null || links.size() == 0) {
		    System.err.println("NO LINKS!");
		}
		else {
		    System.err.println(links.size()+" links");
		    iter = links.iterator();
		    AnalysisLink link;
		    while (iter.hasNext()) {
			link = (AnalysisLink) iter.next();
			dumpLink(link);
		    }
		}
		
		List nodes = chain.getNodes();
		System.err.println(nodes.size()+" nodes");
		iter = nodes.iterator();
		AnalysisNode node;
		while (iter.hasNext()) {
			node = (AnalysisNode) iter.next();
			dumpNode(node);
		}
	}

	private void dumpLink(AnalysisLink link) {
		System.err.println("link "+link.getID());
		FormalOutput fo = link.getFromOutput();
		if (fo != null) {
			System.err.println("from output "+fo.getID()+", "+fo.getName());
			SemanticType st = fo.getSemanticType();
			if (st != null)
				System.err.println("st ..."+st.getID()+", "+st.getName());
		}
		FormalInput fi = link.getToInput();
		if (fi != null) {
			System.err.println("to input "+fi.getID()+", "+fi.getName());
			SemanticType st = fi.getSemanticType();
			if (st != null)
				System.err.println("st ..."+st.getID()+", "+st.getName());
		}
	}
	
	private void dumpNode(AnalysisNode node) {
		System.err.println("node.."+node.getID());
		Module mod = node.getModule();
		System.err.println("module .."+mod.getID()+", "+mod.getName());
	}
	
	public static void main(String[] args) {
		new ChainRetrievalTest();
	}
}