/*
 * org.openmicroscopy.vis.chains.ChainFrameBase
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

import java.awt.Rectangle;
import javax.swing.JFrame;
import javax.swing.WindowConstants;
import java.awt.Container;
import java.awt.event.WindowEvent;
import java.awt.event.WindowAdapter;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.piccolo.PChainCanvas;

/** 
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ChainFrameBase extends JFrame {
	
	private final Controller controller;
	private Container contentPane;
	private PChainCanvas canvas;
	
	private MenuBar menuBar;
	private ToolBar toolBar;
	
	private ModulePaletteFrame paletteFrame;
	
	public ChainFrameBase(Controller controller,Connection connection,int i) {
		super("OME Chains: "+i);
		setResizable(true);
		
		this.controller = controller;
		
		contentPane = getContentPane();
		// create a chain canvas and add it to this frame.
		canvas = new PChainCanvas(connection);
		contentPane.add(canvas);
		
		setBounds(new Rectangle(710,10,700,700));
		show();		
		setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
		addWindowListener(new WindowAdapter() {
			public void windowClosed(WindowEvent e) {
				ChainFrameBase c = (ChainFrameBase) e.getWindow();
				Controller control = c.getController();
				control.disposeChainCanvas(c);
			}
		});
	}

	public Controller getController() {
			return controller;
	}
}
