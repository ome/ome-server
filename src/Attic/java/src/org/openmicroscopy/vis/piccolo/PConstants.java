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

public class PConstants {

	// for a buffered node, we want to get its bounds with some empty space
	// on each side.  this value gives the amount of buffer space.
	public static final int BORDER=80;	
	
	// magnification at which point we should do our semantic zooming.
	public static final double SCALE_THRESHOLD=0.5;
	
	// time for animation delay
	public static final int ANIMATION_DELAY=500;
	
	// text font
	public static final Font NAME_FONT = new Font("Helvetica",Font.BOLD,14);
	
	// scale multiplier for chains and library
	public static final double SCALE_FACTOR=1.2;
	
	public static final Color CANVAS_BACKGROUND_COLOR = new Color(100,100,100);
	
	public static final Color HIGHLIGHT_COLOR = new Color(154,51,155); 
	public static final Color SELECTED_HIGHLIGHT_COLOR = new Color(51,204,255);
	
	public static final double CATEGORY_LABEL_OFFSET_X=40;
	public static final double CATEGORY_LABEL_OFFSET_Y=20;
	
	// size of a link bulb.
	public static final float LINK_BULB_SIZE=8;
	public static final float LINK_BULB_RADIUS = LINK_BULB_SIZE/2;
	
}