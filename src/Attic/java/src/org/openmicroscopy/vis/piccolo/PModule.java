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
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PPaintContext;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PNodeFilter;
import edu.umd.cs.piccolox.util.PBoundsLocator;

import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.Chain.Node;
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


/** 
 * A Piccolo widget for an OME analysis  module. This widget will consist of a 
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
	
	/*
	 * 
	 * Some static constants for convenience.
	 */
	
	private static final float DEFAULT_WIDTH=80;
	private static final float DEFAULT_HEIGHT=50;
	private static final float DEFAULT_ARC_WIDTH=10.0f;
	private static final float DEFAULT_ARC_HEIGHT=10.0f;
	private static final float NAME_LABEL_OFFSET=5.0f;
	private static final float NAME_SPACING=15.0f;
	public static final float PARAMETER_SPACING=3.0f;
	private static final float HORIZONTAL_GAP =50.0f;
	private static final float NAME_MAG=1;
	private static final float ZOOM_MAG=2;
	
	/**
	 * Deffault colors and strokes
	 */
	private static final Color DEFAULT_COLOR=Color.black;
	private static final Color DEFAULT_FILL = Color.lightGray;
	
	private static final BasicStroke DEFAULT_STROKE= new BasicStroke(5.0f); 
	private static final Font NAME_FONT = new Font("Helvetica",Font.BOLD,14);

	
	/**
	 *  The Rectangle with the bounds of the enclosing border
	 */
	private RoundRectangle2D rect;
	
	/**
	 * The node contiaining the module name
	 */
	private PText name;
	
	/**
	 * A version of the module name suitable for semantic zooming
	 */
	private PText zoomName;
	 
	/**
	 * Dimensions of the PModule
	 */
	private float height;
	private float width=0;
	
	/**
	 * The Width of the name node.
	 */
	private float nameWidth=0;
	
	/**
	 *  The node that will contain nodes for each of the formal parameters
	 */
	private PParameterNode labelNodes;
	
	/**
	 * A node that holds the square rectangle {@link PLinkTarget}s associated
	 * with each of the inputs and outputs.
	 * 
	 */
	private PNode linkTargets;
	
	/**
	 * The {@Plink LinkTarget}s for the modules as a whole
	 */
	private PLinkTarget inputLinkTarget;
	private PLinkTarget outputLinkTarget;
	
	/**
	 * Each {@link PModule} corresponds to a node in a chain, if it is part of
	 * an analysis chain
	 */
	private Node node=null;
	
	/**
	 * The OME object corresponding to the analysis module that this object
	 * represents
	 */
	private CModule module;
	
	public PModule() {
	}
	
	public PModule(Connection connection,CModule module,float x,float y) {
		this(connection,module);
		setOffset(x,y);
	}
	 
	/**
	 * The main constructor 
	 * @param connection - the connection to the OME database
	 * @param module The OME Module being represented
	 */
	public PModule(Connection connection,CModule module) {
		super();
	
		this.module = module;
		
		// create the container node for the formal parameters
		labelNodes = new PParameterNode();
		addChild(labelNodes);
		
		// create the name and position it.
		name = new PText(module.getName());
		name.setFont(NAME_FONT);
		name.setPickable(false);
		name.setScale(NAME_MAG);
		addChild(name);
		
		name.setOffset(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET);
		PBounds nameBounds = name.getGlobalFullBounds();
		
		// calculate starting height for parameters.
		height = NAME_LABEL_OFFSET+((float) nameBounds.getHeight());
	
		// build the node for the link targets
		linkTargets = new PNode();
		addChild(linkTargets);	
		
		float linkTargetHeight = height;
		
		// add the input link target
		inputLinkTarget = new PLinkTarget();
		linkTargets.addChild(inputLinkTarget);
		inputLinkTarget.setOffset(-PLinkTarget.LINK_TARGET_HALF_SIZE,height);
				
		nameWidth = (float) nameBounds.getWidth();
		
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
	
		
		// set up the magnified version of the module name
		zoomName = new PText(module.getName());
		zoomName.setFont(NAME_FONT);
		zoomName.setPickable(false);
		zoomName.setConstrainWidthToTextWidth(false);
		zoomName.setScale(ZOOM_MAG);
		double zwidth = (width-2*NAME_LABEL_OFFSET)/ZOOM_MAG;
		double zheight = (height-2*NAME_LABEL_OFFSET)/ZOOM_MAG;
		zoomName.setBounds(new PBounds(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET,
			 zwidth,zheight));
		addChild(zoomName);
		zoomName.setVisible(false);
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
	private void addParameterLabels(CModule module,Connection connection) {
		
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
		
		// Store them in {@link TreeSet} objects, so things will be sorted,
		// based on the id numbers of the semantic types of the associated 
		// parameters   See PFormalParameter for details
		TreeSet inSet  = new TreeSet();
		TreeSet outSet= new TreeSet();
		
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
				inp = new PFormalInput(this,param,connection);
				labelNodes.addChild(inp);
				inSet.add(inp);
				if (inp.getLabelWidth() > maxInputWidth)
					maxInputWidth = inp.getLabelWidth();
			}
			if (i < outSize) {
				param = (FormalParameter) outputs.get(i);
				outp = new PFormalOutput(this,param,connection);
				labelNodes.addChild(outp);
				outSet.add(outp);
				if (outp.getLabelWidth() > maxOutputWidth)
					maxOutputWidth = outp.getLabelWidth();
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
				outp = (PFormalOutput) outs[i];
				float rightJustifyGap = maxOutputWidth-
					outp.getLabelWidth();
				// and then move right by that amount.
				outp.setOffset(outputColumnX+rightJustifyGap,height);
				rowHeight = (float) outp.getFullBoundsReference().getHeight();
			}
			// advance to next row in height.
			height += rowHeight; 
		}
	}
	
	/**
	 * Paint the node in the given context. This method does some 
	 * simple semantic zooming. If the scale factor is below the threshold - 
	 * the user has zoomed out - don't show the individual parameters and the 
	 * link targets - just show the larger module name. Otherwise, 
	 * show all of the details.
	 * 
	 */
	public void paint(PPaintContext aPaintContext) {
		double s = aPaintContext.getScale();
	
		if (s <= PConstants.SCALE_THRESHOLD) {
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
	
	/**
	 * Set the color of the module if it is highlighted.
	 * @param v true if the module is highlighted, else false
	 */
	public void setHighlighted(boolean v) {
		if (v == true)
			setStrokePaint(PConstants.SELECTED_HIGHLIGHT_COLOR);
		else
			setStrokePaint(DEFAULT_COLOR);
		repaint();
	}
	
	/**
	 * Set the color indiciating that the module can be linked to from 
	 * the selected module
	 * @param v true if this module can be linked to from the current selection.
	 * 
	 */
	public void setLinkableHighlighted(boolean v) {
		if (v == true)
			setStrokePaint(PConstants.HIGHLIGHT_COLOR);
		else
			setStrokePaint(DEFAULT_COLOR);
		repaint();
	}
	
	/**
	 * 
	 * @return the OME Module associated with this graphical display
	 */
	public Module getModule() {
		return module;
	}
	
	
	/**
	 * to remove a {@link PModule}, remove all of its links,
	 * remove this widget from the list of widgets for the corresponding OME 
	 * Module, and remove this widget from the scenegraph
	 *
	 */
	public void remove() {
		// iterate over children of labelNodes
		Iterator iter = labelNodes.getChildrenIterator();
		
		PFormalParameter p;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			p.removeLinks();
		}
		module.removeModuleWidget(this);
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
	 * translate - call super class and then notify all who are interested 
	 * in receiving events from this node.
	 */
	
	public void translate(double dx,double dy) {
		super.translate(dx,dy);
		fireStateChanged();
	}

	public void setAllHighlights(boolean v) {
		setModulesHighlighted(v);
		setParamsHighlighted(v);
	}
	
	/**
	 * Set all of the {@link PModule} objects with the same OME {@link Module} 
	 * as this one to have the same highlighted state.
	 * @param v true if the modules should be highlighted, else false
	 */
	public void setModulesHighlighted(boolean v) {
		
		module.setModulesHighlighted(v);
	}
	
	/***
	 * Set the parameters associated with this module to be highlighted.
	 * @param v true if the parameters should be highlighted, else false
	 */
	public void setParamsHighlighted(boolean v) {

		Iterator iter = labelNodes.getChildrenIterator();
		PFormalParameter p;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			p.setParamsHighlighted(v);
		}
	}	

	public PBounds getBufferedBounds() {
		PBounds b = getGlobalFullBounds();
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
	
	/**
	 * @param out The object wrapping an OME {@link FormalOutput} for this 
	 * 	module
	 * @return The {@link PFormalOutput} node for that {@link FormalOutput} 
	 */
	public PFormalOutput getFormalOutputNode(FormalOutput out) {
		return (PFormalOutput) getMatchingParameterNode(PFormalOutput.class,out);
	}
	
	/**
	 * @param in The object wrapping an OME {@link FormalInput} for this 
	 * 	module
	 * @return The {@link PFormalInput} node for that {@link FormalInput} 
	 */
	public PFormalInput getFormalInputNode(FormalInput in) {
	 	return (PFormalInput) getMatchingParameterNode(PFormalInput.class,in);
	}	
	
	/**
	 * 
	 * @param clazz The class ({@link PFormalOutput} or {@link PFormalInput} 
	 * 		desired
	 * @param target The {@link FormalParameter} object to be mached
	 * @return The corresponding {@link PFormalParmeter}
	 */
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
		// should never reach here
		return null;
	}

	public PLinkTarget getInputLinkTarget() {
		return inputLinkTarget;
	}
	
	public PLinkTarget getOutputLinkTarget() {
		return outputLinkTarget;
	}
	
	/**
	 * A position is no the input side if it's to the left of the horizontal
	 * midpoint. Used to determine which side the user clicked on when creating 
	 * bulk links between modules
	 * @param pos A location on the module.
	 * @return True if thhe location is on the left half, else false
	 */
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
	
	/**
	 * 
	 * @return a sorted list of all of the input parameters that don't already
	 * have incoming links. These parameters are identified via
	 * 	a {@link PNodeFilter}
	 */
	public TreeSet getInputParameters() {
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
		return new TreeSet(labelNodes.getAllNodes(inputFilter,null));
	}
	
	/**
	 * 
	 * @return a sorted list of all of the output parameters. These parameters 
	 * are identified via a {@link PNodeFilter}
	 */
	public TreeSet getOutputParameters() {
		PNodeFilter outputFilter = new PNodeFilter() {
			public boolean accept(PNode aNode) {
				return (aNode instanceof PFormalOutput);
			}
			public boolean acceptChildrenOf(PNode aNode) {
				return true;
			}
		};
		return new TreeSet(labelNodes.getAllNodes(outputFilter,null));
	}
	
	public void setNode(Node node) {
		this.node = node;
	}
	
	public Node getNode() {
		return node;
	}
	
	public double getX() {
		return getFullBounds().getX();
	}
	
	public double getY() {
		return getFullBounds().getY();
	}
}