/*
 * org.openmicroscopy.imageviewer.ui.ImageViewerFrame
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
import java.util.Iterator;
import java.util.List;

import javax.swing.*;


/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ImageViewerFrame extends JFrame
{
  public ImageViewerFrame()
  {
    setTitle("Image Viewer");
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    Container container = getContentPane();
    container.add(new ImageViewerPanel(), "Center");
  }
}

class ImageViewerPanel extends JPanel
{
  public ImageViewerPanel()
  {
    setLayout(new BorderLayout(5,5));
    
    JPanel northPanel = new JPanel();
    northPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
    northPanel.add(new StatusLabel("Waiting for login..."));
    
    add(northPanel,BorderLayout.NORTH);
    
    JPanel eastPanel = new JPanel();
    eastPanel.setLayout(new GridLayout(2,1));
    eastPanel.add(new OMELoginPanel());
    eastPanel.add(new ImageListPanel());
    add(eastPanel,BorderLayout.EAST);
    
    JPanel wholeImagePanel = new JPanel();
    wholeImagePanel.setLayout(new BorderLayout(2,2));
    ImagePanel imagePanel = new ImagePanel();
    wholeImagePanel.add(new JScrollPane(imagePanel),BorderLayout.CENTER);
    
    ImageControlPanel controlPanel = new ImageControlPanel();
    wholeImagePanel.add(controlPanel,BorderLayout.SOUTH);
    add(wholeImagePanel,BorderLayout.CENTER);
    
  }
}
  
class StatusLabel extends JLabel
                  implements MessageWidget
{
  private Font messageFont = new Font(null,Font.PLAIN,12);
  private Font errorFont = new Font(null,Font.BOLD,12);
  private ImageController controller;
  
  private void init()
  {
    controller = ImageController.getInstance();
    controller.setStatusWidget(this);
  }
  
  public StatusLabel()
  {
    super();
    init();
  }
  
  public StatusLabel(String message)
  {
    super(message);
    init();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.MessageWidget#displayError(java.lang.String)
   */
  public void displayError(String error)
  {
    setFont(errorFont);
    setText(error);
    revalidate();
    repaint();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.MessageWidget#displayMessage(java.lang.String)
   */
  public void displayMessage(String message)
  {
    setFont(messageFont);
    setText(message);
    revalidate();
    repaint();
  }
  
  public void doUpdate()
  {
    revalidate();
    repaint();
  }
}

class OMELoginPanel extends JPanel
                    implements OMELoginWidget
{
  private final JTextField urlField = new JTextField(12);
  private final JTextField nameField = new JTextField(12);
  private final JPasswordField passField = new JPasswordField(12);
  private ImageController controller;
  
  private void init()
  {
    Font font = new Font(null,Font.PLAIN,10);
    controller = ImageController.getInstance();
    controller.setLoginWidget(this);
    
    JPanel fieldPanel = new JPanel();
    JPanel logPanel = new JPanel();
    
    setLayout(new BorderLayout(2,2));

    setLayout(new BoxLayout(this,BoxLayout.Y_AXIS));

    JLabel urlLabel = new JLabel("Remote URL:");
    urlLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
    urlField.setMaximumSize(new Dimension(300,25));

    JLabel nameLabel = new JLabel("Username:");
    nameLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
    nameField.setMaximumSize(new Dimension(200,25));

    JLabel passLabel = new JLabel("Password:");
    passLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
    passField.setMaximumSize(new Dimension(200,25));

    logPanel.setLayout(new FlowLayout(FlowLayout.CENTER));

    JButton loginButton = new JButton("Login");
    loginButton.setAction(controller.LOGIN_ACTION);

    JButton logoutButton = new JButton("Logout");
    logoutButton.setAction(controller.LOGOUT_ACTION);
    
    logPanel.add(loginButton);
    logPanel.add(Box.createHorizontalStrut(10));
    logPanel.add(logoutButton);
    
    fieldPanel.setLayout(new BoxLayout(fieldPanel,BoxLayout.Y_AXIS));
    
    fieldPanel.add(urlLabel);
    fieldPanel.add(urlField);
    fieldPanel.add(Box.createVerticalStrut(8));
    fieldPanel.add(nameLabel);
    fieldPanel.add(nameField);
    fieldPanel.add(Box.createVerticalStrut(8));
    fieldPanel.add(passLabel);
    fieldPanel.add(passField);
    
    add(fieldPanel,BorderLayout.CENTER);
    add(logPanel,BorderLayout.SOUTH);
  }
  
  public OMELoginPanel()
  {
    init();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMELoginWidget#getRemoteURL()
   */
  public String getRemoteURL()
  {
    return urlField.getText();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMELoginWidget#getUsername()
   */
  public String getUsername()
  {
    return nameField.getText();
  }

  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMELoginWidget#getPassword()
   */
  public String getPassword()
  {
    return new String(passField.getPassword());
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.UIWidget#doUpdate()
   */
  public void doUpdate()
  {
    revalidate();
    repaint();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.OMELoginWidget#resetInfo()
   */
  public void resetInfo()
  {
    urlField.setText("");
    nameField.setText("");
    passField.setText("");
  }
}

class ImageListPanel extends JPanel
                     implements ListWidget
{
  private JList list;
  private DefaultListModel listModel;
  private ImageController controller;
  
  private void init()
  {
    controller = ImageController.getInstance();
    controller.setImageListWidget(this);
    
    listModel = new DefaultListModel();
    list = new JList(listModel);
    listModel.addElement("No images loaded");
    list.setBorder(BorderFactory.createTitledBorder("Image List"));
    list.setEnabled(false);
    
    setLayout(new BorderLayout(2,2));
    
    JPanel buttonPanel = new JPanel();
    JButton loadButton = new JButton("Load All");
    
    loadButton.setAction(controller.LOAD_IMAGE_ACTION);
    
    JButton selectButton = new JButton("Select");
    selectButton.setAction(controller.DISPLAY_IMAGE_ACTION);
    buttonPanel.add(loadButton);
    buttonPanel.add(Box.createHorizontalStrut(10));
    buttonPanel.add(selectButton);
    
    add(list,BorderLayout.CENTER);
    add(buttonPanel,BorderLayout.SOUTH);
  }
  
  public ImageListPanel()
  {
    init();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#addEntry(java.lang.Object)
   */
  public void addEntry(Object object)
  {
    if(!list.isEnabled())
    {
      listModel.clear();
      list.setEnabled(true);
    }
    listModel.addElement(object);
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#displayList(java.util.List)
   */
  public void displayList(List list)
  {
    listModel.clear();
    this.list.setEnabled(true);
    for(Iterator iter = list.iterator(); iter.hasNext();)
    {
      listModel.addElement(iter.next());
    }
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#clearEntries()
   */
  public void clearEntries()
  {
    listModel.clear();
    listModel.addElement("No images");
    list.setEnabled(false);
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#removeEntry(java.lang.Object)
   */
  public void removeEntry(Object object)
  {
    listModel.removeElement(object);
    if(listModel.size() == 0)
    {
      listModel.addElement("No images");
      list.setEnabled(false);
    }
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#getSelectedIndex()
   */
  public int getSelectedIndex()
  {
    return list.getSelectedIndex();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ListWidget#getSelectedObject()
   */
  public Object getSelectedObject()
  {
    return list.getSelectedValue();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.UIWidget#doUpdate()
   */
  public void doUpdate()
  {
    revalidate();
    repaint();
  }
}