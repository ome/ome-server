/*
 * org.openmicroscopy.vis.chains.ModulePaletteFrame
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




package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.piccolo.PPaletteCanvas;
import org.openmicroscopy.vis.ome.Connection;
import javax.swing.JFrame;
import java.awt.Rectangle;

/** 
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ModulePaletteFrame extends JFrame {

	public PPaletteCanvas canvas = null;
	
	public static int HEIGHT=600;
	public static int WIDTH=600;
	
	public ModulePaletteFrame(Connection connection) {
		super("OME Module Palette");
		
		canvas = new PPaletteCanvas(connection);
		
		getContentPane().add(canvas);
		int w = canvas.getPaletteWidth();
		System.err.println("width is "+w);
		int h = canvas.getPaletteHeight();
		System.err.println("heightis "+h);
		double scale = ((double) HEIGHT)/((double) h);
		canvas.scaleToCenter(scale);
		setBounds(new Rectangle(710,10,WIDTH,HEIGHT));
		show();	
	}
	
}
	