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
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;
import java.util.*;

import org.openmicroscopy.*;

public class PlaygroundPane
    extends JPanel
{
    protected static int ARROW_WIDTH = 6;
    protected static int ARROW_HEIGHT = 4;

    protected static Polygon  ARROWHEAD = 
    new Polygon(new int[] {0,-ARROW_WIDTH,-ARROW_WIDTH},
                new int[] {0,ARROW_HEIGHT,-ARROW_HEIGHT},
                3);

    protected JDesktopPane  playground;

    protected Chain           chain;
    protected Map             instanceWidgets;
    protected WidgetListener  widgetListener;

    protected class ResizingDesktopPane
        extends JDesktopPane
    {
        public Dimension getPreferredSize()
        {
            int  width = 0, height = 0;
            Iterator  i = instanceWidgets.values().iterator();
            Rectangle bounds = new Rectangle();
            while (i.hasNext())
            {
                ChainNodeWidget widget = (ChainNodeWidget) i.next();
                widget.getBounds(bounds);

                int x2 = bounds.x+bounds.width;
                if (x2 > width) width = x2;

                int y2 = bounds.y+bounds.height;
                if (y2 > height) height = y2;
            }

            return new Dimension(width,height);
        }

        public void paintChildren(Graphics g) 
        {
            super.paintChildren(g);

            Graphics2D g2 = (Graphics2D) g;
            Iterator   i = chain.getLinkIterator();

            g2.setPaint(Color.black);

            //Point playgroundLocation = playgroundPane.getLocation();
            Point playgroundLocation = new Point(0,0);
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

                g2.setStroke(s1);
                g2.draw(new Line2D.Double(xS,y1,xT,y2));

                g2.setStroke(s2);
                g2.draw(new Line2D.Double(x1,y1,xS,y1));
                g2.draw(new Line2D.Double(xT+1,y2,x2-1,y2));

                g2.transform(AffineTransform.getTranslateInstance(toPoint.x,toPoint.y));
                g2.fill(ARROWHEAD);
                g2.setTransform(defaultTransform);
            }

        }
    }

    public PlaygroundPane(Chain chain)
    {
        super(new BorderLayout());

        this.chain = chain;
        this.instanceWidgets = new HashMap();

        playground = new ResizingDesktopPane();
        playground.setOpaque(false);
        JScrollPane  scroll = 
            new JScrollPane(playground,
                            ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS,
                            ScrollPaneConstants.HORIZONTAL_SCROLLBAR_ALWAYS);
        //scroll.getViewport().setScrollMode(JViewport.BACKINGSTORE_SCROLL_MODE);
        add(scroll,BorderLayout.CENTER);
        setOpaque(false);

        widgetListener = new WidgetListener();
    }

    public Chain getChain() { return chain; }

    private class WidgetListener
        implements ComponentListener
    {
        private void updatePlayground()
        {
            PlaygroundPane.this.repaint();
        }

        public void componentHidden(ComponentEvent e) { updatePlayground(); }
        public void componentMoved(ComponentEvent e) { updatePlayground(); }
        public void componentResized(ComponentEvent e) { updatePlayground(); }
        public void componentShown(ComponentEvent e) { updatePlayground(); }
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

        cnWidget.addComponentListener(widgetListener);
        playground.add(cnWidget);
        instanceWidgets.put(node,cnWidget);
        cnWidget.setLocation(new Point(x,y));
        cnWidget.setSize(cnWidget.getPreferredSize());
        cnWidget.unhighlightAllLabels();
    }

    private static Stroke s1 = new BasicStroke(1.0f);
    private static Stroke s2 = new BasicStroke(2.0f);

}
