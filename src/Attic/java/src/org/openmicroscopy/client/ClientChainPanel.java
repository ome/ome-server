/*
 * org.openmicroscopy.client.ClientChainPanel
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
 * Written by:    Brian S. Hughes <bshughes@mit.edu>
 *
 *------------------------------------------------------------------------------
 */



package org.openmicroscopy.client;

import java.awt.Color;
import java.awt.Rectangle;
import java.awt.BasicStroke;
import java.awt.geom.Rectangle2D;
import java.awt.Image;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Dimension.*;
import java.awt.geom.AffineTransform;
import java.util.Iterator;
import java.util.List;
import javax.swing.*;
import org.openmicroscopy.remote.*;
import org.openmicroscopy.vis.ome.*;
import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.vis.chains.*;
import org.openmicroscopy.vis.piccolo.PModule;
import org.openmicroscopy.vis.piccolo.PChainLibraryCanvas;
import org.openmicroscopy.*;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PNode;





/**
 *  Populate a JPanel with the schematic diagram of an analysis chain.
 * context for the workstation.
 *
 * @author  Brian S. Hughes
 * @version 2.0
 * @since   2.0.3
 */

public class ClientChainPanel extends JPanel {
    private PChainLibraryCanvas canvas;
    private Connection conn;
    private Controller cntrl;
    private Chain   ch;
    private CChain cch;
    private static final int INDENT = 7;
    private static final String TEXT_CLASS = "PText";
    private static final String PMODULE_CLASS = "org.openmicroscopy.vis.piccolo.PModule";

    public ClientChainPanel(Controller controller,Connection connection) {
	super();
	conn = connection;
	cntrl = controller;
	setPreferredSize(new java.awt.Dimension(400, 300));
	setBackground(new Color(255, 175, 103));
    }

    public PChainLibraryCanvas setCanvas() {
	Chain ch = cntrl.getChain();
	CChain cch = new CChain((RemoteSession)(conn.getSession()), ch.toString());
	canvas = new PChainLibraryCanvas(conn, cch);
	canvas.setBounds(getBounds());
	canvas.getCamera().setViewScale(1f);
	System.err.println("made new canvas");
	cch.layout();
	System.err.println("did layout");
	//AffineTransform at = new AffineTransform(1,0,0,0,1,0);
	//canvas.getCamera().setViewTransform(at);
	canvas.drawChain(cch);
	canvas.scaleToSize();
	Rectangle canB = canvas.getBounds();
	System.err.println("   at creation, this canvas's bounds: "+canB.width+" x "
			   +canB.height+" X: "+canB.x+" Y: "+canB.y);
	return canvas;
    }
    
    public PChainLibraryCanvas getCanvas() {
	return canvas;
    }

    public void dumpContents() {
	PCamera pCam = getCanvas().getCamera();
	List refL = pCam.getLayersReference();
	Iterator it = refL.iterator();
	System.err.println("Camera has "+pCam.getLayerCount()+" layers");
	while (it.hasNext()) {
	    PLayer lay = (PLayer)it.next();
	    System.err.println("   ref layer: "+ lay.toString());
	    System.err.println("        has "+lay.getChildrenCount()+" children");
	    Iterator chIt = lay.getChildrenIterator();
	    while (chIt.hasNext()) {
		PNode pn = (PNode)chIt.next();
		System.err.println("\t   class: "+pn.getClass()+"  "+pn.toString());
	    }
	}
	//repaint();
    }

    public void paint(Graphics g) {
	super.paint(g);
    Graphics2D g2 = (Graphics2D)g;
    PCamera pCam = getCanvas().getCamera();
    List refL = pCam.getLayersReference();
    Iterator it = refL.iterator();
    int x = 0;
    int y = 20;

    //setBackground(new Color(255, 175, 203));
    g2.drawString("Drawing Chain", 0,y);
    y += 20;
    System.err.println("    Repainting ClientChainPanel");
    
    while (it.hasNext()) {
        PLayer lay = (PLayer)it.next();
        Iterator chIt = lay.getChildrenIterator();
        while (chIt.hasNext()) {
	    PNode pn = (PNode)chIt.next();
	    System.err.println("Class: "+pn.getClass().toString());
	    if (pn.getClass().getName().equals(PMODULE_CLASS)) {
		g2.drawString(new String("children:"), x, y);
		y += 12;
		PModule pm = (PModule)pn;
		int kids =pm.getChildrenCount();
		while (kids-- > 0) {
		    String modKid = pm.getChild(kids).getClass().toString();
		    if (pm.getChild(kids).getClass().toString().endsWith(TEXT_CLASS)) {
			PText pt = (PText)(pm.getChild(kids));
			g2.drawString(pt.getText(), x, y);
			//g2.drawString(new String("   "+), x, y);
			y += 12;
		    }
		}
	    }
        }
    }
  }
	

}

