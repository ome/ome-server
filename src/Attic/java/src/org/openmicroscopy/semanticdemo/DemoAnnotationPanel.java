/*
 * org.openmicroscopy.semanticdemo.DemoAnnotationPanel
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
package org.openmicroscopy.semanticdemo;

import java.awt.*;

import javax.swing.*;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;

import java.util.*;
import java.util.List;

/**
 * Danger, danger: not MVC.  Danger, danger.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class DemoAnnotationPanel extends JPanel
                                 implements AnnotationReceiver
{
  private DefaultListModel typesListModel;
  private JList typesListWidget;
  private JTextArea annotationArea;
  private Map annotationMap;
  
  public DemoAnnotationPanel()
  {
    annotationMap = new HashMap();
    initView();
    initController(); 
  }
  
  private void initView()
  {
    typesListModel = new DefaultListModel();
    typesListWidget = new JList(typesListModel);
    typesListWidget.setPreferredSize(new Dimension(150,150));
    annotationArea = new JTextArea(5,40);
    setLayout(new BorderLayout(2,2));
    add(annotationArea,BorderLayout.CENTER);
    add(typesListWidget,BorderLayout.WEST);
  }
  
  private void initController()
  {
    typesListWidget.addListSelectionListener(new ListSelectionListener()
    {
      // replace all text w/selected element values
      public void valueChanged(ListSelectionEvent e)
      {
        annotationArea.setText("");
        int[] selectedIndices = typesListWidget.getSelectedIndices();
        StringBuffer annotationBuffer = new StringBuffer();
    
        for(int i=0;i<selectedIndices.length;i++)
        {
          String annotation =
            (String)annotationMap.get(typesListModel.get(i));
          annotationBuffer.append(annotation);
          annotationBuffer.append("\n");
        }
      }
    });
  }
  
  public void setAnnotations(Map typesMap)
  {
    if(typesMap == null)
    {
      typesListModel.clear();
      return;
    }
    typesListModel.clear();
    List keySet = new ArrayList(typesMap.keySet());
    Collections.sort(keySet);
    
    for(Iterator iter = keySet.iterator(); iter.hasNext();)
    {
      Object key = iter.next();
      typesListModel.addElement(key);
      annotationMap.put(key,typesMap.get(key));
    }
  }
}
