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
import org.openmicroscopy.vis.ome.ModuleInfo;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PPaintContext;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PNodeFilter;
import edu.umd.cs.piccolox.util.PBoundsLocator;

import org.openmicroscopy.Module;
import org.openmicroscopy.Module.FormalParameter;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.awt.geom.RoundRectangle2D;
import java.awt.geom.Point2D;
import javax.swing.event.EventListenerList;
import java.awt.BasicStroke;
import java.awt.Font;
import java.awt.Color;
import java.util.List;
import java.lang.Object;
import java.util.Iterator;
import java.util.ArrayList;
import java.util.TreeSet;
import java.util.Collection;

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

public class PModule extends PPath implements PBufferedNode {
	
	// Some static constants for convenience.
	
	private static final float DEFAULT_WIDTH=80;
	private static final float DEFAULT_HEIGHT=50;
	private static final float DEFAULT_ARC_WIDTH=10.0f;
	private static final float DEFAULT_ARC_HEIGHT=10.0f;
	private static final float NAME_LABEL_OFFSET=5.0f;
	private static final float NAME_SPACING=15.0f;
	public static final float PARAMETER_SPACING=3.0f;
	private static final float HORIZONTAL_GAP =50.0f;
	
	
	private static final Color DEFAULT_COLOR=Color.black;
	private static final Color DEFAULT_FILL = Color.lightGray;
	public static final Color HIGHLIGHT_COLOR=Color.magenta;
	
	private static final BasicStroke DEFAULT_STROKE= new BasicStroke(3.0f); 
	private static final Font NAME_FONT = new Font("Helvetica",Font.PLAIN,14);
 
	private ModuleInfo info;
	
	// the Rectangle with the bounds of the enclosing border
	private RoundRectangle2D rect;
	
	// The node contiaining the module name
	private PText name;
	// and a version for semantic zooming
	private PText zoomName;
	 
	private float height;
	private float width=0;
	
	private float nameWidth=0;
	
	// The node that will contain nodes for each of the formal parameters
	private PParameterNode labelNodes;
	
	private PNode linkTargets;
	
	private PLinkTarget inputLinkTarget;
	private PLinkTarget outputLinkTarget;
	
	
	/**
	 * The main constructor 
	 * @param canvas The canvas that this module will be displayed on. 
	 * 		Eventually, this might be expanded to account for multiple canvases.
	 * @param module The OME Module being represented
	 * @param x Initial x coordinate (global)
	 * @param y Initial y coordinate
	 */
	public PModule(Connection connection,ModuleInfo info,float x,float y) {
		super();
		this.info = info;
		Module module = info.getModule();
		
		// create the container node for the formal parameters
		labelNodes = new PParameterNode();
		addChild(labelNodes);
		
		// create the name and position it.
		name = new PText(module.getName());
		name.setFont(NAME_FONT);
		name.setPickable(false);
		addChild(name);
		
		name.setOffset(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET);
		
		// calculate starting height for parameters.
		height = NAME_LABEL_OFFSET+((float) name.getBounds().getHeight());
	
		linkTargets = new PNode();
		addChild(linkTargets);	
		float linkTargetHeight = height;
		
		inputLinkTarget = new PLinkTarget();
		linkTargets.addChild(inputLinkTarget);
		inputLinkTarget.setOffset(-PLinkTarget.LINK_TARGET_HALF_SIZE,height);
				
		nameWidth = (float) name.getBounds().getWidth();
		
		// do the individual parameter labels.
		addParameterLabels(module,connection);  
		
		// set width of the whole bounding rectangle
	    width = NAME_LABEL_OFFSET*2+width-PLinkTarget.LINK_TARGET_HALF_SIZE;
		
		// create bounding rectangle, set it to be this node's path,
		// and finish other parameters.
		rect = 
			new RoundRectangle2D.Float(0f,0f,width,height,
					DEFAULT_ARC_WIDTH,DEFAULT_ARC_HEIGHT);
					
		setPathTo(rect);
		setPaint(DEFAULT_FILL);
		setStrokePaint(DEFAULT_COLOR);
		setStroke(DEFAULT_STROKE);
		
		// add the other target
		outputLinkTarget = new PLinkTarget();
		linkTargets.addChild(outputLinkTarget);
		outputLinkTarget.setOffset(width-PLinkTarget.LINK_TARGET_HALF_SIZE,
			linkTargetHeight);
	
		
		//zoomname.
		zoomName = new PText(module.getName());
		zoomName.setFont(NAME_FONT);
		zoomName.setPickable(false);
		zoomName.setConstrainWidthToTextWidth(false);
		zoomName.setScale(2);
		double zwidth = (width-2*NAME_LABEL_OFFSET)/2;
		double zheight = (height-2*NAME_LABEL_OFFSET)/2;
		zoomName.setBounds(new PBounds(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET,
			 zwidth,zheight));
		addChild(zoomName);
		zoomName.setVisible(false);
		 
		 
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
	private void addParameterLabels(Module module,Connection connection) {
		
//		System.err.println("building a PModule for "+module.getName());
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
		PFormalInput inp;
		PFormalOutput outp;
		//PFormalInput ins[] = new PFormalInput [inSize];
		//PFormalOutput outs[] = new PFormalOutput [outSize];
		TreeSet inSet  = new TreeSet();
		TreeSet outSet= new TreeSet();
		
		// get input nodes and find max input width
		float maxInputWidth =0;
		float maxOutputWidth =0;
		
		// for each row.
		System.err.println("module name is "+module.getName());
		for (int i = 0; i < rows; i++) {
			if (i < inSize) {
				// as long as I have more inputs, create them, 
				// add them to label nodes, 
				// and store max width
				param = (FormalParameter) inputs.get(i);
				inp = new PFormalInput(this,param,connection);
				labelNodes.addChild(inp);
				inSet.add(inp);
				if (inp.getLabelWidth() > maxInputWidth)
					maxInputWidth = inp.getLabelWidth();
				/*ins[i]= new PFormalInput(this,param,connection);
				labelNodes.addChild(ins[i]);
				if (ins[i].getLabelWidth() > maxInputWidth)
					maxInputWidth = ins[i].getLabelWidth();
				*/
				
			}
			if (i < outSize) {
				param = (FormalParameter) outputs.get(i);
				outp = new PFormalOutput(this,param,connection);
				labelNodes.addChild(outp);
				outSet.add(outp);
				if (outp.getLabelWidth() > maxOutputWidth)
					maxOutputWidth = outp.getLabelWidth();
				/*outs[i]= new PFormalOutput(this,param,connection);
				labelNodes.addChild(outs[i]);
								if (outs[i].getLabelWidth() > maxOutputWidth)
									maxOutputWidth = outs[i].getLabelWidth();*/
			}
		}
		
		// find maximum width of the whole thing.
		width = maxInputWidth+maxOutputWidth+HORIZONTAL_GAP;
		if (nameWidth > width)
			width = nameWidth;
		
		// find horizontal starting point of the output parameters.
		//float outputColumnX=NAME_LABEL_OFFSET+maxInputWidth+HORIZONTAL_GAP;
		float outputColumnX = width-maxOutputWidth;
		
		
		//height of first one
		height+=NAME_SPACING;
		float rowHeight=0;
		
		
	 		
	 	Object[] ins = inSet.toArray();
	 	Object[] outs = outSet.toArray();
	
		// place things at appropriate x,y.
		for (int i =0; i < rows; i++) {
			// get ith input 
			if (i <inSize) {
				inp = (PFormalInput) ins[i];
				inp.setOffset(NAME_LABEL_OFFSET,height);
				rowHeight = (float) inp.getFullBoundsReference().getHeight();	
			}
			// get ith output
			if (i < outSize) {
				// we want to right-justify these. So, 
				// find difference bwtween the maximum output width
				// and the width of this one.
				//float rightJustifyGap = maxOutputWidth-
				//	((float) outs[i].getFullBoundsReference().getWidth());
				outp = (PFormalOutput) outs[i];
				float rightJustifyGap = maxOutputWidth-
					outp.getLabelWidth();
				// and then move right by that amount.
				outp.setOffset(outputColumnX+rightJustifyGap,height);
				rowHeight = (float) outp.getFullBoundsReference().getHeight();
			}
			// advance to next row in height.
			height += rowHeight; // was +PARAMETER_SPACING;, but now
					// we're adding that spacing into the height of each row.
		}
	}
	
	/**
	 * Paint the node in the given context. This method does some 
	 * simple semantic zooming.
	 * 
	 */
	public void paint(PPaintContext aPaintContext) {
		double s = aPaintContext.getScale();
	
		if (s < PConstants.SCALE_THRESHOLD) {
			labelNodes.setVisible(false);
			labelNodes.setPickable(false);
			name.setVisible(false);
			zoomName.setVisible(true);
			linkTargets.setVisible(true);
		}
		else {
			linkTargets.setVisible(false);
			name.setVisible(true);
			labelNodes.setVisible(true);
			labelNodes.setPickable(true);
			zoomName.setVisible(false);
		} 
		super.paint(aPaintContext);
	} 
	
	public void setHighlighted(boolean v) {
		if (v == true)
			setStrokePaint(HIGHLIGHT_COLOR);
		else
			setStrokePaint(DEFAULT_COLOR);
		repaint();
	}
	
	
	public Module getModule() {
		return info.getModule();
	}
	
	public ModuleInfo getModuleInfo() {
		return info;
	}
	
	public void remove() {
		// iterate over children of labelNodes
		Iterator iter = labelNodes.getChildrenIterator();
		
		PFormalParameter p;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			p.removeLinks();
		}
		info.removeModuleWidget(this);
		removeFromParent();
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

	public void setAllHighlights(boolean v) {
		setModulesHighlighted(v);
		setParamsHighlighted(v);
	}
	public void setModulesHighlighted(boolean v) {
		
		PModule m;
		
		ModuleInfo info =  getModuleInfo();
		ArrayList widgets = info.getModuleWidgets();
		
		
		for  (int i = 0; i < widgets.size(); i++) {
			m = (PModule) widgets.get(i);
			m.setHighlighted(v);
		}
	}
	
	public void setParamsHighlighted(boolean v) {

		Iterator iter = labelNodes.getChildrenIterator();
		PFormalParameter p;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			p.setParamsHighlighted(v);
		}
	}	

	public PBounds getBufferedBounds() {
		PBounds b = getFullBoundsReference();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,
			b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER);
	}
	
	// handles
	
	public void addHandles() {
		addChild(new PModuleHandles(PBoundsLocator.createNorthEastLocator(this)));
		addChild(new PModuleHandles(PBoundsLocator.createNorthWestLocator(this)));
		addChild(new PModuleHandles(PBoundsLocator.createSouthEastLocator(this)));
		addChild(new PModuleHandles(PBoundsLocator.createSouthWestLocator(this)));
	}
	
	public void removeHandles() {
		ArrayList handles = new ArrayList();
		Iterator i = getChildrenIterator();
		while (i.hasNext()) {
			PNode each = (PNode) i.next();
			if (each instanceof PModuleHandles) 
				handles.add(each);
		}
		removeChildren(handles);
	}
	
	public PFormalOutput getFormalOutputNode(FormalOutput out) {
		return (PFormalOutput) getMatchingParameterNode(PFormalOutput.class,out);
	}
	
	
	public PFormalInput getFormalInputNode(FormalInput in) {
	 	return (PFormalInput) getMatchingParameterNode(PFormalInput.class,in);
	}	
	
	private PFormalParameter getMatchingParameterNode(final Class clazz,
		FormalParameter target) {
		
		Iterator iter = labelNodes.getChildrenIterator();
		
		PFormalParameter p;
		FormalParameter param;
		
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			Class pClass = p.getClass();
			if (pClass ==  clazz) {
				param = p.getParameter();
				if (target.getID() == param.getID())
					return p;
			}
		}
		// should never reach her.
		return null;
	}

	public PLinkTarget getInputLinkTarget() {
		return inputLinkTarget;
	}
	
	public PLinkTarget getOutputLinkTarget() {
		return outputLinkTarget;
	}
	
	public boolean isOnInputSide(Point2D pos) {
		boolean res = false;
		globalToLocal(pos);
		float posX = (float)pos.getX();
		PBounds b = getFullBoundsReference();
		float mid = (float) (b.getWidth()/2);
		if (posX < mid)
			res = true;
		return res;
	}
	
	public Collection getInputParameters() {
		PNodeFilter inputFilter = new PNodeFilter() {
			public boolean accept(PNode aNode) {
				// want only those things that are inputs.
				if (!(aNode instanceof PFormalInput))
					return false;
				PFormalInput inp = (PFormalInput) aNode;
				// and can still be origins - don't have anything 
				// linked to them.
				return inp.canBeLinkOrigin();
			}
			public boolean acceptChildrenOf(PNode aNode) {
				return true;
			}
		};
		return labelNodes.getAllNodes(inputFilter,null);
	}
	
	public Collection getOutputParameters() {
		PNodeFilter outputFilter = new PNodeFilter() {
			public boolean accept(PNode aNode) {
				return (aNode instanceof PFormalOutput);
			}
			public boolean acceptChildrenOf(PNode aNode) {
				return true;
			}
		};
		return labelNodes.getAllNodes(outputFilter,null);
	}
}