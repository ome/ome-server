/*
 * org.openmicroscopy.analysis.ui.ChainNodeWidget
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
import javax.swing.*;
import javax.swing.event.*;
import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.analysis.*;

public class ChainNodeWidget
  extends JPanel
{
    protected Chain.Node  node;
    protected JLabel      lblName, lblDescription, inputLabels[], outputLabels[];
    protected JPanel      labelPanel;
    protected Map         parameters, labels;

    protected PlaygroundController  controller;

    private class DragMouseListener extends MouseInputAdapter
    {
	int lastX = -1, lastY = -1;
	boolean  good = false;
    
	public void mousePressed(MouseEvent e)
	{
	    Component  c = e.getComponent();

	    lastX = c.getX()+e.getX();
	    lastY = c.getY()+e.getY();

	    good = lblName.getBounds().contains(e.getPoint());
	}
    
	public void mouseDragged(MouseEvent e)
	{
	    Component  c = e.getComponent();
	    int thisX = c.getX()+e.getX(), thisY = c.getY()+e.getY();
      
	    if (good)
            {
		c.setLocation(c.getX()+thisX-lastX,c.getY()+thisY-lastY);
                c.getParent().invalidate();
            }
	    lastX = thisX;
	    lastY = thisY;
	}
    }

    private class LabelMouseListener extends MouseInputAdapter
    {
        private boolean  input = false;

        public LabelMouseListener(boolean input)
        {
            this.input = input;
        }

        public void mouseEntered(MouseEvent e)
        {
            Component  c = e.getComponent();

            Module.FormalParameter  param = 
                (Module.FormalParameter) parameters.get(c);

            if (param != null)
                controller.displayParameter(param);
        }

        public void mouseExited(MouseEvent e)
        {
            controller.displayNothing();
        }

        public void mouseClicked(MouseEvent e)
        {
            Component c = e.getComponent();

            Module.FormalParameter  param = 
                (Module.FormalParameter) parameters.get(c);
                    
            if (param == null)
                return;

            if ((SwingUtilities.isLeftMouseButton(e)) &&
                (!e.isControlDown()) &&
                (!e.isAltDown()) &&
                (!e.isShiftDown()) &&
                (!e.isAltGraphDown()) &&
                (!e.isMetaDown()))
            {
                if (e.getClickCount() == 1)
                {
                    controller.selectAttributeType(param,node,input);
                    e.consume();
                }
            }
        }
    }

    public ChainNodeWidget(Chain.Node node, PlaygroundController controller)
    {
	super();

	this.node = node;
        this.controller = controller;
        this.parameters = new HashMap();
        this.labels = new HashMap();

        controller.addNodeWidget(this);

        initialize();
    }

    private Font   unhighlightedFont, highlightedFont;
    private Color  unhighlightedColor, highlightedColor;

    private void initialize()
    {
	//setSize(new Dimension(60,60));
	setLayout(new BorderLayout());
	setBorder(BorderFactory.createRaisedBevelBorder());
    
	JLabel  lbl0;
	Module    module = node.getModule();

	lbl0 = new JLabel(module.getName(),SwingConstants.CENTER);
        lbl0.setBorder(BorderFactory.createEmptyBorder(0,6,0,6));
	add(lbl0,BorderLayout.NORTH);
	lblName = lbl0;

	labelPanel = new JPanel(new GridLayout(0,2));
	labelPanel.setBorder(BorderFactory.createEmptyBorder(4,4,4,4));

	int  numInputs = module.getNumInputs();
	int  numOutputs = module.getNumOutputs();
	int  max = (numInputs > numOutputs)? numInputs: numOutputs;

	inputLabels = new JLabel[numInputs];
	outputLabels = new JLabel[numOutputs];

	Font font = lbl0.getFont();
	unhighlightedFont = font.deriveFont(Font.PLAIN);
        unhighlightedColor = Color.black;
        highlightedFont = font.deriveFont(Font.BOLD);
        highlightedColor = lbl0.getForeground();

        LabelMouseListener  inputListener = new LabelMouseListener(true);
        LabelMouseListener  outputListener = new LabelMouseListener(false);

	for (int i = 0; i < max; i++)
	{
            Module.FormalParameter  param = null;

            if (i < numInputs)
            {
                param = module.getInput(i);
                lbl0 = (inputLabels[i] = new JLabel(param.getParameterName(),
                                                    SwingConstants.LEFT));
                parameters.put(lbl0,param);
                labels.put(param,lbl0);
                lbl0.addMouseListener(inputListener);
            } else {
                lbl0 = new JLabel("");
            }

            highlightLabel(param);
	    //lbl0.setBorder(BorderFactory.createEmptyBorder(
	    labelPanel.add(lbl0);

            if (i < numOutputs)
            {
                param = module.getOutput(i);
                lbl0 = (outputLabels[i] = new JLabel(param.getParameterName(),
                                                     SwingConstants.RIGHT));
                parameters.put(lbl0,param);
                labels.put(param,lbl0);
                lbl0.addMouseListener(outputListener);
            } else {
                lbl0 = new JLabel("");
            }

            highlightLabel(param);
	    labelPanel.add(lbl0);
	}

	add(labelPanel,BorderLayout.CENTER);
  
	DragMouseListener ml = new DragMouseListener();
	addMouseListener(ml);
	addMouseMotionListener(ml);
    }

    public Chain.Node getChainNode() { return node; }

    public void highlightLabel(JLabel lbl0)
    {
        if (lbl0 != null)
        {
	    lbl0.setFont(highlightedFont);
	    lbl0.setForeground(highlightedColor);
        }
    }

    public void unhighlightLabel(JLabel lbl0)
    {
        if (lbl0 != null)
        {
	    lbl0.setFont(unhighlightedFont);
	    lbl0.setForeground(unhighlightedColor);
        }
    }

    public void highlightLabel(Module.FormalParameter param)
    {
        highlightLabel((JLabel) labels.get(param));
    }

    public void unhighlightLabel(Module.FormalParameter param)
    {
        unhighlightLabel((JLabel) labels.get(param));
    }

    public void highlightInputsByType(AttributeType type)
    {
        for (int i = 0; i < inputLabels.length; i++)
        {
            Module.FormalParameter param =
                (Module.FormalParameter) parameters.get(inputLabels[i]);

            if ((param != null) && param.getAttributeType().equals(type))
                highlightLabel(inputLabels[i]);
        }
    }

    public void highlightOutputsByType(AttributeType type)
    {
        for (int i = 0; i < outputLabels.length; i++)
        {
            Module.FormalParameter param =
                (Module.FormalParameter) parameters.get(outputLabels[i]);

            if ((param != null) && param.getAttributeType().equals(type))
                highlightLabel(outputLabels[i]);
        }
    }

    public void unhighlightAllLabels()
    {
        for (int i = 0; i < inputLabels.length; i++)
            unhighlightLabel(inputLabels[i]);
        for (int i = 0; i < outputLabels.length; i++)
            unhighlightLabel(outputLabels[i]);
    }

    public Point getInputNubLocation(Module.FormalInput input)
    {
        int index;

        index = input.getModule().getInputs().indexOf(input);
        if ((index < 0) || (index >= inputLabels.length))
            throw new ArrayIndexOutOfBoundsException("getInputNubLocation");

        // this should be returned in the coordinate system of the widget's parent.
        Point  location = getLocation();
        Point  panel = labelPanel.getLocation();
        Point  label = inputLabels[index].getLocation();

        // location now points to the left edge of the widget,
        // and the top edge of the input label
        location.translate(panel.x,panel.y);
        location.translate(0,label.y);

        // location now points to the left edge of the widget,
        // and the middle of the input label
        Dimension  labelSize = inputLabels[index].getSize();
        location.translate(0,labelSize.height/2);

        // take into account the widget's border
        location.translate(-2,0);

        return location;
    }

    public Point getOutputNubLocation(Module.FormalOutput output)
    {
        int index;

        index = output.getModule().getOutputs().indexOf(output);
        if ((index < 0) || (index >= outputLabels.length))
            throw new ArrayIndexOutOfBoundsException("getOutputNubLocation");

        // this should be returned in the coordinate system of the widget's parent.
        Point  location = getLocation();
        Point  panel = labelPanel.getLocation();
        Point  label = outputLabels[index].getLocation();

        // location now points to the left edge of the widget,
        // and the top edge of the output label
        location.translate(panel.x,panel.y);
        location.translate(0,label.y);

        // location now points to the right edge of the widget,
        // and the top edge of the output label
        Dimension  size = getSize();
        location.translate(size.width,0);

        // location now points to the right edge of the widget,
        // and the middle of the output label
        Dimension  labelSize = outputLabels[index].getSize();
        location.translate(0,labelSize.height/2);

        // take into account the widget's border
        location.translate(-2,0);

        return location;
    }

}
