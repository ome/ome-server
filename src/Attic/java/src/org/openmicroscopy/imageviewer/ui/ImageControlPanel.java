/*
 * org.openmicroscopy.imageviewer.ImageControlPanel
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
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.imageviewer.ui;

import java.awt.*;
import javax.swing.*;
import java.awt.event.*;

import javax.swing.event.*;

import org.openmicroscopy.imageviewer.data.ImageInformation;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $ Revision: $ $ Date: $
 */
public class ImageControlPanel extends JPanel
                               implements OMEImageFilterWidget
{
  private ImageController controller;
  private JSlider zBox;
  private JSlider tBox;
  private JComboBox redChannels;
  private JComboBox greenChannels;
  private JComboBox blueChannels;
  private JCheckBox redOn;
  private JCheckBox greenOn;
  private JCheckBox blueOn;
  
  private BoundedRangeModel zModel;
  private BoundedRangeModel tModel;
  private DefaultComboBoxModel redChannelModel;
  private DefaultComboBoxModel greenChannelModel;
  private DefaultComboBoxModel blueChannelModel;
  
  private boolean internalChange = false;
  
  private final Font defaultFont = new Font(null,Font.PLAIN,10);
  
  public ImageControlPanel()
  {
    this.controller = ImageController.getInstance();
    controller.setImageFilterWidget(this);
    setLayout(new FlowLayout());
    zModel = new DefaultBoundedRangeModel(0,0,0,0);
    tModel = new DefaultBoundedRangeModel(0,0,0,0);
    redChannelModel = new DefaultComboBoxModel();
    greenChannelModel = new DefaultComboBoxModel();
    blueChannelModel = new DefaultComboBoxModel();
    
    JLabel zLabel = new JLabel("Z:");
    zBox = new JSlider(zModel);
    zBox.setPreferredSize(new Dimension(100,30));
    zBox.setFont(defaultFont);
    
    JLabel tLabel = new JLabel("T:");
    tBox = new JSlider(tModel);
    tBox.setPreferredSize(new Dimension(100,30));
    tBox.setFont(defaultFont);
    
    redChannelModel.addElement("--");
    greenChannelModel.addElement("--");
    blueChannelModel.addElement("--");
    redChannels = new JComboBox(redChannelModel);
    greenChannels = new JComboBox(greenChannelModel);
    blueChannels = new JComboBox(blueChannelModel);
    
    redOn = new JCheckBox("Red");
    redOn.setForeground(Color.red);
    greenOn = new JCheckBox("Green");
    greenOn.setForeground(Color.green);
    blueOn = new JCheckBox("Blue");
    blueOn.setForeground(Color.blue);
    
    zModel.addChangeListener(new ChangeListener()
    {
      public void stateChanged(ChangeEvent arg0)
      {
        if(internalChange)
          controller.UPDATE_FILTER_ACTION.actionPerformed(null);
      }
    });

    tModel.addChangeListener(new ChangeListener()
    {
      public void stateChanged(ChangeEvent arg0)
      {
        if(internalChange)
          controller.UPDATE_FILTER_ACTION.actionPerformed(null);
      }
    });
    

    redChannels.addItemListener(new ItemListener()
    {
      public void itemStateChanged(ItemEvent arg0)
      {
        if(internalChange && arg0.getStateChange() == ItemEvent.SELECTED)
          controller.UPDATE_FILTER_ACTION.actionPerformed(null);
      }
    });

    greenChannels.addItemListener(new ItemListener()
    {
      public void itemStateChanged(ItemEvent arg0)
      {
        if(internalChange && arg0.getStateChange() == ItemEvent.SELECTED)
          controller.UPDATE_FILTER_ACTION.actionPerformed(null);
      }
    });

    blueChannels.addItemListener(new ItemListener()
    {
      public void itemStateChanged(ItemEvent arg0)
      {
        if(internalChange && arg0.getStateChange() == ItemEvent.SELECTED)
          controller.UPDATE_FILTER_ACTION.actionPerformed(null);
      }
    });

    redOn.setAction(controller.UPDATE_FILTER_ACTION);
    greenOn.setAction(controller.UPDATE_FILTER_ACTION);
    blueOn.setAction(controller.UPDATE_FILTER_ACTION);
    
    redOn.setText("Red");
    greenOn.setText("Green");
    blueOn.setText("Blue");
    
    add(zLabel);
    add(zBox);
    add(Box.createHorizontalStrut(10));
    add(tLabel);
    add(tBox);
    add(redOn);
    add(redChannels);
    add(Box.createHorizontalStrut(10));
    add(greenOn);
    add(greenChannels);
    add(Box.createHorizontalStrut(10));
    add(blueOn);
    add(blueChannels);
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getCurrentZ()
   */
  public int getCurrentZ()
  {
    return zModel.getValue();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getCurrentT()
   */
  public int getCurrentT()
  {
    return tModel.getValue();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getRedOn()
   */
  public boolean getRedOn()
  {
    return redOn.isSelected();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getRedChannel()
   */
  public int getRedChannel()
  {
    return ((Integer)redChannelModel.getSelectedItem()).intValue();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getGreenOn()
   */
  public boolean getGreenOn()
  {
    return greenOn.isSelected();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getGreenChannel()
   */
  public int getGreenChannel()
  {
    return ((Integer)greenChannelModel.getSelectedItem()).intValue();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getBlueOn()
   */
  public boolean getBlueOn()
  {
    return blueOn.isSelected();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#getBlueChannel()
   */
  public int getBlueChannel()
  {
    return ((Integer)blueChannelModel.getSelectedItem()).intValue();
  }

  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMEImageFilterWidget#updatePossibleValues(org.openmicroscopy.imageviewer.ImageInformation)
   */
  public void updatePossibleValues(ImageInformation info)
  {
    if(info == null)
    {
      return;
    }
    internalChange = false;
    zModel.setMinimum(0);
    zModel.setMaximum(info.getDimZ()-1);
    if(zModel.getMinimum() == zModel.getMaximum())
    {
      zModel.setExtent(0);
    }
    else
    {
      zModel.setExtent(1);
    }
    
    tModel.setMinimum(0);
    tModel.setMaximum(info.getDimT()-1);
    if(tModel.getMinimum() == tModel.getMaximum())
    {
      tModel.setExtent(0);
    }
    else
    {
      tModel.setExtent(1);
    }
    
    redChannelModel.removeAllElements();
    greenChannelModel.removeAllElements();
    blueChannelModel.removeAllElements();
    for(int i=0;i<info.getDimC();i++)
    {
      redChannelModel.addElement(new Integer(i));
      greenChannelModel.addElement(new Integer(i));
      blueChannelModel.addElement(new Integer(i));
    }
    revalidate();
    repaint();
    internalChange = true;
  }
  
  public void loadDefaults(int z, int t, int redChannel,
                           int greenChannel, int blueChannel,
                           boolean redOn,boolean greenOn,boolean blueOn)
  {
    internalChange = false;
    this.redOn.setSelected(redOn);
    this.greenOn.setSelected(greenOn);
    this.blueOn.setSelected(blueOn);
    this.redChannelModel.setSelectedItem(new Integer(redChannel));
    this.greenChannelModel.setSelectedItem(new Integer(greenChannel));
    this.blueChannelModel.setSelectedItem(new Integer(blueChannel));
    this.zModel.setValue(z);
    this.tModel.setValue(t);
    zBox.revalidate();
    tBox.revalidate();
    revalidate();
    repaint();
    internalChange = true;
  }


}
