/*
 * org.openmicroscopy.vis.chains.ome.Connection
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

import org.openmicroscopy.remote.*;
import org.openmicroscopy.Factory;
import org.openmicroscopy.Session;
import org.openmicroscopy.Attribute;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.managers.ChainManager;
import org.openmicroscopy.vis.piccolo.PFormalParameter;
import org.openmicroscopy.vis.piccolo.PFormalInput;
import org.openmicroscopy.vis.piccolo.PFormalOutput;
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.vis.util.SwingWorker;
import org.openmicroscopy.SemanticType;
import java.util.Hashtable;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import java.util.HashMap;
import javax.swing.JWindow;
import javax.swing.JLabel;
import java.net.URL;
import java.net.MalformedURLException;
import java.awt.image.BufferedImage;



/** 
 * <p>A wrapper class that handles discussion with the OME Database.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class Connection {
	
	private RemoteBindings remote=null;
	private Session session;
	private Factory factory;
	
	private Modules modules;
	private Chains chains;

	//inputs and outputs are hashes that match semantic types 
 	// to PModuleInputs and PModuleOutputs of the same type. 
	 // Given a semantic type as input(output), looking at the output(input)
	 // map entry for the given type will give a list of labels of 
	 // outputs(inputs) it can link to.
	 //
	 // This is a bit clunky. It might make more sense to subclass 
	 // RemoteSemanticTypes 
	 // it might make more sense to have these lists in subclasses of 
	 // RemoteSemanticType. Oh well.
    
 	private Hashtable inputs = new Hashtable();
 	private Hashtable outputs = new Hashtable();
 	
	private JWindow status;
	private JLabel statusLabel;
		
 	private final ConnectionWorker worker;
 	
 	private final String userName;
 	private final String passWord;
 	
 	
 	private String host;
 	// the list of chain executions for the currently selected dataset
 	private List chainExecutions;
 	
 	private ThumbnailAgent thumbnails;
 	
 	//private CDataset curDataset;
	/***
	 * Creates a {@link ConnectionWorker} that will build a new connection to 
	 * the database via XMLRPC. If successful, the ConnectionWorker will return 
	 * session and factory objects that are used to access data in the database.
	 * This class should be a wrapper around all direct interactions with OME, 
	 * insulating visualization code from OME code. Specifically, no objects 
	 * outside of this class should need to know about {@link Factory} and 
	 * {@link Session} objects
	 * 
	 * @param controller The chains controller, which will be notified 
	 * 		(via procedure call) when login is complete.
	 * @param URL		 
	 * @param userName
	 * @param passWord
	 */
	public Connection(final Controller controller,
		final String URL,final String userName,final String passWord) {
	
		this.userName = userName;
		this.passWord = passWord;
		this.host = getHost(URL);
		//buildStatusWindow();	
		worker = 
			new ConnectionWorker(controller,this,URL,userName,passWord);
		
		worker.start();
	}
	
	
	public void createThumbnailAgent() {
		
		thumbnails = new ThumbnailAgent(host,userName,passWord);
		try {
			thumbnails.initialize();
		} catch( Exception e) {
			e.printStackTrace();
			thumbnails = null;
		}

	}
		
	/**
	 * The assumption is that if we are connecting to the XMLRPC server
	 * at http://foo:port, we can get to the web server via host name foo. 
	 * This is a bit of a hack, but it will have to do until the image 
	 * server is reallly going...
	 * 
	 * @param url
	 * @return the hostname of the corresponding url.
	 */
	private String getHost(String url) {
		URL fullURL=null;
		try {
			 fullURL = new URL(url);}
		catch (MalformedURLException e) {
			System.err.println("Should never get here...");
			return null;
		}
		return fullURL.getHost();
	}
	public void setSession(Session session) {
		this.session = session;
	}
	
	public Session getSession() {
		return session;
	}
	
	public void setFactory(Factory factory) {
		this.factory = factory;
	}
	
	public void setModules(Modules modules) {
		this.modules = modules;
	}
	
	public void setChains(Chains chains) {
		this.chains = chains;
	}
	
	public String getUserName() {		
		Attribute user = session.getUser();
		return new String(user.getStringElement("FirstName")+" " +
			user.getStringElement("LastName"));
	}
	
	public String getOwnerName(CChain chain) {
		Attribute owner = chain.getOwner();
		return new String(owner.getStringElement("FirstName")+" " +
			owner.getStringElement("LastName"));
	}
	
	/**
	 * 
	 * @return The {@link Modules} object containing the modules for this session
	 */
	public Modules getModules() {
		return modules;
	}
	
	/**
	 * 
	 * @return the {@link Chains} object containing the cains for this session
	 */
	public Chains getChains() {
		return chains;
	}
	
	
	/**
	 * Layout the chains in the current session
	 *
	 */
	public void layoutChains() {
		if (chains != null)
		 	chains.layout();
	}
	
	/**
	 * Retrieve a module
	 * @param id a module id
	 * @return the {@link CModule} with the given ID
	 */
	public CModule getModule(int id) {
		return modules.getModule(id);
	}
	
	/**
	 * Retrieve a chain
	 * @param i the chain id
	 * @return The {@link CChain} with the given id
	 */
	public CChain getChain(int i) {
		return chains.getChain(i);
	}
	
	/**
	 * Add a chain
	 * @param c The chain to be added
	 */
	public void addChain(CChain c) {
		chains.addChain(c);
	}
	
	/**
	 * The inputs and outputs lists are hashes of lists, keyed by
	 * SemanticType. The entries in those lists are PFormalParameter 
	 * instances - either ModuleInputs or ModuleOutputs.
	 *  
	 * @param type
	 * @param in
	 */
	public void addInput(SemanticType type,PFormalInput in) {
	//	System.err.println("adding inputs");
		addToHash(type,in,inputs);	
	}
	
	public void addOutput(SemanticType type,PFormalOutput out) {
		//System.err.println("adding outputs");
		addToHash(type,out,outputs);
	}
	
	private void addToHash(SemanticType type,PFormalParameter param,
					Hashtable hash) {
		ArrayList list;
		
		if (type == null || type.toString().compareTo(">>OBJ:NULL") == 0) {
	//		System.err.println("semantic type is null"); 
			return;
		} 
		Integer id = new Integer(type.getID());
		
		Object map  = hash.get(id);
		if (map == null) 
			list = new ArrayList();
		else 
			list = (ArrayList) map;
			
		// add the parameter to the list and put it back in the hash.
		list.add(param);
		hash.put(id,list);
			
	}
	
	/** 
	 * Returns the lists of inputs for the given semantic type
	 * @param type
	 * @return list of inputs with this type
	 */
	public ArrayList getInputs(SemanticType type) {
		return getHashedList(type,inputs);
	}
	
	/** 
	 * Returns the lists of outputs for the given semantic type
	 * @param type
	 * @return list of outputs with this type
	 */
	public ArrayList getOutputs(SemanticType type) {
		return getHashedList(type,outputs);
	}
	
	private ArrayList getHashedList(SemanticType type,Hashtable hash) {
		Integer id = new Integer(type.getID());
		Object obj = hash.get(id);
		return (ArrayList) obj;
	}
	
	/**
	 * Tell the server to finalize the active database transaction
	 *
	 */
	public void commitTransaction() {
		session.commitTransaction();
	}
	
    public ChainManager getChainManager() {
		return session.getChainManager();
	}
	
	/**
	 * 
	 * @return a list of modules from the database
	 */
	public List loadModules() {
		return factory.findObjects("OME::Module",null);
	}
	
	/**
	 * 
	 * @return a list of the module categories in the database
	 */
	public List loadCategories() {
		return factory.findObjects("OME::Module::Category",null);
	}
	
	/**
	 * 
	 * @return a list of the Chains in the database
	 */
	public List loadChains() {
		return factory.findObjects("OME::AnalysisChain",null);
	}
	
	public List getProjectsForUser() {
		Attribute user = session.getUser();
		HashMap crit = new HashMap();
		crit.put("owner_id",user);
		List projects = factory.findObjects("OME::Project",crit);
		return projects;
	}
	
	public List getDatasetsForUser() {
		Attribute user = session.getUser();
		HashMap crit = new HashMap();
		crit.put("owner_id",user);
		List datasets = factory.findObjects("OME::Dataset",crit);
		return datasets;
	}
	
	public void initDatasets(final Controller controller) {
		
		final SwingWorker worker = new SwingWorker() {
			public Object construct() {
				List ds = getDatasetsForUser();
				Iterator iter = ds.iterator();
				while (iter.hasNext()) {
					CDataset d = (CDataset) iter.next();
					controller.setStatusLabel("Dataset "+d.getName());
					d.getImageCount();
				}
				return null;
			}
			public void finished() {
				System.err.println("finishing with the datasets");
				controller.finishInitThread();
			}
		};
		worker.start();
	}
	
	public List getChainExecutions(CChain c) {
		if (c == null)
			return null;
			
		HashMap crit = new HashMap();
		crit.put("analysis_chain",c);
		List execs  = factory.findObjects("OME::AnalysisChainExecution",crit);
		return execs;
	}
	

	
	public void getThumbnail(CImage i) {
		
		int id = i.getID();
		try {
			if (thumbnails != null) {
			//	System.err.println("calling thumbnails.getThumbnail(id)");
				getThumbnail(i,id);
			}
		} catch(Exception e) {
			System.err.println("exception in grabbing thumbnail "+id);
			e.printStackTrace();
		}
	//	System.err.println(" returning from connection.getThumbnail..");
		/*if (image == null) 
			System.err.println("image is nulll..."); */
	}
	
	public void getThumbnail(final CImage i,final int id) {
		final SwingWorker worker = new SwingWorker() {
			BufferedImage image = null;
			public Object construct() {
				try {
					image = thumbnails.getThumbnail(id);
				}
				catch (Exception e) {
					e.printStackTrace();
				}
				return image;
			}
			
			public void finished() {
				i.setImageData(image);
			}
		};
		worker.start();
	}
}
