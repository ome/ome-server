/*
 * org.openmicroscopy.analysis.ui.ChainNodeWidget
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.analysis.ui;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import org.openmicroscopy.*;

public class ChainNodeWidget
    extends JPanel
{
    protected Chain.Node  node;
    protected JLabel      lblName, lblDescription, inputLabels[], outputLabels[];
    protected List        inputIDs, outputIDs;
    protected JPanel      labelPanel;
    protected Map         parameters, labels;

    protected PlaygroundController  controller;

    private class TitleMouseListener extends MouseInputAdapter
    {
        int lastX = -1, lastY = -1;
    
        public void mousePressed(MouseEvent e)
        {
            Component  c = e.getComponent();
            Component  p = c.getParent();

            lastX = p.getX()+e.getX();
            lastY = p.getY()+e.getY();
        }
    
        public void mouseDragged(MouseEvent e)
        {
            Component  c = e.getComponent();
            Component  p = c.getParent();
            int thisX = p.getX()+e.getX(), thisY = p.getY()+e.getY();
      
            p.setLocation(p.getX()+thisX-lastX,p.getY()+thisY-lastY);
            p.getParent().invalidate();

            lastX = thisX;
            lastY = thisY;
        }

        public void mouseEntered(MouseEvent e)
        {
            controller.displayMessage("Drag to move this module");
        }

        public void mouseExited(MouseEvent e)
        {
            controller.displayNothing();
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
                    controller.selectSemanticType(param,
                                                   ChainNodeWidget.this,
                                                   input);
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

    private Font   unhighlightedFont, highlightedFont, italicFont;
    private Color  unhighlightedColor, highlightedColor, italicColor;

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
        TitleMouseListener ml = new TitleMouseListener();
        lblName.addMouseListener(ml);
        lblName.addMouseMotionListener(ml);

        labelPanel = new JPanel(new GridLayout(0,2,0,0));
        labelPanel.setBorder(BorderFactory.createEmptyBorder(4,4,4,4));

        java.util.List inputs = module.getInputs();
        java.util.List outputs = module.getOutputs();

        int  numInputs = inputs.size();
        int  numOutputs = outputs.size();
        int  max = (numInputs > numOutputs)? numInputs: numOutputs;

        inputLabels = new JLabel[numInputs];
        outputLabels = new JLabel[numOutputs];
        inputIDs = new ArrayList();
        outputIDs = new ArrayList();

        Font font = lbl0.getFont();
        unhighlightedFont = font.deriveFont(Font.PLAIN);
        unhighlightedColor = Color.black;
        highlightedFont = font.deriveFont(Font.BOLD);
        highlightedColor = lbl0.getForeground();
        italicFont = font.deriveFont(Font.ITALIC);
        italicColor = Color.black;

        LabelMouseListener  inputListener = new LabelMouseListener(true);
        LabelMouseListener  outputListener = new LabelMouseListener(false);

        for (int i = 0; i < max; i++)
        {
            Module.FormalParameter  param = null;

            if (i < numInputs)
            {
                param = (Module.FormalParameter) inputs.get(i);
                lbl0 = (inputLabels[i] = new JLabel(param.getParameterName(),
                                                    SwingConstants.LEFT));
                inputIDs.add(new Integer(param.getID()));
                parameters.put(lbl0,param);
                labels.put(param,lbl0);
                lbl0.addMouseListener(inputListener);
            } else {
                lbl0 = new JLabel("");
            }

            highlightLabel(param);
            labelPanel.add(lbl0);

            if (i < numOutputs)
            {
                param = (Module.FormalParameter) outputs.get(i);
                lbl0 = (outputLabels[i] = new JLabel(param.getParameterName(),
                                                     SwingConstants.RIGHT));
                outputIDs.add(new Integer(param.getID()));
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

    public void italicLabel(JLabel lbl0)
    {
        if (lbl0 != null)
        {
            lbl0.setFont(italicFont);
            lbl0.setForeground(italicColor);
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

    public void italicLabel(Module.FormalParameter param)
    {
        italicLabel((JLabel) labels.get(param));
    }

    public void highlightInputsByType(SemanticType type)
    {
        for (int i = 0; i < inputLabels.length; i++)
        {
            Module.FormalParameter param =
                (Module.FormalParameter) parameters.get(inputLabels[i]);

            if ((param != null) && param.getSemanticType().equals(type))
                highlightLabel(inputLabels[i]);
        }
    }

    public void highlightOutputsByType(SemanticType type)
    {
        for (int i = 0; i < outputLabels.length; i++)
        {
            Module.FormalParameter param =
                (Module.FormalParameter) parameters.get(outputLabels[i]);

            if ((param != null) && param.getSemanticType().equals(type))
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

        //index = input.getModule().getInputs().indexOf(input);
        index = inputIDs.indexOf(new Integer(input.getID()));
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

        //index = output.getModule().getOutputs().indexOf(output);
        index = outputIDs.indexOf(new Integer(output.getID()));
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
