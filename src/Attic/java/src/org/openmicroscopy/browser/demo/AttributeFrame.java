/*
 * org.openmicroscopy.browser.demo.AttributeFrame
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
package org.openmicroscopy.browser.demo;

import java.awt.BorderLayout;
import java.awt.Font;
import java.util.Vector;

import javax.swing.Box;
import javax.swing.DefaultCellEditor;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableColumn;
import javax.swing.table.TableColumnModel;

import org.openmicroscopy.browser.datamodel.DataElementType;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class AttributeFrame extends JFrame
{
  public AttributeFrame()
  {
    super("Attribute Editor");
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    this.getContentPane().setLayout(new BorderLayout());
    
    Vector typeList = new Vector();
    typeList.add(DataElementType.INT);
    typeList.add(DataElementType.LONG);
    typeList.add(DataElementType.FLOAT);
    typeList.add(DataElementType.DOUBLE);
    typeList.add(DataElementType.STRING);
    typeList.add(DataElementType.BOOLEAN);
    typeList.add(DataElementType.OBJECT);
    typeList.add(DataElementType.ATTRIBUTE);
    
    JComboBox comboBox = new JComboBox(typeList);
    
    JPanel panel = new JPanel();
    panel.setLayout(new BorderLayout());
    panel.add(Box.createHorizontalStrut(8),BorderLayout.WEST);
    panel.add(Box.createVerticalStrut(5),BorderLayout.NORTH);
    panel.add(Box.createVerticalStrut(5),BorderLayout.SOUTH);
    JLabel label = new JLabel("Modify the attributes for this dataset:");
    label.setFont(new Font(label.getFont().getFontName(),
                           Font.BOLD,
                           label.getFont().getSize()));
    panel.add(label,BorderLayout.CENTER);
    
    getContentPane().add(panel,BorderLayout.NORTH);
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.WEST);
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.EAST);
    getContentPane().add(Box.createVerticalStrut(10),BorderLayout.SOUTH);
    
    Object[][] data = {
                        {"phenotype", DataElementType.STRING},
                        {"stack-max", DataElementType.DOUBLE},
                        {"stack-min", DataElementType.DOUBLE},
                        {"wavelength-nm", DataElementType.INT},
                        {"notes", DataElementType.STRING},
                        {"slide-number", DataElementType.INT}
                      };
                      
    DemoDataModel dataModel =
      new DemoDataModel(data, new Object[] {"Name", "Type"});
      
                      
    JTable t = new JTable(dataModel);
    JScrollPane sp = new JScrollPane(t);
    
    TableColumnModel model = t.getColumnModel();
    TableColumn col = model.getColumn(1);
    col.setCellEditor(new DefaultCellEditor(comboBox));
    
    this.getContentPane().add(sp,BorderLayout.CENTER);
                      
  }
  
  class DemoDataModel extends DefaultTableModel
  {
    public DemoDataModel(Object[][] obj, Object[] names)
    {
      super(obj,names);
      // be stupid here
    }
  }
}
