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
import java.awt.BasicStroke;

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
	public static final Font THUMBNAIL_NAME_FONT = 
		new Font("Helvetica",Font.BOLD,6);
	
	public static final Font THUMBNAIL_LABEL_FONT = 
		new Font("Helvetica",Font.BOLD,8);
	public static final Font PROJECT_LABEL_FONT = 
			new Font("Helvetica",Font.BOLD,10);
	public static final Font TOOLTIP_FONT = new Font("Helvetica",Font.BOLD,12);
	public static final Font NAME_FONT = new Font("Helvetica",Font.BOLD,14);	
	public static final Font LABEL_FONT  = new Font("Helvetica",Font.BOLD,18);
	public static final Font LARGE_NAME_FONT = 
		new Font("Helvtical",Font.BOLD,24);
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
	 * Color for category boxes.
	 */
    public static final Color CATEGORY_COLOR= new Color(204,204,255,100);
	
	/**
	 * color for an executed chain.
	 */	
	public static final Color EXECUTED_COLOR = new Color(150,150,255,100);


	public static final Color LOCKED_COLOR = Color.RED;
    /**
     * default colors
     */
    
    public static final Color DEFAULT_COLOR = Color.BLACK;
    public static final Color DEFAULT_TEXT_COLOR = DEFAULT_COLOR;
    public static final Color DEFAULT_FILL = Color.LIGHT_GRAY;
    
    /**
     * link highlight
     */
    
    public static final Color LINK_HIGHLIGHT_COLOR=Color.WHITE;
    
    /**
     * colors for generic box
     * 
     */
    
    public static final Color HIGHLIGHT_COLOR_OUTER = new Color(215,140,47);
    public static final Color HIGHLIGHT_COLOR_MIDDLE = new Color(223,163,89);
    public static final Color HIGHLIGHT_COLOR_INNER = new Color(231,186,130);
    
    public static final Color PROJECT_SELECTED_COLOR = new Color(0,0,255);
    public static final Color PROJECT_ACTIVE_COLOR = new Color(0,0,220);
    public static final Color PROJECT_ROLLOVER_COLOR = new Color(0,0,200);
    
    /**
     * Border colors
     *
     */
    public static final Color BORDER_OUTER = new Color(191,191,191);
	public static final Color BORDER_MIDDLE = new Color(212,212,212);
	public static final Color BORDER_INNER =  new Color(233,233,233);
	
	public static final Color HALO_COLOR = Color.RED;
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
	public static final float LINK_TARGET_SIZE=10;
	public static final float LINK_TARGET_HALF_SIZE=LINK_TARGET_SIZE/2;
	public static final float  LINK_TARGET_BUFFER=3;
	
	public static final BasicStroke LINK_STROKE=
		new BasicStroke(1,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND);
	
 	
	public static final double FIELD_LABEL_SCALE=4;
	
	public static final double ITEM_LABEL_SCALE=3;
	
	
	public static final float STROKE_WIDTH=4.0f;
	public static final BasicStroke BORDER_STROKE = new BasicStroke(STROKE_WIDTH);
	public static final BasicStroke MODULE_STROKE = new BasicStroke(5);
}