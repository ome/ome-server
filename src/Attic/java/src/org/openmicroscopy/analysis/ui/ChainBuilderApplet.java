/*
 * org.openmicroscopy.analysis.ui.ChainBuilderApplet
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
import org.openmicroscopy.simple.*;
import org.openmicroscopy.applet.*;

public class ChainBuilderApplet
    extends JApplet
{
    protected PlaygroundPane        playgroundPane;
    protected PlaygroundController  controller;

    protected Chain  chain;
    protected ChainNodeWidget  widgets[];

    public void init()
    {
        Container  cp = getContentPane();
        cp.setLayout(new BorderLayout());

        JPanel p1;
//         String chain = getParameter("chain");

//         if (chain.equalsIgnoreCase("IMAGE_IMPORT"))
//         {
//             playgroundPane = new PlaygroundPane(TestInstances.imageImportChain);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.imageImport_stackStats,
//                                     controller),
//                 50,150);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.imageImport_planeStats,
//                                     controller),
//                 50,350);
//         } else if (chain.equalsIgnoreCase("FIND_SPOTS")) {
//             playgroundPane = new PlaygroundPane(TestInstances.findSpotsChain);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.findSpots_stackStats,
//                                     controller),
//                 50,150);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.findSpots_findSpots,
//                                     controller),
//                 350,150);
//         } else if (chain.equalsIgnoreCase("TEST_SPOTS")) {
//             playgroundPane = new PlaygroundPane(TestInstances.testFindSpotsChain);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.testFindSpots_stackStats,
//                                     controller),
//                 50,150);
//             playgroundPane.addNodeWidget(
//                 new ChainNodeWidget(TestInstances.testFindSpots_findSpots,
//                                     controller),
//                 350,150);
//         }

//        controller.setPlaygroundPane(playgroundPane);

        loadParameters();

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

    protected void loadParameters()
    {
        AppletParameters  ap = new AppletParameters(this);

        int numDataTables = ap.getIntParameter("DataTables",false);
        for (int i = 0; i < numDataTables; i++)
            new AppletDataTable(ap,"DataTable"+i);

        int numAttributeTypes = ap.getIntParameter("AttributeTypes",false);
        for (int i = 0; i < numAttributeTypes; i++)
            new AppletAttributeType(ap,"AttributeType"+i);

        int numModules = ap.getIntParameter("Modules",false);
        for (int i = 0; i < numModules; i++)
            new AppletModule(ap,"Module"+i);

        String chainName = ap.getStringParameter("Chain",false);

        chain = new AppletChain(ap,chainName);
        controller = new PlaygroundController();
        playgroundPane = new PlaygroundPane(chain);
        widgets = new ChainNodeWidget[chain.getNumNodes()];
        for (int i = 0; i < widgets.length; i++)
        {
            int x = ap.getIntParameter(chainName+"/Node"+i+"/X",false);
            int y = ap.getIntParameter(chainName+"/Node"+i+"/Y",false);
            widgets[i] = new ChainNodeWidget(chain.getNode(i),controller);
            playgroundPane.addNodeWidget(widgets[i],x,y);
        }

        controller.setPlaygroundPane(playgroundPane);
    }
}
