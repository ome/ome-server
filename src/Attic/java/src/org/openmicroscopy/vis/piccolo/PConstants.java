/*
 * org.openmicroscopy.vis.piccolo.PConstants
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

import java.awt.Font;
import java.awt.Color;

/** 
 *
 * Somce constant values used throughout the piccolo code in the chain-
 * building app. 
 *  
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PConstants {

	/**
	 * For a buffered node, we want to get its bounds with some empty space
	 * on each side.  this value gives the amount of buffer space.
	 */
	public static final int BORDER=80;
	
	public static final int SMALL_BORDER=20;	
	
	
	/**
	 * Magnification threshold for sematic zooming. When magnification decreases
	 * past this point, zoom-out to lower-level of detail, and vice-versa.
	 */ 
	public static final double SCALE_THRESHOLD=0.5;
	
	/**
	 * Animation delay when scaling a node to center in the canvas. 
	 */
	public static final int ANIMATION_DELAY=500;
	
	/**
	 * The {@link Font} used for the name of a Formal Parameter 
	 */
	public static final Font NAME_FONT = new Font("Helvetica",Font.BOLD,14);
	
	/**
	 * Scaling multipliers for events that scale a canvas gradually - as 
	 * opposed to events that scale to a particular node. 
	 */
	public static final double SCALE_FACTOR=1.2;
	
	/**
	 * The standard background color for Piccolo Canvases
	 */
	public static final Color CANVAS_BACKGROUND_COLOR = Color.WHITE;
	
	
	/**
	 * The color used to identify items that can be linked to the current item.
	 */
	public static final Color HIGHLIGHT_COLOR = new Color(154,51,155); 
	
	/** 
	 * The color that can be used to identify items that are the same type 
	 * (ie., {@link PModule}s corresponding to the same module) as the current
	 * selection 
	 */
	public static final Color SELECTED_HIGHLIGHT_COLOR = new Color(51,204,255);
	
	/** 
	 * Positional offsets for a category name in a {@link PCategoryBox} in a 
	 * {@link PPaletteCanvas}
	 *
	 */
	public static final double CATEGORY_LABEL_OFFSET_X=40;
	public static final double CATEGORY_LABEL_OFFSET_Y=20;
	
	/**
	 * Size parameters for the circle at the end of a {@link PLink}
	 */
	public static final float LINK_BULB_SIZE=8;
	public static final float LINK_BULB_RADIUS = LINK_BULB_SIZE/2;
	
}