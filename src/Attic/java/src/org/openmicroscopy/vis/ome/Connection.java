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
import org.openmicroscopy.vis.util.SwingWorker;
import org.openmicroscopy.vis.piccolo.PFormalParameter;
import org.openmicroscopy.vis.piccolo.PFormalInput;
import org.openmicroscopy.vis.piccolo.PFormalOutput;
import org.openmicroscopy.SemanticType;
import java.util.Hashtable;
import java.util.ArrayList;



/** 
 * <p>A wrapper class to handle discussion with the OME Database.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Connection {
	
	RemoteBindings remote=null;
	Session session;
	Factory factory;
	
	Modules modules;

	//inputs and outputs are hashes that match semantic types 
 	// to PModuleInputs and PModuleOutputs of the same type. 
	 // Given a semantic type as input(output), looking at the output(input)
	 // map entry for the given type will give a list of labels of 
	 // outputs(inputs) it can link to.
	 //
	 // This is a bit clunky. If OME java types were more easily subclassed, 
	 // it might make more sense to have these lists in subclasses of 
	 // RemoteSemanticType. Oh well.
    
 	private Hashtable inputs = new Hashtable();
 	private Hashtable outputs = new Hashtable();
 	
	/***
	 * Creates a new connection to the database via XMLRPC. If successful, gets 
	 * session and factory objects that are used to access data in the database.
	 * This class should be a wrapper around all interactions with OME, insulating
	 * all visualization code from OME code.
	 * 
	 * @param controller The chains controller, which will be notified (via procedure call)
	 * 		when login is complete.
	 * @param URL		 
	 * @param userName
	 * @param passWord
	 */
	public Connection(final ApplicationController controller,
		final String URL,final String userName,final String passWord) {
		
		
		// wrap it up in a Swing thread to allow UI to proceed 
		// uninterrupted.
		final SwingWorker worker = new SwingWorker() {
			public Object construct() {
				try {
				//	XmlRpcCaller.TRACE_CALLS=true;
					remote = new RemoteBindings();
					remote.loginXMLRPC(URL,userName,passWord);
				} catch (Exception e) {
					System.err.println(e);
					controller.cancelLogin();
				}
				return remote;
			}
			public void finished() {
				if (remote != null) {
					session = remote.getSession();
					factory = remote.getFactory();
					// this reads in all of the modules in the database
					// similar additional calls might end up here.
					System.err.println("factory is "+factory);
					modules  = new Modules(factory);
					controller.completeLogin();
					// for debugging only
					//modules.dump();
				}
			}
		};
		worker.start();
	}
	
	public String getUserName() {		
		Attribute user = session.getUser();
		return new String(user.getStringElement("FirstName")+" " +
			user.getStringElement("LastName"));
	}
	
	public Modules getModules() {
		return modules;
	}
	
	/**
	 * Shortcut interface to allow users to get access to modules
	 * without going through the Modules object. <p>
	 * 
	 * @param i
	 * @return
	 */
	
	public ModuleInfo getModuleInfo(int i) {
		return modules.getModuleInfo(i);	
	}
	
	public void setModuleInfo(int i,ModuleInfo info) {
		modules.setModuleInfo(i,info);
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
	
	
}
