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

import org.openmicroscopy.analysis.*;

public class ChainNodeWidget
  extends JPanel
{
    protected Chain.Node  node;
    protected JLabel     lblName, lblDescription, inputLabels[], outputLabels[];
    protected JPanel     labelPanel;

    private class MouseListener extends MouseInputAdapter
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

    public ChainNodeWidget(Chain.Node node)
    {
	super();

	this.node = node;

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
	font = font.deriveFont(Font.PLAIN);

	for (int i = 0; i < max; i++)
	{
	    lbl0 = (i < numInputs)?
		(inputLabels[i] = new JLabel(module.getInput(i).getParameterName(),SwingConstants.LEFT)):
		new JLabel("");
	    lbl0.setFont(font);
	    lbl0.setForeground(Color.black);
	    //lbl0.setBorder(BorderFactory.createEmptyBorder(
	    labelPanel.add(lbl0);

	    lbl0 = (i < numOutputs)?
		(outputLabels[i] = new JLabel(module.getOutput(i).getParameterName(),SwingConstants.RIGHT)):
		new JLabel("");
	    lbl0.setFont(font);
	    lbl0.setForeground(Color.black);
	    labelPanel.add(lbl0);
	}

	add(labelPanel,BorderLayout.CENTER);
  
	MouseListener ml = new MouseListener();
	addMouseListener(ml);
	addMouseMotionListener(ml);
    }

    public Chain.Node getChainNode() { return node; }

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
