/*
 * org.openmicroscopy.analysis.ui.Test
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

import org.openmicroscopy.*;
import org.openmicroscopy.analysis.*;

public class Test
    extends JFrame
{
    public static void main(String[] args)
    {
        String chain;

        chain = (args.length > 0)? args[0]: "IMAGE_IMPORT";

        Test  test = new Test(chain);
        test.setVisible(true);
    }

    protected PlaygroundPane        playgroundPane;
    protected PlaygroundController  controller;
   
    protected Test(String chain)
    {
        super("Analysis Engine");

        Container  cp = getContentPane();
        cp.setLayout(new BorderLayout());

        setSize(800,600);

        addWindowListener(new WindowAdapter()
            {
                public void windowClosing(WindowEvent e)
                {
                    System.exit(0);
                }
            });

        JPanel p1;
        controller = new PlaygroundController();

        if (chain.equalsIgnoreCase("IMAGE_IMPORT"))
        {
            playgroundPane = new PlaygroundPane(TestInstances.imageImportChain);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.imageImport_stackStats,
                                    controller),
                50,150);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.imageImport_planeStats,
                                    controller),
                50,350);
        } else if (chain.equalsIgnoreCase("FIND_SPOTS")) {
            playgroundPane = new PlaygroundPane(TestInstances.findSpotsChain);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.findSpots_stackStats,
                                    controller),
                50,150);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.findSpots_findSpots,
                                    controller),
                350,150);
        } else if (chain.equalsIgnoreCase("TEST_SPOTS")) {
            playgroundPane = new PlaygroundPane(TestInstances.testFindSpotsChain);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.testFindSpots_stackStats,
                                    controller),
                50,150);
            playgroundPane.addNodeWidget(
                new ChainNodeWidget(TestInstances.testFindSpots_findSpots,
                                    controller),
                350,150);
        }

        controller.setPlaygroundPane(playgroundPane);

        p1 = new JPanel(new BorderLayout());
        p1.setBorder(BorderFactory.createLoweredBevelBorder());
        cp.add(p1,BorderLayout.CENTER);
        p1.add(playgroundPane,BorderLayout.CENTER);

        JLabel  lbl0;
        lbl0 = new JLabel(" ",SwingConstants.CENTER);
        p1.add(lbl0,BorderLayout.SOUTH);
        controller.setStatusLabel(lbl0);

        p1 = new JPanel(new BorderLayout());
        p1.setBorder(BorderFactory.createEmptyBorder(2,2,2,2));
        cp.add(p1,BorderLayout.WEST);

        JTree tree = new JTree(new ModuleTreeModel());
        tree.setBorder(BorderFactory.createLoweredBevelBorder());
        p1.add(tree,BorderLayout.CENTER);
    }
}
