/*
 * org.openmicroscopy.vis.chains.Controller
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

import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ApplicationController;
import org.openmicroscopy.util.LoginDialog;
import javax.swing.JFrame;
import javax.swing.JWindow;
import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import java.util.ArrayList;
import java.util.Iterator;
import java.awt.Image;
import java.net.URL;
import java.awt.image.ImageProducer;
import java.awt.Toolkit;
import java.awt.Font;
import java.awt.Dimension;
import java.awt.Rectangle;


/** 
 * <p>Control and top-level management for the Chain-building application.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Controller implements ApplicationController {
	
	private static final String 
		ICON_PATH="org/openmicroscopy/vis/chains/resources/chain-logo.jpg";
	private static final String SPLASH_IMAGE=
		"org/openmicroscopy/vis/chains/resources/splash.jpg";
    
    private static final String COPY_STRING =
    	"Copyright 2003, OME: MIT,NIH, University of Dundee";
	private static final int SPLASH_DELAY=5000; // 5 seconds
	
	private Font copyFont = new Font("Sans-Serif",Font.BOLD,9);
	private CmdTable cmd;
	private ModulePaletteFrame mainFrame;
	private ChainLibraryFrame library;
	
	private Image icon;
	
	ArrayList canvasFrames = new ArrayList();
	private Connection connection = null;
	private int chainCanvasCount = 0;
	
	private ChainFrame currentChainFrame;

	public Controller() {
		cmd = new CmdTable(this);
		try {
			ClassLoader cload = this.getClass().getClassLoader();
			URL url = cload.getResource(ICON_PATH);
			Toolkit toolkit = Toolkit.getDefaultToolkit();
			icon = toolkit.createImage((ImageProducer) url.getContent());
		}
		catch(Exception e) {
			icon = null;
		}
		doSplash();
	}
	
	public Image getIcon() {
		return icon;
	}

	public CmdTable getCmdTable() {
			return cmd;	
	}

	private void doSplash() {
		JWindow splash = new JWindow();
		JPanel content = (JPanel) splash.getContentPane();
		int width=0;
		int height = 0;
		JLabel label = null;
		
		content.setLayout(new BoxLayout(content,BoxLayout.Y_AXIS));
		ClassLoader cload = this.getClass().getClassLoader();
		URL url = cload.getResource(SPLASH_IMAGE);
		if (url != null) {
			ImageIcon icon = new ImageIcon(url);
			label  = new JLabel(icon);
			content.add(label);
		}
		
		JLabel info  = new JLabel(Chains.INFO);
		info.setFont(copyFont);
		JLabel copy = new JLabel(COPY_STRING);
		copy.setFont(copyFont);
		
		
		content.add(info);
		content.add(copy);
		splash.pack();
		if (url != null) {
			width += label.getWidth();
			height += label.getHeight();
		}
		else
			width +=info.getWidth();
		height += copy.getHeight()+info.getHeight();
		Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
		Rectangle bounds = splash.getBounds();
		int x = (int) (screen.getWidth()-width)/2;
		int y = (int) (screen.getHeight()-height)/2;
		splash.setBounds(x,y,width,height);
		splash.setVisible(true);
		try { Thread.sleep(SPLASH_DELAY); }catch (Exception e) { }
		splash.setVisible(false);
	}


	
	public void setMainFrame(ModulePaletteFrame mf) {
		this.mainFrame = mf;
	}
	
	public JFrame getMainFrame() {
		return mainFrame;
	}
	
	public ChainLibraryFrame getLibrary() {
			return library;
	}
	
	/**
	 * Creates the database connection via results from a LoginDialog.
	 * This database connecdtion will spawn a thread and call completeLogin(),
	 * below.<p>
	 *
	 */
	public void doLogin() {
		
		LoginDialog  loginDialog = new LoginDialog(mainFrame);
		loginDialog.show();
		if (loginDialog.isOk()) 
			connection =  new Connection(this,loginDialog.getURL(),
				loginDialog.getUserName(),loginDialog.getPassword());
	}

	public void cancelLogin() {
			connection = null;	
	}
	
	public void completeLogin(Connection connection) {
		this.connection = connection;
		mainFrame.setLoggedIn(true,connection);
		connection.layoutChains();
		System.err.println("doing library frame..");
		library = new ChainLibraryFrame(this,connection); 
	}
	
	public void doLogout() {
//		System.err.println("logout...");
		updateDatabase();
		mainFrame.setLoggedIn(false,connection);
		removeCanvasFrames();
		// remove library
		if (library !=null)
			library.dispose();
		chainCanvasCount = 0;
	}
	
	private void removeCanvasFrames() {
		Iterator iter = canvasFrames.iterator();

		ChainFrame canvasFrame;
		while (iter.hasNext()) {
			canvasFrame = (ChainFrame) iter.next();
			canvasFrame.dispose();
		}
		canvasFrames = new ArrayList();
	}
	
	public void quit() {
		System.exit(0);
	}
	
	/**
	 * A placeholder (for now) that might eventually be used to make sure that 
	 * the database is updated before the program exits.
	 *
	 */
	public void updateDatabase() {
	}
		
		
	public void newChain() {
//		System.err.println("new chain");
		ChainFrame canvasFrame = 
			new ChainFrame(this,connection,chainCanvasCount++,
				library.getCanvas());
		canvasFrames.add(canvasFrame);
	}
	
	public void disposeChainCanvas(ChainFrame c) {
		canvasFrames.remove(c);
	}
	
	public void saveChain() {
//		System.err.println("saving chain...");
		if (currentChainFrame != null) {
//			System.err.println("chain is "+currentChainFrame);
			currentChainFrame.save();
		}
	}
	
	public void setCurrentChain(ChainFrame c) {
		currentChainFrame = c;
	}
}

