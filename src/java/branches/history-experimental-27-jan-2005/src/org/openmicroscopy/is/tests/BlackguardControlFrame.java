/*
 * org.openmicroscopy.is.tests.BlackguardControlFrame
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




package org.openmicroscopy.is.tests;

import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;

public class BlackguardControlFrame
    extends JFrame
{
    private static final String[] LEVEL_BASES =
    {"Absolute","Relative to mean","Relative to geomean"};

    private Blackguard  blackguard;

    public BlackguardControlFrame(Blackguard blackguard)
    {
        super("Blackguard");
        this.blackguard = blackguard;

        setDefaultCloseOperation(EXIT_ON_CLOSE);
        jbInit();

        jButton1.setActionCommand("update");
        jButton1.addActionListener(blackguard);
        getRootPane().setDefaultButton(jButton1);

        jButton2.setActionCommand("quit");
        jButton2.addActionListener(blackguard);
    }

    // FROM JBUILDER
    JPanel jPanel1 = new JPanel();
    Border border1;
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    JLabel jLabel1 = new JLabel();
    JTextField tfPixelsID = new JTextField();
    Border border2;
    JPanel jPanel2 = new JPanel();
    GridLayout gridLayout1 = new GridLayout();
    JButton jButton1 = new JButton();
    JButton jButton2 = new JButton();
    Border border4;
    JTabbedPane jTabbedPane1 = new JTabbedPane();
    JPanel jPanel3 = new JPanel();
    JPanel jPanel4 = new JPanel();
    GridBagLayout gridBagLayout2 = new GridBagLayout();
    JLabel jLabel2 = new JLabel();
    JTextField tfGrayChannel = new JTextField();
    JLabel jLabel3 = new JLabel();
    JTextField tfGrayBlackLevel = new JTextField();
    JLabel jLabel4 = new JLabel();
    JTextField tfGrayWhiteLevel = new JTextField();
    GridBagLayout gridBagLayout3 = new GridBagLayout();
    JLabel jLabel5 = new JLabel();
    JTextField tfRedChannel = new JTextField();
    JLabel jLabel6 = new JLabel();
    JTextField tfRedBlackLevel = new JTextField();
    JLabel jLabel7 = new JLabel();
    JTextField tfRedWhiteLevel = new JTextField();
    JCheckBox cbRedOn = new JCheckBox();
    JCheckBox cbGreenOn = new JCheckBox();
    JLabel jLabel8 = new JLabel();
    JTextField tfGreenChannel = new JTextField();
    JLabel jLabel9 = new JLabel();
    JTextField tfGreenBlackLevel = new JTextField();
    JLabel jLabel10 = new JLabel();
    JTextField tfGreenWhiteLevel = new JTextField();
    JCheckBox cbBlueOn = new JCheckBox();
    JLabel jLabel11 = new JLabel();
    JTextField tfBlueChannel = new JTextField();
    JLabel jLabel12 = new JLabel();
    JTextField tfBlueBlackLevel = new JTextField();
    JLabel jLabel13 = new JLabel();
    JTextField tfBlueWhiteLevel = new JTextField();
    JPanel jPanel5 = new JPanel();
    FlowLayout flowLayout1 = new FlowLayout();
    JPanel jPanel6 = new JPanel();
    FlowLayout flowLayout2 = new FlowLayout();
    JLabel jLabel14 = new JLabel();
    JPanel jPanel7 = new JPanel();
    JComboBox cbLevelBasis = new JComboBox(LEVEL_BASES);

    private void jbInit()
    {
        border1 = BorderFactory.createEmptyBorder(2,2,2,2);
        border2 = BorderFactory.createEmptyBorder(2,2,2,2);
        border4 = BorderFactory.createEmptyBorder(4,4,4,4);
        jPanel1.setLayout(gridBagLayout1);
        jLabel1.setBorder(border2);
        jLabel1.setText("Pixels ID");
        tfPixelsID.setText("1");
        tfPixelsID.setColumns(5);
        tfPixelsID.setHorizontalAlignment(SwingConstants.TRAILING);
        jPanel2.setLayout(gridLayout1);
        gridLayout1.setColumns(1);
        gridLayout1.setRows(0);
        gridLayout1.setVgap(4);
        jButton1.setText("Update");
        jButton2.setText("Quit");
        jPanel2.setBorder(border4);
        jPanel3.setLayout(gridBagLayout2);
        jLabel2.setText("Channel");
        tfGrayChannel.setText("0");
        tfGrayChannel.setColumns(5);
        tfGrayChannel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel3.setText("Black level");
        tfGrayBlackLevel.setText("0");
        tfGrayBlackLevel.setColumns(5);
        tfGrayBlackLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel4.setText("White level");
        tfGrayWhiteLevel.setSelectionStart(1);
        tfGrayWhiteLevel.setText("1000");
        tfGrayWhiteLevel.setColumns(5);
        tfGrayWhiteLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jPanel4.setLayout(gridBagLayout3);
        jLabel5.setText("Channel");
        tfRedChannel.setText("0");
        tfRedChannel.setColumns(5);
        tfRedChannel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel6.setText("Black level");
        tfRedBlackLevel.setText("0");
        tfRedBlackLevel.setColumns(5);
        tfRedBlackLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel7.setText("White level");
        tfRedWhiteLevel.setText("1000");
        tfRedWhiteLevel.setColumns(5);
        tfRedWhiteLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        cbRedOn.setText("Red");
        cbGreenOn.setText("Green");
        jLabel8.setText("Channel");
        tfGreenChannel.setSelectionEnd(11);
        tfGreenChannel.setText("0");
        tfGreenChannel.setColumns(5);
        tfGreenChannel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel9.setText("Black level");
        tfGreenBlackLevel.setSelectionEnd(11);
        tfGreenBlackLevel.setText("0");
        tfGreenBlackLevel.setColumns(5);
        tfGreenBlackLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel10.setText("White level");
        tfGreenWhiteLevel.setSelectionEnd(11);
        tfGreenWhiteLevel.setText("1000");
        tfGreenWhiteLevel.setColumns(5);
        tfGreenWhiteLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        cbBlueOn.setText("Blue");
        jLabel11.setText("Channel");
        tfBlueChannel.setSelectionEnd(11);
        tfBlueChannel.setText("0");
        tfBlueChannel.setColumns(5);
        tfBlueChannel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel12.setText("Black level");
        tfBlueBlackLevel.setSelectionEnd(11);
        tfBlueBlackLevel.setText("0");
        tfBlueBlackLevel.setColumns(5);
        tfBlueBlackLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jLabel13.setText("White level");
        tfBlueWhiteLevel.setSelectionEnd(11);
        tfBlueWhiteLevel.setText("1000");
        tfBlueWhiteLevel.setColumns(5);
        tfBlueWhiteLevel.setHorizontalAlignment(SwingConstants.TRAILING);
        jPanel5.setLayout(flowLayout1);
        jPanel6.setLayout(flowLayout2);
        jLabel14.setText("Level basis");
        cbLevelBasis.setActionCommand("levelBasis");
        this.getContentPane().add(jPanel1, BorderLayout.CENTER);
        jPanel1.add(jPanel2,       new GridBagConstraints(1, 0, 1, 3, 0.0, 0.0
                                                          ,GridBagConstraints.NORTH, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
        jPanel2.add(jButton1, null);
        jPanel2.add(jButton2, null);
        jPanel1.add(jTabbedPane1,            new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                                    ,GridBagConstraints.CENTER, GridBagConstraints.BOTH, new Insets(0, 4, 4, 4), 0, 0));
        jTabbedPane1.add(jPanel3,    "Grayscale");
        jPanel3.add(jLabel2,   new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0
                                                      ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 2), 0, 0));
        jPanel3.add(tfGrayChannel,    new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0
                                                           ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel3.add(jLabel3,  new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                     ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 2), 0, 0));
        jPanel3.add(tfGrayBlackLevel,  new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0
                                                         ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel3.add(jLabel4,  new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                     ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 2), 0, 0));
        jPanel3.add(tfGrayWhiteLevel,  new GridBagConstraints(1, 2, 1, 1, 0.0, 0.0
                                                         ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel3.add(jPanel7,  new GridBagConstraints(0, 3, 2, 1, 0.0, 1.0
                                                     ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
        jTabbedPane1.add(jPanel4,   "RGB");
        jPanel4.add(jLabel5,          new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                             ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(tfRedChannel,         new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0
                                                                 ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel6,          new GridBagConstraints(0, 2, 1, 1, 0.0, 0.0
                                                             ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(tfRedBlackLevel,        new GridBagConstraints(1, 2, 1, 1, 0.0, 0.0
                                                                   ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel7,         new GridBagConstraints(0, 3, 1, 1, 0.0, 0.0
                                                            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel4.add(tfRedWhiteLevel,        new GridBagConstraints(1, 3, 1, 1, 0.0, 0.0
                                                                   ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel4.add(cbRedOn,      new GridBagConstraints(0, 0, 2, 1, 0.0, 0.0
                                                         ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(4, 4, 0, 4), 0, 0));
        jPanel4.add(cbGreenOn,    new GridBagConstraints(0, 4, 2, 1, 0.0, 0.0
                                                         ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(8, 4, 0, 4), 0, 0));
        jPanel4.add(jLabel8,   new GridBagConstraints(0, 5, 1, 1, 0.0, 0.0
                                                      ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(tfGreenChannel,   new GridBagConstraints(1, 5, 1, 1, 0.0, 0.0
                                                             ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel9,   new GridBagConstraints(0, 6, 1, 1, 0.0, 0.0
                                                      ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(tfGreenBlackLevel,   new GridBagConstraints(1, 6, 1, 1, 0.0, 0.0
                                                                ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel10,   new GridBagConstraints(0, 7, 1, 1, 0.0, 0.0
                                                       ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel4.add(tfGreenWhiteLevel,   new GridBagConstraints(1, 7, 1, 1, 0.0, 0.0
                                                                ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel4.add(cbBlueOn,   new GridBagConstraints(0, 8, 2, 1, 0.0, 0.0
                                                       ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(8, 4, 0, 4), 0, 0));
        jPanel4.add(jLabel11,   new GridBagConstraints(0, 9, 1, 1, 0.0, 0.0
                                                       ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(tfBlueChannel,   new GridBagConstraints(1, 9, 1, 1, 0.0, 0.0
                                                            ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(4, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel12,   new GridBagConstraints(0, 10, 1, 1, 0.0, 0.0
                                                       ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(tfBlueBlackLevel,   new GridBagConstraints(1, 10, 1, 1, 0.0, 0.0
                                                               ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 2, 4), 0, 0));
        jPanel4.add(jLabel13,   new GridBagConstraints(0, 11, 1, 1, 0.0, 0.0
                                                       ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel4.add(tfBlueWhiteLevel,   new GridBagConstraints(1, 11, 1, 1, 0.0, 0.0
                                                               ,GridBagConstraints.WEST, GridBagConstraints.NONE, new Insets(2, 4, 4, 4), 0, 0));
        jPanel1.add(jPanel5,   new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0
                                                      ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
        jPanel5.add(jLabel1, null);
        jPanel5.add(tfPixelsID, null);
        jPanel1.add(jPanel6,  new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0
                                                     ,GridBagConstraints.CENTER, GridBagConstraints.NONE, new Insets(0, 0, 0, 0), 0, 0));
        jPanel6.add(jLabel14, null);
        jPanel6.add(cbLevelBasis, null);
    }

}
