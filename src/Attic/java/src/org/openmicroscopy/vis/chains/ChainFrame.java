/*
 * org.openmicroscopy.vis.chains.ChainFrame
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

import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.piccolo.PChainCanvas;
import edu.umd.cs.piccolo.PCanvas;
import java.awt.Rectangle;
import java.awt.event.WindowEvent;
import java.awt.event.WindowAdapter;


/** 
 * <p>Main operational chain for the Chain-building application holds
 * toolbar and the chain canvas.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class ChainFrame extends ChainFrameBase {
	
	public ChainFrame(Controller controller,Connection connection,int i) {
		super(controller,connection,new String("OME Chains: "+i));
		addWindowListener(new WindowAdapter() {
			public void windowClosed(WindowEvent e) {
				ChainFrame c = (ChainFrame) e.getWindow();
				Controller control = c.getController();
				control.disposeChainCanvas(c);
			}
		});
	}
	
	public PCanvas createCanvas(Connection connection) {
		return new PChainCanvas(connection);
	}
	
	public Rectangle getInitialBounds() {
		return new Rectangle(710,10,700,700);
	}
}