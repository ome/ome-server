/*
 * org.openmicroscopy.alligator.SemanticTypeFrame
 *
 * Copyright (C) 2002-2003 Open Microscopy Environment, MIT
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

package org.openmicroscopy.alligator;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.Border;
import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class SemanticTypeFrame
    extends ViewEditFrame
{
    private SemanticType type;
    private Controller controller;
    private boolean canEdit;

    BorderLayout borderLayout1 = new BorderLayout();
    JPanel jPanel1 = new JPanel();
    BorderLayout borderLayout2 = new BorderLayout();
    JTable jvElementsTable = new JTable();
    JLabel jLabel2 = new JLabel();
    GridBagLayout gridBagLayout3 = new GridBagLayout();
    CardLayout cardLayout1 = new CardLayout();
    JScrollPane jScrollPane1 = new JScrollPane();
    JTextArea jvDescriptionArea = new JTextArea();
    JLabel jLabel1 = new JLabel();
    JLabel jvGranularityLabel = new JLabel();
    JPanel jViewPanel = new JPanel();
    JLabel jvTypeNameLabel = new JLabel();
    JPanel jPanel3 = new JPanel();
    JPanel jPanel2 = new JPanel();
    FlowLayout flowLayout1 = new FlowLayout();
    JButton jEditButton = new JButton();
    JPanel jEditPanel = new JPanel();
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    JTextField jeTypeNameField = new JTextField();
    JLabel jLabel3 = new JLabel();
    JComboBox jeGranularityCombo = new JComboBox();
    JLabel jLabel4 = new JLabel();
    JTextArea jeDescriptionArea = new JTextArea();
    JPanel jPanel4 = new JPanel();
    BorderLayout borderLayout3 = new BorderLayout();
    JPanel jPanel5 = new JPanel();
    JButton jeAddElementButton = new JButton();
    JScrollPane jScrollPane2 = new JScrollPane();
    JButton jeRemoveElementButton = new JButton();
    Border border1;
    FlowLayout flowLayout2 = new FlowLayout();
    JTable jeElementsTable = new JTable();
    JPanel jPanel6 = new JPanel();
    JButton jeRevertButton = new JButton();
    FlowLayout flowLayout3 = new FlowLayout();
    JButton jeApplyButton = new JButton();

    public SemanticTypeFrame(Controller controller, SemanticType type,
                             boolean canEdit)
    {
        super("Semantic Type");
        this.type = type;
        this.controller = controller;
        this.canEdit = canEdit;
        try
        {
            jbInit();
            initUI();
            refreshUI();
            pack();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void jbInit() throws Exception
    {
        border1 = BorderFactory.createCompoundBorder(BorderFactory.createEtchedBorder(Color.white,new Color(140, 140, 140)),BorderFactory.createEmptyBorder(4,4,4,4));
        jPanel1.setBorder(BorderFactory.createEmptyBorder(8,8,8,8));
        jPanel3.setLayout(cardLayout1);
        jvTypeNameLabel.setHorizontalAlignment(SwingConstants.CENTER);
        jvTypeNameLabel.setText("SemanticTypeName");
        jViewPanel.setLayout(gridBagLayout3);
        jViewPanel.setMaximumSize(new Dimension(2147483647, 2147483647));
        jvGranularityLabel.setText("Dataset");
        jLabel1.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel1.setText("Granularity");
        jvDescriptionArea.setEnabled(true);
        jvDescriptionArea.setBorder(null);
        jvDescriptionArea.setMaximumSize(new Dimension(300, 2147483647));
        jvDescriptionArea.setOpaque(false);
        jvDescriptionArea.setEditable(false);
        jvDescriptionArea.setText("Description");
        jvDescriptionArea.setColumns(25);
        jvDescriptionArea.setLineWrap(true);
        jvDescriptionArea.setRows(3);
        jvDescriptionArea.setWrapStyleWord(true);
        jScrollPane1.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
        jLabel2.setText("Description");
        jLabel2.setHorizontalAlignment(SwingConstants.TRAILING);
        jPanel1.setLayout(borderLayout2);
        this.getContentPane().setLayout(borderLayout1);
        jPanel2.setLayout(flowLayout1);
        jEditButton.setActionCommand("Edit");
        jEditButton.setText("Edit");
        jEditPanel.setLayout(gridBagLayout1);
        jeTypeNameField.setPreferredSize(new Dimension(76, 21));
        jeTypeNameField.setText("Type Name");
        jeTypeNameField.setHorizontalAlignment(SwingConstants.CENTER);
        jLabel3.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel3.setText("Granularity");
        jLabel4.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel4.setText("Description");
        jeDescriptionArea.setText("Description");
        jeDescriptionArea.setColumns(25);
        jeDescriptionArea.setLineWrap(true);
        jeDescriptionArea.setRows(3);
        jeDescriptionArea.setWrapStyleWord(true);
        jPanel4.setLayout(borderLayout3);
        jPanel5.setLayout(flowLayout2);
        jeAddElementButton.setActionCommand("AddElement");
        jeAddElementButton.setText("Add");
        jeRemoveElementButton.setDoubleBuffered(false);
        jeRemoveElementButton.setActionCommand("RemoveElement");
        jeRemoveElementButton.setText("Remove");
        jPanel4.setBorder(border1);
        jeRevertButton.setActionCommand("Revert");
        jeRevertButton.setText("Revert");
        jPanel6.setLayout(flowLayout3);
        jeApplyButton.setText("Apply");
        jPanel6.add(jeApplyButton, null);
        this.getContentPane().add(jPanel1,  BorderLayout.CENTER);
        jPanel1.add(jPanel3,  BorderLayout.CENTER);
        jPanel3.add(jViewPanel,  "View");
        jViewPanel.add(jvTypeNameLabel,    new GridBagConstraints(0, 0, 2, 1, 0.0, 0.0
                                                                  ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(0, 4, 4, 4), 0, 0));
        jViewPanel.add(jLabel1,   new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                         ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(4, 4, 2, 6), 0, 0));
        jViewPanel.add(jvGranularityLabel,   new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0
                                                                    ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(4, 2, 2, 4), 0, 0));
        jViewPanel.add(jLabel2,   new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                         ,GridBagConstraints.NORTH, GridBagConstraints.HORIZONTAL, new Insets(2, 4, 4, 6), 0, 0));
        jViewPanel.add(jvDescriptionArea,     new GridBagConstraints(1, 2, 1, 1, 1.0, 0.0
                                                                     ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 4, 4), 0, 0));
        jViewPanel.add(jScrollPane1,   new GridBagConstraints(0, 3, 2, 1, 1.0, 2.0
                                                              ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(4, 4, 4, 4), 0, 0));
        jScrollPane1.getViewport().add(jvElementsTable, null);
        jViewPanel.add(jPanel2,    new GridBagConstraints(0, 4, 2, 1, 0.0, 0.0
                                                          ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 4, 4, 4), 0, 0));
        jPanel2.add(jEditButton, null);
        jPanel3.add(jEditPanel,   "Edit");
        jEditPanel.add(jeTypeNameField,      new GridBagConstraints(0, 0, 4, 1, 0.0, 0.0
                                                                    ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(0, 4, 4, 4), 0, 0));
        jEditPanel.add(jLabel3,      new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                            ,GridBagConstraints.CENTER, GridBagConstraints.HORIZONTAL, new Insets(4, 4, 2, 6), 0, 0));
        jEditPanel.add(jeGranularityCombo,     new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0
                                                                      ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 2, 2, 4), 0, 0));
        jEditPanel.add(jLabel4,    new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                          ,GridBagConstraints.NORTH, GridBagConstraints.HORIZONTAL, new Insets(2, 4, 4, 6), 0, 0));
        jEditPanel.add(jeDescriptionArea,    new GridBagConstraints(1, 2, 1, 1, 1.0, 0.0
                                                                    ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(2, 2, 4, 4), 0, 0));
        jEditPanel.add(jPanel4,    new GridBagConstraints(0, 3, 2, 1, 1.0, 2.0
                                                          ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(4, 4, 4, 4), 0, 0));
        jPanel4.add(jPanel5,  BorderLayout.SOUTH);
        jPanel5.add(jeAddElementButton, null);
        jPanel5.add(jeRemoveElementButton, null);
        jPanel4.add(jScrollPane2, BorderLayout.CENTER);
        jScrollPane2.getViewport().add(jeElementsTable, null);
        jEditPanel.add(jPanel6,  new GridBagConstraints(0, 4, 2, 1, 0.0, 0.0
                                                        ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 4, 4, 4), 0, 0));
        jPanel6.add(jeRevertButton, null);
    }

    protected void initUI()
    {
        jvDescriptionArea.setOpaque(false);
        jvElementsTable.setModel(controller.getElementTableModel(type));
        if (!canEdit)
        {
            // If this semantic type is uneditable (ie, remote),
            // then don't even display the edit button.
            jViewPanel.remove(jPanel2);
        } else {
            jeElementsTable.setModel(jvElementsTable.getModel());
            jeGranularityCombo.
                setModel(new DefaultComboBoxModel(Granularity.LABELS));
        }

        jEditButton.addActionListener(this);
        jeApplyButton.addActionListener(this);
        jeRevertButton.addActionListener(this);
    }

    public void refreshUI()
    {
        if (type == null)
        {
            setTitle("Semantic Type");
            jvTypeNameLabel.setText("");
            jvGranularityLabel.setText("");
            jvDescriptionArea.setText("");
            //controller.updateElementTableModel(type).updateList(null);
        } else {
            view();
        }
    }

    public void view()
    {
        cardLayout1.show(jPanel3,"View");
        setTitle(type.getName());
        jvTypeNameLabel.setText(type.getName());
        jvGranularityLabel.setText(Granularity.LABELS[type.getGranularity()]);
        jvDescriptionArea.setText(type.getDescription());
        controller.getElementTableModel(type).update(type);
    }

    public void edit()
    {
        cardLayout1.show(jPanel3,"Edit");
        jeTypeNameField.setText(type.getName());
        jeGranularityCombo.setSelectedIndex(type.getGranularity());
        jeDescriptionArea.setText(type.getDescription());
    }

    public void apply()
    {
        type.setName(jeTypeNameField.getText());
        type.setGranularity(jeGranularityCombo.getSelectedIndex());
        type.setDescription(jeDescriptionArea.getText());
    }

}
