/*
 * org.openmicroscopy.alligator.MainFrame
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




package org.openmicroscopy.alligator;

import java.awt.*;
import java.awt.event.*;
//import java.awt.geom.AffineTransform;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.*;

public class MainFrame
    extends JFrame
{
    private Controller controller;

    // From JBuilder
    BorderLayout borderLayout1 = new BorderLayout();
    JPanel jPanel1 = new JPanel();
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    JScrollPane jScrollPane1 = new JScrollPane();
    JTable jLocalTypesTable = new JTable();
    JScrollPane jScrollPane2 = new JScrollPane();
    JScrollPane jScrollPane3 = new JScrollPane();
    JScrollPane jScrollPane4 = new JScrollPane();
    JTable jRemoteTypesTable = new JTable();
    //JTree jLocalModuesTree = new JTree();
    JTree jRemoteModulesTree = new JTree();
    //JLabel jLocalLabel = new JLabel();
    JLabel jRemoteLabel = new JLabel();
    JLabel jTypesLabel = new JLabel();
    JLabel jModulesLabel = new JLabel();
    JPanel jPanel2 = new JPanel();
    GridBagLayout gridBagLayout2 = new GridBagLayout();
    JLabel jConnectedLabel = new JLabel();
    JProgressBar jRemoteProgressBar = new JProgressBar();
    Border border1;

    public MainFrame(Controller controller)
    {
        super("OME Alligator");

        this.controller = controller;
        controller.setMainFrame(this);

        setDefaultCloseOperation(WindowConstants.DO_NOTHING_ON_CLOSE);
        setResizable(true);
        try
        {
            jbInit();
            initUI();
            initMenubar();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void jbInit() throws Exception
    {
        border1 = BorderFactory.createEmptyBorder(8,8,8,8);
        this.getContentPane().setLayout(borderLayout1);
        jPanel1.setLayout(gridBagLayout1);
        /*jLocalLabel.setToolTipText("");
        jLocalLabel.setHorizontalAlignment(SwingConstants.CENTER);
        jLocalLabel.setText("Local"); */
        jRemoteLabel.setHorizontalAlignment(SwingConstants.CENTER);
        jRemoteLabel.setText("Remote");
        jTypesLabel.setText("Types");
        jModulesLabel.setText("Modules");
        //jScrollPane1.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        jScrollPane1.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        jScrollPane2.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        jScrollPane2.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        jScrollPane3.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        jScrollPane3.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        jScrollPane4.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        jScrollPane4.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        jPanel2.setLayout(gridBagLayout2);
        jConnectedLabel.setText("Not connected to an OME server.");
        jPanel1.setBorder(border1);
        this.getContentPane().add(jPanel1, BorderLayout.CENTER);
      //  jPanel1.add(jScrollPane1,        new GridBagConstraints(1, 1, 1, 1, 1.0, 1.0
        //                                                        ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 2, 2), 0, 0));
        jScrollPane1.getViewport().add(jLocalTypesTable, null);
        jPanel1.add(jScrollPane2,      new GridBagConstraints(2, 1, 1, 1, 1.0, 1.0
                                                              ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 2, 4), 0, 0));
        jScrollPane2.getViewport().add(jRemoteTypesTable, null);
        //jPanel1.add(jScrollPane3,       new GridBagConstraints(1, 2, 1, 1, 1.0, 1.0
               //                                                ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 4, 2), 0, 0));
        jPanel1.add(jScrollPane4,       new GridBagConstraints(2, 2, 1, 1, 1.0, 1.0
                                                               ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 4, 4), 0, 0));
       // jScrollPane3.getViewport().add(jLocalModuesTree, null);
        jScrollPane4.getViewport().add(jRemoteModulesTree, null);
        //jPanel1.add(jLocalLabel,    new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0
          //                                                 ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel1.add(jRemoteLabel,    new GridBagConstraints(2, 0, 1, 1, 0.0, 0.0
                                                            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel1.add(jTypesLabel,   new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                          ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(2, 4, 2, 6), 0, 0));
        jPanel1.add(jModulesLabel,   new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                            ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(2, 4, 4, 6), 0, 0));
        jPanel1.add(jPanel2,      new GridBagConstraints(1, 3, 2, 1, 0.0, 0.0
                                                         ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(6, 4, 4, 4), 0, 0));
        jPanel2.add(jConnectedLabel,     new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0
                                                                ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 4, 0), 0, 0));
        jPanel2.add(jRemoteProgressBar,  new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                                ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
    }

    protected void initUI()
    {
        addWindowListener(new WindowAdapter()
            {
                public void windowClosing(WindowEvent e)
                {
                    controller.QUIT_ACTION.actionPerformed(null);
                }
            });

        jLocalTypesTable.setModel(controller.localTypesTableModel);
        jRemoteTypesTable.setModel(controller.remoteTypesTableModel);
        jRemoteModulesTree.setRootVisible(false);
        jRemoteModulesTree.setModel(controller.remoteModulesTreeModel);

        jRemoteTypesTable.addMouseListener(new MouseAdapter()
            {
                public void mouseClicked(MouseEvent e)
                {
                    // Only listen for a double left click

                    if (SwingUtilities.isLeftMouseButton(e) &&
                        (e.getClickCount() == 2))
                    {
                        int index = jRemoteTypesTable.getSelectedRow();
                        if (index == -1) return;
                        SemanticType type = controller.remoteTypesTableModel.
                            getSemanticType(index);

                        controller.displaySemanticType(type,false);
                    }
                }
            });

        jLocalTypesTable.addMouseListener(new MouseAdapter()
            {
                public void mouseClicked(MouseEvent e)
                {
                    // Only listen for a double left click

                    if (SwingUtilities.isLeftMouseButton(e) &&
                        (e.getClickCount() == 2))
                    {
                        int index = jLocalTypesTable.getSelectedRow();
                        if (index == -1) return;
                        // We don't have the table model yet
                        SemanticType type = controller.localTypesTableModel.
                            getSemanticType(index);

                        controller.displaySemanticType(type,true);
                    }
                }
            });

        jRemoteProgressBar.setEnabled(false);
    }

    protected JMenuItem makeMenuItem(Controller.AlligatorAction a)
    {
        JMenuItem  item;
        item = new JMenuItem();
        item.setAction(a);
        item.setAccelerator(a.getAccelerator());
        return item;
    }

    protected void initMenubar()
    {
        JMenuBar   menubar;
        JMenu      menu;
        JMenuItem  item;

        menubar = new JMenuBar();

        menubar.add(menu = new JMenu("File"));
        menu.add(item = makeMenuItem(controller.LOGIN_ACTION));
        menu.add(item = makeMenuItem(controller.LOGOUT_ACTION));
        menu.addSeparator();
        menu.add(item = makeMenuItem(controller.QUIT_ACTION));

        setJMenuBar(menubar);
    }
}
