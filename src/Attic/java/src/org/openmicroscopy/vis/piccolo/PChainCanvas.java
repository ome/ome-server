/*
 * org.openmicroscopy.vis.piccolo.PChainCanvas
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




package org.openmicroscopy.vis.piccolo;

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.SemanticType;
import java.util.Hashtable;
import java.util.ArrayList;

/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainCanvas extends PCanvas{
	
	private Connection connection;
	private int modCount;
	private PLayer layer;
	
	private static final float GAP=30f;
	private static final float TOP=20f;
	private float maxWidth = 0f;
	
	// inputs and outputs are hashes that match semantic types 
	// to modules inputs and outputs of the same type.
    // Given a semantic type as input(output), looking at the output(input)
    // map entry for the given type will give a list of labels of 
    // outputs(inputs) it can link to.
    //
    // This is a bit clunky. If OME java types were more easily subclassed, 
    // it might make more sense to have these lists in subclasses of 
    // RemoteSemanticType. Oh well.
    
	private Hashtable inputs;
	private Hashtable outputs;
	
	private float x,y;
	
	private PLayer linkLayer;
	
	public PChainCanvas() {
		super();
		layer = getLayer();
		inputs = new Hashtable();
		outputs = new Hashtable();
		removeInputEventListener(getPanEventHandler());
		linkLayer = new PLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		addInputEventListener(new PChainEventHandler(this,linkLayer));
	}
	
	/** 
	 * Populate the Canvas with nodes for each of the modules. 
	 * This procedure is called when the Connection object has completed
	 * loading the module information from the database.<p>
	 * 
	 * The canvas is populated in columns of 5 modules each.
	 * 
	 * @param connection The connection to the database.
	 * 
	 */
	public void setConnection(Connection connection) {
		this.connection = connection;
		
		modCount = connection.moduleCount();
		RemoteModule module = connection.getModule(0);
		
		x = 0;
		y = TOP;
		for (int i = 0; i < modCount; i++ ) {
			
			if ((i % 5) == 0) { // at the start of a new column 
				x += 100+maxWidth;
				y = TOP;
				maxWidth =0;
			}
			displayModule(connection.getModule(i));
		}
	}

	/** 
	 * Create a node for each module, add it to the canvas,
	 * update position of each one, and track maximum width - for
	 * layout of subsequent columns.<p>
	 * 
	 * @param module The module to be displayed.
	 */	
	private void displayModule(RemoteModule module) {

		PModule mNode = new PModule(this,module,x,y);
		float h = (float) mNode.getBounds().getHeight();
		y += h+GAP;
		layer.addChild(mNode);
		float nodeWidth = (float) mNode.getBounds().getWidth();
		if (nodeWidth > maxWidth)
			maxWidth=nodeWidth;
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
		addToHash(type,in,inputs);	
	}
	
	public void addOutput(SemanticType type,PFormalOutput out) {
		addToHash(type,out,outputs);
	}
	
	private void addToHash(SemanticType type,PFormalParameter param,
					Hashtable hash) {
		ArrayList list;
		// hash things based on the string rep. of the type id.
		// can't do 
		//Integer id = new Integer(type.getID());
		// as the key, as each call for a given integer value 
		// will give a different object.
		String idstring = Integer.toString(type.getID());
		
		// get the list, create a new list if there's no entry
		// for the key.
		Object map = hash.get(idstring);
		if (map == null) 
			list = new ArrayList();
		else 
			list = (ArrayList) map;
			
		// add the parameter to the list and put it back in the hash.
		list.add(param);
		hash.put(idstring,list);	
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
		//Integer id = new Integer(type.getID());
		String idstring = Integer.toString(type.getID());
		Object obj = hash.get(idstring);
		return (ArrayList) obj;
	}
		
}