/*
 * org.openmicroscopy.vis.chains.ModulePaletteFrame
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.piccolo.PPaletteCanvas;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CModule;
import edu.umd.cs.piccolo.PCanvas;
import java.awt.BorderLayout;
import java.awt.Rectangle;
import java.awt.Dimension;
import javax.swing.JSplitPane;
import javax.swing.JScrollPane;
import javax.swing.JTree;
import javax.swing.tree.TreeSelectionModel;
import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;
import javax.swing.tree.TreePath;



 /* <p>The {@link ChainFrameBase} instance that holds the palette of modules.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ModulePaletteFrame extends ChainFrameBase implements 
	TreeSelectionListener {

	
	
	private MenuBar menuBar;
	//private ToolBar toolBar;
	
	public static int X=10;
	public static int Y=100;
	public static int HEIGHT=400;
	public static int WIDTH=400;
	
	private JSplitPane splitPane;
	
	private JTree tree; 
	
	/** 
	 * A flag to prevent re-entrant UI event calls on the JTRee
	 */
	private boolean lockTreeChange = false;

	
	public ModulePaletteFrame(Controller controller,Connection connection) {
	
		// next line needed if chain frame base
		super(controller,connection,"OME Chains Palette");
		setIconImage(controller.getIcon()); 
		getCanvas().setConfig(connection,controller);
		layoutFrame();
		menuBar.setLoginsDisabled(true);
	//	toolBar.setLoggedIn(connection.getUserName());
		show();	
		getCanvas().scaleToSize();
	}
	
	/**
	 * @return the {@link Controller} associated with the window
	 * not needed if parent is chainframe base
	 */
	public Controller getController() {
		return controller;
	}
	public Rectangle getInitialBounds() {
		return new Rectangle(X,Y,WIDTH,HEIGHT);
	}
	
	/**
	 * The canvas for this frame is an instance of {@link PPaletteCanvas}
	 * @return a PPaletteCanvas
	 */
	public PCanvas createCanvas(Connection connection) {
		return new PPaletteCanvas(this);
	}

	public PPaletteCanvas getCanvas() {
		return (PPaletteCanvas) canvas;
	}
	
	/**
	 * Build a menu bar based on  a {@link CmdTable}
	 * @param cmd hash associating tags with actions
	 */
	private void buildMenuBar(CmdTable cmd) {
		menuBar = new MenuBar(cmd);
		setJMenuBar(menuBar);
	}

	/**
	 * This frame has a toolbar along with the canvas
	 */
	protected void layoutFrame() {
		//contentPane.setLayout(new BoxLayout(contentPane,BoxLayout.Y_AXIS));
		contentPane.setLayout(new BorderLayout());
		CmdTable cmd = controller.getCmdTable();
		buildMenuBar(cmd);
		
		//toolBar = new ToolBar(cmd);
		//contentPane.add(toolBar,BorderLayout.NORTH);
		
		 
		tree = new JTree(getCanvas().getModuleTreeNode());
		tree.setRootVisible(false);
		tree.setEditable(false);
		tree.setExpandsSelectedPaths(true);
		tree.getSelectionModel().
			setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);
		tree.addTreeSelectionListener(this);
		JScrollPane treePanel = new JScrollPane(tree);
		
		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT,
						true,treePanel,canvas);
		treePanel.setMinimumSize(new Dimension(100,HEIGHT));
		treePanel.setPreferredSize(new Dimension(100,HEIGHT));
		
		canvas.setMinimumSize(new Dimension(WIDTH,HEIGHT));
		canvas.setPreferredSize(new Dimension(WIDTH,HEIGHT));
		splitPane.setPreferredSize(new Dimension(WIDTH+100,HEIGHT)); 
		splitPane.setDividerLocation(0);
		splitPane.setOneTouchExpandable(true);
		splitPane.setResizeWeight(0.25);
		contentPane.add(splitPane,BorderLayout.CENTER);
		pack();
	}
	
	public void setNewChainEnabled(boolean v) {
		//if (toolBar != null)
		//	toolBar.setNewChainEnabled(v);
	}
	
	/**
	 * A Listener for the {@JTree} of module names and categories
	 */
	public void valueChanged(TreeSelectionEvent e) {
		
		// If this change is occurring because a
		if (lockTreeChange == true)
			return;
			
		ModuleTreeNode node = 
			(ModuleTreeNode) tree.getLastSelectedPathComponent();
		if (node == null) 
			return;
		if (node.isLeaf()) { // it's a module
			getCanvas().highlightModule((CModule)node.getObject());
		}
		else 
			getCanvas().unhighlightModules();
	}
	
	public void clearTreeSelection() {
		int rowCount = tree.getRowCount();
		tree.clearSelection();
	}
	
	public void setTreeSelection(CModule mod) {
		int rowCount = tree.getRowCount();
		for (int i =0; i < rowCount; i++) {
			TreePath path = tree.getPathForRow(i);
			Object obj = path.getLastPathComponent();
			if (obj instanceof ModuleTreeNode) {
				ModuleTreeNode modNode = (ModuleTreeNode) obj;
				//if (modNode.isLeaf() && modNode.getID() == mod.getID())  {
				if (modNode.getObject() == mod) {
					// We don't want the valueChanged call to get executed here.
					lockTreeChange= true;
					tree.setSelectionPath(path);
					lockTreeChange = false;
					return;
				}
			}
		}
		tree.clearSelection();
	}
	
}
	