/*
 * org.openmicroscopy.analysis.ui.PlaygroundController
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

import java.awt.event.*;
import javax.swing.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import org.openmicroscopy.*;

public class PlaygroundController
{
    PlaygroundPane  playgroundPane;
    JLabel          statusLabel;
    List            nodeWidgets;

    Module.FormalParameter  lastParameter = null;
    Module.FormalParameter  lastSelectedParam = null;
    Chain.Node              lastNode = null;
    boolean                 lastInput;
    boolean                 statusEmpty = true;

    public PlaygroundController()
    {
        this.nodeWidgets = new ArrayList();
    }

    public void setPlaygroundPane(PlaygroundPane playgroundPane)
    {
        this.playgroundPane = playgroundPane; 
        playgroundPane.addMouseListener(new MouseAdapter()
            {
                public void mouseClicked(MouseEvent e)
                {
                    if (!e.isConsumed())
                        unselectAttributeType();
                }
            });
    }

    public void setStatusLabel(JLabel statusLabel)
    { this.statusLabel = statusLabel; }

    public void addNodeWidget(ChainNodeWidget nw)
    {
        nodeWidgets.add(nw);
    }

    public void removeNodeWidget(ChainNodeWidget nw)
    {
        nodeWidgets.remove(nw);
    }

    private void displayStatusText(String msg)
    {
        if (statusLabel != null)
        {
            //System.err.println(msg);
            statusLabel.setText(msg);
            statusLabel.repaint();
        }
    }

    public void displayMessage(String msg)
    {
        if (statusEmpty)
        {
            displayStatusText(msg);
            statusEmpty = false;
        }
    }

    public void displayParameter(Module.FormalParameter param)
    {
        if (statusEmpty)
        {
            AttributeType type = param.getAttributeType();
            String typeName = (type == null)? "<Untyped>": type.getName();
            displayStatusText(param.getModule().getName()+"."+
                              param.getParameterName()+" : "+
                              typeName);
            //Iterator i = nodeWidgets.iterator();
            //while (i.hasNext())
            //    ((ChainNodeWidget) i.next()).highlightLabel(param);
            lastParameter = param;
            statusEmpty = false;
        }
    }

    public void displayNothing()
    {
        if (!statusEmpty)
        {
            displayStatusText(" ");

            //Iterator i = nodeWidgets.iterator();
            //while (i.hasNext())
            //    ((ChainNodeWidget) i.next()).unhighlightLabel(lastParameter);
            lastParameter = null;
            statusEmpty = true;
        }
    }

    public void selectAttributeType(Module.FormalParameter param, 
                                    ChainNodeWidget widget,
                                    boolean input)
    {
        AttributeType  type = param.getAttributeType();
        String         typeName = (type == null)? "<Untyped>": type.getName();
        Chain.Node     node = widget.getChainNode();

        if (lastParameter != null)
            displayNothing();

        if (lastSelectedParam == null)
        {
            Iterator i = nodeWidgets.iterator();
            if (input)
            {
                displayStatusText("Adding link ("+
                                  typeName+
                                  ") - *** to "+
                                  param.getModule().getName()+"."+
                                  param.getParameterName());
                while (i.hasNext())
                {
                    ChainNodeWidget nw = (ChainNodeWidget) i.next();
                    if (!nw.getChainNode().equals(node))
                        nw.highlightOutputsByType(type);
                }
                widget.italicLabel(param);
            } else {
                displayStatusText("Adding link ("+
                                  typeName+
                                  ") - "+
                                  param.getModule().getName()+"."+
                                  param.getParameterName()+" to ***");
                while (i.hasNext())
                {
                    ChainNodeWidget nw = (ChainNodeWidget) i.next();
                    if (!nw.getChainNode().equals(node))
                        nw.highlightInputsByType(type);
                }
                widget.italicLabel(param);
            }

            lastSelectedParam = param;
            lastNode = node;
            lastInput = input;

            statusEmpty = false;
        } else {
            if (lastInput == input)
            {
                String  msg = input? "input": "output";
                unselectAttributeType("Cannot connect an "+msg+
                                      " to another "+msg+".");
            } else if (!param.getAttributeType().
                       equals(lastSelectedParam.getAttributeType())) {
                unselectAttributeType("Mismatched types.");
            } else {
                boolean  linkedAlready = false;
                Module.FormalParameter  fromParam, toParam;
                Chain.Node  fromNode, toNode;

                if (input)
                {
                    fromParam = lastSelectedParam;
                    fromNode  = lastNode;
                    toParam   = param;
                    toNode    = node;
                } else {
                    fromParam = param;
                    fromNode  = node;
                    toParam   = lastSelectedParam;
                    toNode    = lastNode;
                }

                if (fromNode.equals(toNode))
                {
                    unselectAttributeType("Cannot link a node to itself!");
                } else {
                    Chain  chain = playgroundPane.getChain();
                    List   linksList = playgroundPane.getLinks();

                    Iterator  links = linksList.iterator();
                    while (links.hasNext())
                    {
                        Chain.Link  link = (Chain.Link) links.next();

                        // An input cannot have more than one link
                        // providing it with data.

                        if (link.getToNode().equals(toNode) &&
                            link.getToInput().equals(toParam))
                        {
                            linkedAlready = true;
                            break;
                        }
                    }

                    if (linkedAlready)
                    {
                        unselectAttributeType("Already linked!");
                    } else {
                        //chain.addLink(-1,
                        //              fromNode,
                        //              (Module.FormalOutput) fromParam,
                        //              toNode,
                        //              (Module.FormalInput) toParam);
                        playgroundPane.repaint();
                        unselectAttributeType("Link created");
                    }
                }
            }
        }
    }

    public void unselectAttributeType()
    {
        unselectAttributeType(" ");
    }

    public void unselectAttributeType(String msg)
    {
        if (lastSelectedParam != null)
        {
            displayStatusText(msg);

            Iterator i = nodeWidgets.iterator();
            while (i.hasNext())
                ((ChainNodeWidget) i.next()).unhighlightAllLabels();

            lastSelectedParam = null;
        }

        statusEmpty = true;
    }
}
