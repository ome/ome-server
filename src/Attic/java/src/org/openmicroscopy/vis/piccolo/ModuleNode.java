/*
 * org.openmicroscopy.vis.piccolo.ModuleNode
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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

import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import java.awt.geom.RoundRectangle2D;
import java.awt.BasicStroke;
//import java.awt.Graphics2D;
import java.awt.Font;
//import java.awt.FontMetrics;
import java.awt.Paint;
import java.awt.Color;
import java.util.List;

/** 
 * <p>Displays a RemoteModule in the Chains scenegraph
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModuleNode extends PPath {
	
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
	
	private static final BasicStroke DEFAULT_STROKE= new BasicStroke(2.0f); 
	private static final Font NAME_FONT = new Font("Helvetica",Font.PLAIN,14);
	private static final Font PARAM_FONT = new Font("Helvetica",Font.PLAIN,8);

	private RemoteModule module;
	
	private RoundRectangle2D rect;
	
	private PText name;
	 
	private float height;
	private float width;
	
	private PLayer labelNodes;
	
	public ModuleNode(RemoteModule module,float x,float y) {
		super();
		this.module=module;
		
		labelNodes = new PLayer();
		addChild(labelNodes);
		// do name.
		name = new PText(module.getName());
		name.setFont(NAME_FONT);
		addChild(name);
		
		name.setOffset(NAME_LABEL_OFFSET,NAME_LABEL_OFFSET);
		height = NAME_LABEL_OFFSET+((float) name.getBounds().getHeight());
		
		
		width = (float) name.getBounds().getWidth();
		
		// do the individual labels.
		addParameterLabels();  
		width = NAME_LABEL_OFFSET*2+width;
		
		rect = 
			new RoundRectangle2D.Float(0f,0f,width,height,
					DEFAULT_ARC_WIDTH,DEFAULT_ARC_HEIGHT);
		setPathTo(rect);
		setStroke(DEFAULT_STROKE);
		setOffset(x,y);
	}
	
	private void addParameterLabels() {
		
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
		PText inTexts[] = new PText[inSize];
		PText outTexts[] = new PText[outSize];
		
		// get input nodes and find max input width
		float maxInputWidth =0;
		float maxOutputWidth =0;
		for (int i = 0; i < rows; i++) {
			if (i < inSize) {
				param = (FormalParameter) inputs.get(i);
				inTexts[i]= new PText(param.getParameterName());
				labelNodes.addChild(inTexts[i]);
				if (inTexts[i].getBounds().getWidth() > maxInputWidth)
					maxInputWidth = (float) inTexts[i].getBounds().getWidth();
			}
			if (i < outSize) {
				param = (FormalParameter) outputs.get(i);
				outTexts[i]= new PText(param.getParameterName());
				labelNodes.addChild(outTexts[i]);
				if (outTexts[i].getBounds().getWidth() > maxOutputWidth)
					maxOutputWidth = (float) outTexts[i].getBounds().getWidth();
			}
			
		}
		
		width = maxInputWidth+maxOutputWidth+HORIZONTAL_GAP;
		float outputColumnX=NAME_LABEL_OFFSET+maxInputWidth+HORIZONTAL_GAP;
		
		
		//height of first one
		height+=NAME_SPACING;
		float rowHeight=0;
		
		// place things at appropriate x,y.
		for (int i =0; i < rows; i++) {
			// get ith input 
			if (i <inSize) {
				inTexts[i].setOffset(NAME_LABEL_OFFSET,height);
				rowHeight = (float) inTexts[i].getBounds().getHeight();	
			}
			// get ith output
			if (i < outSize) {
				float rightJustifyGap = maxOutputWidth-
					((float) outTexts[i].getBounds().getWidth());
				outTexts[i].setOffset(outputColumnX+rightJustifyGap,height);
				rowHeight = (float) outTexts[i].getBounds().getHeight();
			}
			height += rowHeight+PARAMETER_SPACING;
		}
	}
	
	public void paint(PPaintContext aPaintContext) {
		double s = aPaintContext.getScale();
		if (s < SCALE_THRESHOLD)
			labelNodes.setVisible(false);
		else
			labelNodes.setVisible(true);
		super.paint(aPaintContext);
	} 
}