/*
 * org.openmicroscopy.vis.piccolo.PModule
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

import org.openmicroscopy.vis.ome.Connection;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import java.awt.geom.RoundRectangle2D;
import javax.swing.event.EventListenerList;
import java.awt.BasicStroke;
import java.awt.Font;
import java.awt.Paint;
import java.awt.Color;
import java.util.List;
import java.lang.Object;


/** 
 * A Piccolo widget for a module. This widget will consist of a 
 * rounded rectangle, which is a border. This node will have two children:
 * a node with the name of the Module, and a second child which will itself
 * have multiple children - one for each input and output of the module. These 
 * children will be instances of PFormalInput and PFormalOutput (or appropriate
 * subclasses thereof).  
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PModule extends PPath {
	
	// Some static constants for convenience.
	
	private static final float DEFAULT_WIDTH=80;
	private static final float DEFAULT_HEIGHT=50;
	private static final float DEFAULT_ARC_WIDTH=10.0f;
	private static final float DEFAULT_ARC_HEIGHT=10.0f;
	private static final float NAME_LABEL_OFFSET=5.0f;
	private static final float NAME_SPACING=15.0f;
	private static final float PARAMETER_SPACING=3.0f;
	private static final float HORIZONTAL_GAP =50.0f;
	private static final float SCALE_THRESHOLD=0.5f;
	
	private static final Paint DEFAULT_PAINT=Color.black;
	private static final Paint DEFAULT_FILL = Color.lightGray;
	
	private static final BasicStroke DEFAULT_STROKE= new BasicStroke(1.0f); 
	private static final Font NAME_FONT = new Font("Helvetica",Font.PLAIN,14);

	private RemoteModule module;
	
	// the Rectangle with the bounds of the enclosing border
	private RoundRectangle2D rect;
	
	// The node contiaining the module name
	private PText name;
	 
	private float height;
	private float width;
	
	// The node that will contain nodes for each of the formal parameters
	private PNode labelNodes;
	
	/**
	 * The main constructor 
	 * @param canvas The canvas that this module will be displayed on. 
	 * 		Eventually, this might be expanded to account for multiple canvases.
	 * @param module The OME Module being represented
	 * @param x Initial x coordinate (global)
	 * @param y Initial y coordinate
	 */
	public PModule(Connection connection,RemoteModule module,float x,float y) {
		super();
		this.module=module;
		
		// create the container node for the formal parameters
		labelNodes = new PNode();
		addChild(labelNodes);
		
		// create the name and position it.
		name = new PText(module.getName());
		name.setFont(NAME_FONT);
		addChild(name);
		name.setOffset(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET);
		
		// calculate starting height for parameters.
		height = NAME_LABEL_OFFSET+((float) name.getBounds().getHeight());
		
		width = (float) name.getBounds().getWidth();
		
		// do the individual parameter labels.
		addParameterLabels(connection);  
		
		// set width of the whole bounding rectangle
		width = NAME_LABEL_OFFSET*2+width;
		
		// create bounding rectangle, set it to be this node's path,
		// and finish other parameters.
		rect = 
			new RoundRectangle2D.Float(0f,0f,width,height,
					DEFAULT_ARC_WIDTH,DEFAULT_ARC_HEIGHT);
		setPathTo(rect);
		setPaint(DEFAULT_FILL);
		setStroke(DEFAULT_STROKE);
		setOffset(x,y);
	}
	
	/** 
	 * Input and output parameters will be displayed in rows - 
	 * with the inputs on the left and the outputs on the right. Each 
	 * row will contain at most one input and one output. Whichever set
	 * (input or output) is larger will have some entries without matching 
	 * counterparts.<p>
	 * 
	 * This procedure positions the parameter nodes and calculates the size
	 * of the bounding rectangle that will be needed to hold all of the 
	 * parameters<p>
	 *
	 * @param connection  the database connection object
	 */
	private void addParameterLabels(Connection connection) {
		
		List inputs = module.getInputs();
		List outputs = module.getOutputs();
		int inSize = inputs.size();
		int outSize = outputs.size();
		// each row will contain one input and one output.
		// if # of each is not equal, we'll have one or more rows of input
		// only or output only.
		// # of rows is max of input and output
		int 	rows = inSize > outSize? inSize: outSize;
		
		FormalParameter param;
		PFormalInput  inTexts[] = new PFormalInput [inSize];
		PFormalOutput  outTexts[] = new PFormalOutput [outSize];
		
		// get input nodes and find max input width
		float maxInputWidth =0;
		float maxOutputWidth =0;
		
		// for each row.
		for (int i = 0; i < rows; i++) {
			if (i < inSize) {
				// as long as I have more inputs, create them, 
				// add them to label nodes, 
				// and store max width
				param = (FormalParameter) inputs.get(i);
				inTexts[i]= new PFormalInput(this,param,connection);
				labelNodes.addChild(inTexts[i]);
				if (inTexts[i].getFullBoundsReference().getWidth() > maxInputWidth)
					maxInputWidth = (float) inTexts[i].getFullBoundsReference().getWidth();
			}
			if (i < outSize) {
				// do the same for outputs.
				param = (FormalParameter) outputs.get(i);
				outTexts[i]= new PFormalOutput(this,param,connection);
				labelNodes.addChild(outTexts[i]);
				if (outTexts[i].getFullBoundsReference().getWidth() > maxOutputWidth)
					maxOutputWidth = (float) outTexts[i].getFullBoundsReference().getWidth();
			}
			
		}
		
		// find maximum width of the whole thing.
		width = maxInputWidth+maxOutputWidth+HORIZONTAL_GAP;
		
		// find horizontal starting point of the output parameters.
		float outputColumnX=NAME_LABEL_OFFSET+maxInputWidth+HORIZONTAL_GAP;
		
		
		//height of first one
		height+=NAME_SPACING;
		float rowHeight=0;
		
		// place things at appropriate x,y.
		for (int i =0; i < rows; i++) {
			// get ith input 
			if (i <inSize) {
				inTexts[i].setOffset(NAME_LABEL_OFFSET,height);
				rowHeight = (float) inTexts[i].getFullBoundsReference().getHeight();	
			}
			// get ith output
			if (i < outSize) {
				// we want to right-justify these. So, 
				// find difference bwtween the maximum output width
				// and the width of this one.
				float rightJustifyGap = maxOutputWidth-
					((float) outTexts[i].getFullBoundsReference().getWidth());
				// and then move right by that amount.
				outTexts[i].setOffset(outputColumnX+rightJustifyGap,height);
				rowHeight = (float) outTexts[i].getFullBoundsReference().getHeight();
			}
			// advance to next row in height.
			height += rowHeight+PARAMETER_SPACING;
		}
	}
	
	/**
	 * Paint the node in the given context. This method does some 
	 * simple semantic zooming.
	 * 
	 */
	public void paint(PPaintContext aPaintContext) {
		double s = aPaintContext.getScale();
	
		if (s < SCALE_THRESHOLD)
			labelNodes.setVisible(false);
		else
			labelNodes.setVisible(true);
		super.paint(aPaintContext);
	} 
	
	
	public RemoteModule getModule() {
		return module;
	}
	
	/***
	 * Some code for managing listeners and events
	 */
	
	private EventListenerList listenerList =
		new EventListenerList();
	
	public void addNodeEventListener(PNodeEventListener nel) {
		listenerList.add(PNodeEventListener.class,nel);
	}

	public void removeNodeEventListener(PNodeEventListener nel) {
		listenerList.remove(PNodeEventListener.class,nel);
	}
		
	public void fireStateChanged() {
		Object[] listeners  = listenerList.getListenerList();
		for (int i = listeners.length-2; i >=0; i -=2) {
			if (listeners[i]==PNodeEventListener.class) {
				((PNodeEventListener)listeners[i+1]).nodeChanged(
					new PNodeEvent(this));
			}
		}
	}
	
	/**
	 * translate - call super class and then update state changes.
	 * 
	 **/
	
	public void translate(double dx,double dy) {
		super.translate(dx,dy);
		fireStateChanged();
	}
}