/*
 * org.openmicroscopy.analysis.ui.Test
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
import java.io.*;
//import java.net.*;
import javax.swing.*;
import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;

import org.openmicroscopy.*;
//import org.openmicroscopy.analysis.*;
import org.openmicroscopy.remote.RemoteBindings;

public class Test
    extends JFrame
{
    private static RemoteBindings bindings;

    public static void main(String[] args)
    {
        String chain;

        if (args.length < 2) 
        {
            System.err.println("Usage:  Test [XML-RPC URL] [Chain name]");
            System.exit(2);
        }

        String urlString = args[0];
        bindings = null;

        BufferedReader in =
            new BufferedReader(new InputStreamReader(System.in));

        try
        {
            System.out.print("Username? ");
            String username = in.readLine();
        
            System.out.print("Password? ");
            String password = in.readLine();

            bindings = new RemoteBindings();
            bindings.loginXMLRPC(urlString,username,password);
        } catch (Exception e) {
            System.err.println(e);
            System.exit(1);
        }

        chain = args[1];

        Test  test = new Test(chain);
        test.setVisible(true);
    }

    protected PlaygroundPane        playgroundPane;
    protected PlaygroundController  controller;
   
    protected Test(String chainName)
    {
        super("Analysis Engine");

        Container  cp = getContentPane();
        cp.setLayout(new BorderLayout());

        setSize(800,600);

        addWindowListener(new WindowAdapter()
            {
                public void windowClosing(WindowEvent e)
                {
                    bindings.logoutXMLRPC();
                    System.exit(0);
                }
            });

        JPanel p1;
        controller = new PlaygroundController();

/*
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
*/
        Factory factory = bindings.getFactory();
        Map criteria = new HashMap();
        criteria.put("name",chainName);
        Chain chain = (Chain) factory.findObject("OME::AnalysisView",criteria);
        playgroundPane = new PlaygroundPane(chain);
        int x = 50;
        Iterator i = chain.iterateNodes();
        while (i.hasNext())
        {
            playgroundPane.addNodeWidget(
                new ChainNodeWidget((Chain.Node) i.next(),controller),
                x,50);
            x += 200;
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
