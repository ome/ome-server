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
import org.openmicroscopy.util.LoginResponder;
import javax.swing.JFrame;
import javax.swing.JWindow;
import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import java.util.ArrayList;
import java.util.Iterator;
import java.awt.Component;
import java.awt.Image;
import java.net.URL;
import java.awt.image.ImageProducer;
import java.awt.Toolkit;
import java.awt.Font;
import java.awt.Dimension;
import java.awt.Rectangle;
import javax.swing.Box;


/** 
 * <p>Control and top-level management for the Chain-building application.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class Controller  implements LoginResponder {
	
	private static final String 
		ICON_PATH="org/openmicroscopy/vis/chains/resources/chain-logo.jpg";
	private static final String SPLASH_IMAGE=
		"org/openmicroscopy/vis/chains/resources/splash.jpg";
    
    private static final String COPY_STRING =
    	"Copyright 2003, OME: MIT,NIH, University of Dundee";
	private static final int SPLASH_DELAY=5000; // 5 seconds
	
	private Font copyFont = new Font("Sans-Serif",Font.BOLD,9);
	private CmdTable cmd;
	private ModulePaletteFrame moduleFrame;
	private ChainLibraryFrame library;
	
	private Image icon;
	
	ArrayList canvasFrames = new ArrayList();
	private Connection connection = null;
	private ChainFrame currentChainFrame;
	
	private ArrayList resultFrames = new ArrayList();
	
	private JWindow status;
	private JLabel statusLabel;
	
	private ChainLogin loginDialog;
	
	private ControlPanel controlPanel;
	
	private ResultFrame currentResultFrame;
	
	private int initThreads = 0;
	
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
		doLogin();
	}
	
	/**
	 * 
	 * @return the icon associated with the application
	 */
	public Image getIcon() {
		return icon;
	}

	/**
	 * 
	 * @return The application's command hash
	 */
	public CmdTable getCmdTable() {
			return cmd;	
	}

	/**
	 * Place a splash window on the screen and leave it there for a bit
	 *
	 */
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
		
		JLabel info  = new JLabel(org.openmicroscopy.vis.chains.Chains.INFO);
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

	/**
	 * Update the contents of the status label in the status window
	 * @param s new text of the status label
	 */
	public void setStatusLabel(String s) {
		if (statusLabel != null)
			statusLabel.setText(s);
	}
	
	public void closeStatusWindow() {
		if (status != null) {
			status.setVisible(false);
			status.dispose();
		}
		status = null;
		statusLabel =null;
	}
	
	/**
	 * Return a pointer to the {@link ModulePaletteFrame}
	 */
	public JFrame getMainFrame() {
		return moduleFrame;
	}
	
	
	/**
	 * Show the login window
	 *
	 */
	public void doLogin() {
		
		loginDialog = new ChainLogin(this);
		loginDialog.show();
	}
	
	/** 
	 * Callback from {@link LoginResponder}. 
	 * Creates the database connection via results from a {@link ChainLogin}.
	 * This database connection will spawn a thread and call 
	 * {@link completeLogin()},below.<p>
	 */
	public void loginOK() {
		connection =  new Connection(this,loginDialog.getURL(),
			loginDialog.getUserName(),loginDialog.getPassword());
		loginDialog.hide();
		buildStatusWindow();
	}
	
	/**
	 * The program will exit if the user chooses not to login
	 */
	public void loginCancel() {
		quit();
	}

	/**
	 * Populate the window used to indicate the status of initializing the 
	 * various components of the tool
	 *
	 */
	private void buildStatusWindow() {
		status = new JWindow();
		JPanel content = (JPanel) status.getContentPane();
		content.setLayout(new BoxLayout(content,BoxLayout.X_AXIS));
		content.add(Box.createRigidArea(new Dimension(5,0)));
		
		JPanel panel = new JPanel();
		panel.setLayout(new BoxLayout(panel,BoxLayout.Y_AXIS));
		content.add(panel);
		
		panel.add(Box.createRigidArea(new Dimension(0,5)));		
		JLabel title = new JLabel("Loading...");
		title.setAlignmentX(Component.LEFT_ALIGNMENT);
		panel.add(title);
		statusLabel = new JLabel("OME Database Contents ");
		statusLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
		statusLabel.setPreferredSize(new Dimension(350,20));
		panel.add(statusLabel);
		Component box = Box.createRigidArea(new Dimension(0,5));
		panel.add(box);
		status.pack();
		Dimension screen = Toolkit.getDefaultToolkit().getScreenSize();
		Rectangle bounds = status.getBounds();
		int x = (int) (screen.getWidth()-bounds.getWidth())/2;
		int y = (int) (screen.getHeight()-bounds.getHeight())/2;
		status.setBounds(x,y,(int)bounds.getWidth(),(int)bounds.getHeight());
		status.setVisible(true);	
	}
	
	/**
	 * Cancel a login and return to the login screen
	 *
	 */
	public void cancelLogin() {
			connection = null;
			if (library != null) { 
				library.dispose();
				library = null;
			}
			if (controlPanel != null) {
				controlPanel.dispose();
				controlPanel = null;
			}
			if (moduleFrame != null) {
				moduleFrame.dispose();
				moduleFrame = null;
			}
				
			removeFrames();
			closeStatusWindow();
			doLogin();	
	}
	
	/**
	 * After the basic login has completed and the database connection has 
	 * been made, populate a {@link ModulePaletteFrame} and a 
	 * {@link ChainLibraryFrame}
	 */
	public void completeWindows() {
		
		//1 thread
		initThreads++;
		connection.initDatasets(this);
		controlPanel  = new ControlPanel(this,connection);
		controlPanel.setLoggedIn(connection.getUserName());
		controlPanel.setEnabled(true);
		// 2 threads
		initThreads++;
		moduleFrame = new ModulePaletteFrame(this,connection);
		// 3 threads
		initThreads++;
		connection.layoutChains();

		
	}
	
	public void buildLibraryFrame() {
		library = new ChainLibraryFrame(this,connection);
		System.err.println("finishing chain library frame");
		finishInitThread();
	}
	

	public synchronized void finishInitThread() {
		initThreads--;
		System.err.println("setting # of active threads to "+initThreads);
		if (initThreads == 0)
			closeStatusWindow();
	}
	/**
	 * Logout of the system - remove all active windows and 
	 * present the login dialog.
	 *
	 */	
	public void doLogout() {

		cancelLogin();
		/*moduleFrame.dispose();
		controlPanel.dispose();
		removeFrames();
		// remove library
		if (library !=null) {
			library.dispose();
			
		}
		doLogin(); */
	}
	
	/**
	 * Remove all active {@link ChainFrame} instances 
	 *
	 */
	private void removeFrames() {
		Iterator iter = canvasFrames.iterator();

		ChainFrame canvasFrame;
		while (iter.hasNext()) {
			canvasFrame = (ChainFrame) iter.next();
			canvasFrame.dispose();
		}
		canvasFrames.clear();
		
		iter = resultFrames.iterator();

		ResultFrame resultFrame;
		while (iter.hasNext()) {
			resultFrame = (ResultFrame) iter.next();
			resultFrame.dispose();
		}
		resultFrames.clear();

	}
	
	/**
	 * Exit the program.
	 *
	 */
	public void quit() {
		System.exit(0);
	}
	
		
		
	public void newChain() {
		if (library != null) {
			ChainFrame canvasFrame = 
				new ChainFrame(this,connection,canvasFrames.size(),
					library.getCanvas());
			canvasFrames.add(canvasFrame);
		}
		
	}
	
	public void newViewResults() {
		if (library != null) {
			ResultFrame res = 
				new ResultFrame(this,connection,resultFrames.size(),
								library.getCanvas());
			resultFrames.add(res);
		}
	}
	
	/**
	 * Remove a specific chain canvas/frame
	 * @param c the frame to be removed
	 */
	public void disposeChainCanvas(ChainFrame c) {
		canvasFrames.remove(c);
	}
	
	public void disposeResultFrame(ResultFrame f) {
		resultFrames.remove(f);
	}
	

	
	public void saveChain() {
		if (currentChainFrame != null) {
			currentChainFrame.save();
		}
	}
	
	public void setCurrentChain(ChainFrame c) {
		currentChainFrame = c;
	}
	
	public void setCurrentResults(ResultFrame r) {
		currentResultFrame = r;
	}
	
	public ControlPanel getControlPanel() {
		return controlPanel;
	}
}

