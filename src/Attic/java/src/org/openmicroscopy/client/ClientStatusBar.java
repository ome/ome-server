/*
 * org.openmicroscopy.client.ClientStatusBar
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

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.awt.geom.*;
import javax.swing.*;
import javax.swing.border.*;


/**
 *  Creates and maintains a workstation status bar. At a minimum, displays
 * currently selected project, dataset, and analysis.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */

public class ClientStatusBar extends JLabel {
    ClientContents ourClient;
    //Color backgnd       = new Color(232, 238, 0);
    Color backgnd       = new Color(232, 238, 157);
    Color statusColor   = new Color(232, 100, 0);
    String projectLabel = "Project: ";
    String datasetLabel = "  Dataset: ";
    String chainLabel   = "  Analysis: ";


    /** Instantiate the one and only status bar this workstation
     * session will use.
     * @param Client  the current ClientContents context
     */

    public ClientStatusBar (ClientContents Client) {
	ourClient = Client;

	this.setBackground(backgnd);
	this.setOpaque(true);
	this.setFont(new java.awt.Font("Dialog", 0, 12));
	this.setAlignmentX((float) 50.0);
	this.setAlignmentY((float) 1.0);
	this.setBorder(BorderFactory.createRaisedBevelBorder());
	//this.setMaximumSize(new Dimension(32767, 17));
	this.setMinimumSize(new Dimension(161, 17));
	this.setPreferredSize(new Dimension(161, 17));
    }


    /** Implements the paint method for the status bar. This
     * method gets called by the runtime whenever it believes
     * that any part of this component needs repainting. Does 
     * all the work for formatting and displaying the status bar.
     * @param g  Graphics context
     */

    public void paint(Graphics g) {
	Graphics2D g2 = (Graphics2D)g;
	FontRenderContext frc;
	LineMetrics metrics;
	int width;
	int height;
	float x = 1;
	float y = 1;
	Font labelFont = new Font("Serif", Font.PLAIN, 12);
	Font nameFont = new Font("Serif", Font.BOLD, 12);
	boolean projectSet;
	boolean datasetSet;
	boolean chainSet;
	String projectName;
	String datasetName;
	String chainName;

	width  = getSize().width;
	height = getSize().height;
	g2.setColor(backgnd);
	g2.fillRect(0, 0, width, height);
	g2.setColor(statusColor);
	projectSet = ourClient.getProjectSet();

	System.out.println("project set = "+projectSet+"\n");

	if (projectSet) {
	    projectName = ourClient.getProjectName();
	    x += drawFragment(g2, labelFont, projectLabel, x, y);
	    x += drawFragment(g2, nameFont, projectName, x, y);
	    x += drawFragment(g2, labelFont, datasetLabel, x, y);

	    datasetSet = ourClient.getDatasetSet();
	    if (datasetSet) {
		datasetName = ourClient.getDatasetName();
		x += drawFragment(g2, nameFont, datasetName , x, y);
	    } else {
		x += drawFragment(g2, nameFont, "no dataset selected", x, y);
	    }

	    chainSet = ourClient.getChainSet();
	    x += drawFragment(g2, labelFont, chainLabel, x, y);
	    if (chainSet) {
		chainName = ourClient.getChainName();
		x += drawFragment(g2, nameFont, chainName , x, y);
	    } else {
		x += drawFragment(g2, nameFont, "no analysis selected", x, y);
	    }

	} else {
	    x += drawFragment(g2, nameFont, "no project selected", x, y);
	}
    }


    /**
     * Calls the paint method, and provides a hook 
     * for future code that would add features to the bar.
     */

    public void setStatusMsg () {
	repaint();
    }


    /**
     * Draws a single fragment of text -- that is, one that uses
     * a single font, and displays in a contiguous area.
     *
     * @param g Graphics2D graphics context
     * @param fragFont  font to use for this text
     * @param x         x display start position
     * @param y         y display start position
     */
  private float drawFragment(Graphics2D g, Font fragFont,
			  String fragText, float x, float y ) {
      float width;
      Rectangle2D box;

      g.setFont(fragFont);
      FontRenderContext frc = g.getFontRenderContext();
      box = fragFont.getStringBounds(fragText, frc);
      width = (float)box.getWidth();
      y = (float)box.getHeight();
      setBackground(backgnd);
      g.drawString(fragText, x, y);

      return width;
  }

}
