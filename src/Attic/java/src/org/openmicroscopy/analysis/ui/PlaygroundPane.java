/*
 * org.openmicroscopy.analysis.ui.PlaygroundPane
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy.analysis.ui;

import java.awt.*;
import java.awt.geom.*;
import javax.swing.*;
import java.util.*;

import org.openmicroscopy.analysis.*;

public class PlaygroundPane
    extends JPanel
{
    protected static int ARROW_WIDTH = 6;
    protected static int ARROW_HEIGHT = 4;

    protected static Polygon  ARROWHEAD = 
    new Polygon(new int[] {0,-ARROW_WIDTH,-ARROW_WIDTH},
                new int[] {0,ARROW_HEIGHT,-ARROW_HEIGHT},
                3);

    protected JPanel        datasetTab;
    protected JPanel        toolsTab;
    protected JPanel        playgroundPane;
    protected JTabbedPane   tabbedPane;
    protected JTree         analysesTree;
    protected JTree         imagesTree;
    protected JTree         toolsTree;
    protected JDesktopPane  playground;

    protected Chain  chain;
    protected Map           instanceWidgets;

    public PlaygroundPane(Chain chain)
    {
	super(new BorderLayout());

        this.chain = chain;
        this.instanceWidgets = new HashMap();

	JPanel p1;

	datasetTab = new JPanel(new GridLayout(0,1));

	p1 = new JPanel(new BorderLayout());
	p1.setBorder(BorderFactory.createEmptyBorder(2,2,2,2));
	p1.add(new JLabel("Analyses",SwingConstants.CENTER),BorderLayout.NORTH);
	analysesTree = new JTree(new String[] {"Current Analysis","Previous Analysis 1","Previous Analysis 2"});
	analysesTree.setBorder(BorderFactory.createLoweredBevelBorder());
	p1.add(analysesTree,BorderLayout.CENTER);
	datasetTab.add(p1);
	
	p1 = new JPanel(new BorderLayout());
	p1.setBorder(BorderFactory.createEmptyBorder(2,2,2,2));
	p1.add(new JLabel("Images",SwingConstants.CENTER),BorderLayout.NORTH);
	imagesTree = new JTree(new String[] {"Image 1","Image 2","Image 3","Image 4"});
	imagesTree.setBorder(BorderFactory.createLoweredBevelBorder());
	p1.add(imagesTree,BorderLayout.CENTER);
	datasetTab.add(p1);
	
	toolsTab = new JPanel(new GridLayout(0,1));
	
	p1 = new JPanel(new BorderLayout());
	p1.setBorder(BorderFactory.createEmptyBorder(2,2,2,2));
	p1.add(new JLabel("Tools",SwingConstants.CENTER),BorderLayout.NORTH);
	toolsTree = new JTree(new String[] {"Test 1","Test 2"});
	toolsTree.setBorder(BorderFactory.createLoweredBevelBorder());
	p1.add(toolsTree,BorderLayout.CENTER);
	toolsTab.add(p1);
	
	tabbedPane = new JTabbedPane(SwingConstants.TOP);
	tabbedPane.addTab("Dataset",datasetTab);
	tabbedPane.addTab("Tools",toolsTab);
	tabbedPane.setPreferredSize(new Dimension(150,10));
	tabbedPane.setBorder(BorderFactory.createCompoundBorder(
	    BorderFactory.createRaisedBevelBorder(),
	    BorderFactory.createEmptyBorder(2,2,2,2)));

	playgroundPane = new JPanel(new BorderLayout());

	playground = new JDesktopPane();
        playground.setOpaque(false);
	playgroundPane.add(playground,BorderLayout.CENTER);
        playgroundPane.setOpaque(false);

        JSplitPane  split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT,
                                           false,
                                           tabbedPane,
                                           playgroundPane);
 	//add(tabbedPane,BorderLayout.WEST);
	//add(playgroundPane,BorderLayout.CENTER);
        add(split,BorderLayout.CENTER);
    }


    public void addNodeWidget(ChainNodeWidget cnWidget, int x, int y)
    {
        Chain.Node       node = cnWidget.getChainNode();
        ChainNodeWidget  oldWidget = (ChainNodeWidget) instanceWidgets.get(node);

        if (oldWidget != null)
        {
            // remove the old widget first
            playground.remove(oldWidget);
        }

	playground.add(cnWidget);
        instanceWidgets.put(node,cnWidget);
	cnWidget.setLocation(new Point(x,y));
	cnWidget.setSize(cnWidget.getPreferredSize());
    }

    public void paintChildren(Graphics g) 
    {
        super.paintChildren(g);

        Graphics2D g2 = (Graphics2D) g;
        Iterator   i = chain.getLinkIterator();

        g2.setPaint(Color.black);

        Point playgroundLocation = playgroundPane.getLocation();
        AffineTransform  defaultTransform = g2.getTransform();

        while (i.hasNext())
        {
            Chain.Link  link = (Chain.Link) i.next();

            //System.err.println("*** "+link);

            ChainNodeWidget  fromWidget = (ChainNodeWidget) instanceWidgets.get(link.getFromNode());
            ChainNodeWidget  toWidget = (ChainNodeWidget) instanceWidgets.get(link.getToNode());

            if ((fromWidget == null) || (toWidget == null))
            {
                System.err.println("Parameter link for a node that has no widget.");
                continue;
            }
            
            Point  fromPoint = null, toPoint = null;

            try
            {
                fromPoint = fromWidget.getOutputNubLocation(link.getFromOutput());
                toPoint = toWidget.getInputNubLocation(link.getToInput());
            } catch (ArrayIndexOutOfBoundsException e) {
                System.err.println("Parameter link to invalid input/output.");
                continue;
            }

            fromPoint.translate(playgroundLocation.x,playgroundLocation.y);
            toPoint.translate(playgroundLocation.x,playgroundLocation.y);
            
            //System.err.println("  "+fromPoint.x+","+fromPoint.y+" "+toPoint.x+","+toPoint.y);

            double  x1 = fromPoint.getX();
            double  y1 = fromPoint.getY();
            double  x2 = toPoint.getX();
            double  y2 = toPoint.getY();
            double  dX = x2-x1;
            double  xM = x1+(dX/2);
            double  xT = x2-(ARROW_WIDTH*2);
            double  xS = x1+(ARROW_WIDTH);

            /*            
            g2.draw(new Line2D.Double(x1,y1,xM,y1));
            g2.draw(new Line2D.Double(xM,y1,xM,y2));
            g2.draw(new Line2D.Double(xM,y2,x2,y2));
            */

            g2.draw(new Line2D.Double(x1,y1,xS,y1));
            g2.draw(new Line2D.Double(xS,y1,xT,y2));
            g2.draw(new Line2D.Double(xT,y2,x2-1,y2));

            g2.transform(AffineTransform.getTranslateInstance(toPoint.x,toPoint.y));
            g2.fill(ARROWHEAD);
            g2.setTransform(defaultTransform);
        }

    }
}
