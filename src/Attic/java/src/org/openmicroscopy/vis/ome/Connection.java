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
import org.openmicroscopy.*;
import org.openmicroscopy.managers.ChainManager;
import org.openmicroscopy.vis.piccolo.PFormalParameter;
import org.openmicroscopy.vis.piccolo.PFormalInput;
import org.openmicroscopy.vis.piccolo.PFormalOutput;
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.SemanticType;
import java.util.Hashtable;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import javax.swing.JWindow;
import javax.swing.JLabel;



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
	
		//buildStatusWindow();	
		worker = 
			new ConnectionWorker(controller,this,URL,userName,passWord);
		
		worker.start();
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
	
	/**
	 * 
	 * @return a {@link ChainManager} for the given session
	 */
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
}
