/*
 * org.openmicroscopy.vis.chains.ChainLogin
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
 
import org.openmicroscopy.util.LoginFrame;
import org.openmicroscopy.util.LoginResponder; 
import java.awt.Toolkit;
import java.awt.Dimension;
import java.awt.Rectangle;

/** 
 * An extension of {@link LoginFrame} that centers the login window in the 
 * middle of the screen
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ChainLogin extends LoginFrame {
 	
 	public ChainLogin(LoginResponder responder) {
 		super(responder);
		Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
		Rectangle bounds = getBounds();
		int x = (int) (screen.getWidth()-bounds.getWidth())/2;
		int y = (int) (screen.getHeight()-bounds.getHeight())/2;
		setBounds(x,y,(int) bounds.getWidth(),(int) bounds.getHeight());
 	}
 }