/*
 * org.openmicroscopy.client.ClientContents
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
 * Written by:    Brian S. Hughes <bshughes@mit.edu>
 *
 *------------------------------------------------------------------------------
 */



package org.openmicroscopy.client;

//import java.awt.*;
import java.lang.Integer;
import java.awt.geom.*;
import java.awt.Container;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Toolkit;
import java.awt.Canvas;
import java.awt.MediaTracker;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.font.*;
import java.awt.event.*;
import java.awt.event.*;
import java.awt.GridBagConstraints;
import java.util.List;
import java.util.Iterator;
import java.util.HashMap;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.filechooser.*;
import javax.swing.LookAndFeel;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.imageviewer.ui.*;
import org.openmicroscopy.vis.ome.*;
import org.openmicroscopy.vis.chains.*;
import org.openmicroscopy.vis.piccolo.*;
import org.openmicroscopy.*;



/**
 *  Sets up main workstation window, and maintains much of the top level
 * context for the workstation.
 *
 * @author  Brian S. Hughes
 * @version 2.0
 * @since   2.0.3
 */
public class ClientContents extends JFrame {
    boolean projectSet = false;
    boolean datasetSet = false;
    boolean imageSet   = false;
    boolean chainSet   = false;
    String         userName;
    String         groupName;
    StringBuffer   projectName = new StringBuffer();
    StringBuffer   datasetName = new StringBuffer();
    StringBuffer   imageName = new StringBuffer();
    StringBuffer   chainName = new StringBuffer();
    ProjectViewer  prV;
    DatasetViewer  dsV;
    ImageViewer    imV;
    ChainViewer    chV;
    ImageController imC;
    ZoomImagePanel     pixPanel;
    //JScrollPane    holdsImage;
    JPanel         holdsImage = new JPanel();
    JPanel         workstationPanel;
    JSplitPane     Viewers;
    JSplitPane     mainContents;
    ClientMenu     menu;
    ClientLogin    ourLogin;
    ClientStatusBar statusBar;
    ClientTabs     tabPanel;
    ClientViewPane viewPane;
    DataAccess     Accessor;
    Cursor waitcur =
	java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.WAIT_CURSOR);
    Cursor defcur =
	java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.DEFAULT_CURSOR);
    private static String motifClassName = "com.sun.java.swing.plaf.motif.MotifLookAndFeel";


    /**
     *  Instantiate the main workstation window for the current login.
     * Build the main menu bar, status bar, tab panel, and detail info
     * viewer panel. Add our mascot's picture as the main icon.
     *
     * @param clientPanel JPanel in which to build window
     * @param login       current login yields the link to the remote server
     */

    public ClientContents (JPanel clientPanel, ClientLogin login) {

        workstationPanel = clientPanel;
	ourLogin = login;
	Accessor = ourLogin.getAccessor();
	userName = new String(ourLogin.getExperimenter());
	groupName = new String(ourLogin.getGroup());
	imC = ImageController.getInstance(Accessor.bindings);
	pixPanel = new ZoomImagePanel();
	//holdsImage = new JScrollPane(pixPanel);
	holdsImage = new JPanel();
	holdsImage.setPreferredSize(new Dimension(200,200));
	//holdsImage.add(pixPanel);

	try {
	    UIManager.setLookAndFeel(motifClassName);
	} catch (Exception exc) {
	    System.err.println("Error loading L&F: " + exc);
	}

        statusBar = new ClientStatusBar(this);
        tabPanel  = new ClientTabs(this, Accessor);
        viewPane  = new ClientViewPane(this, Accessor);

        // Add menu bar to client's window
        menu = new ClientMenu(this, ourLogin, statusBar);
        GridBagConstraints mainConstrain = new GridBagConstraints();
        mainConstrain.gridx = 0;
        mainConstrain.gridy = 0;
        mainConstrain.gridwidth = 1;
        mainConstrain.gridheight = 2;
        mainConstrain.anchor = GridBagConstraints.NORTHWEST;
        mainConstrain.fill = GridBagConstraints.BOTH;
        mainConstrain.weightx = 1;
        mainConstrain.weighty = 0;

	// Put up our favorite image on corner of window
	java.awt.Image decalIcon  = null;
	//Class c = ClientContents.class;
	ClassLoader cload = this.getClass().getClassLoader();
	try {
	    java.net.URL u = cload.getResource("org/openmicroscopy/client/AnimalCellicon.gif");
	    decalIcon = Toolkit.getDefaultToolkit().getImage(u);
	} catch(Exception e){
	    System.err.println("Failed to load icon: "+e);
	}
	if (decalIcon != null) {
	    MediaTracker mt = new MediaTracker(this);
	    mt.addImage(decalIcon, 1);
	    try {
		mt.waitForAll();
	    } catch(Exception e) {
		System.err.println(e);
		System.exit(1);
	    }
	    mainConstrain.weightx = 0;
	    workstationPanel.add(new DecalPanel(decalIcon), mainConstrain);
	}

	//mainConstrain.ipadx = 60;
        mainConstrain.weightx = 1;
	mainConstrain.gridheight = 1;
	mainConstrain.gridx=1;
        //mainConstrain.gridwidth = GridBagConstraints.REMAINDER;
        mainConstrain.gridwidth = 4;
        workstationPanel.add(menu.getOMEMenuBar(), mainConstrain);

        // Add status bar
        mainConstrain.gridy = 1;
        mainConstrain.fill = GridBagConstraints.BOTH;
        workstationPanel.add(statusBar, mainConstrain);

        mainConstrain.fill = GridBagConstraints.HORIZONTAL;
	mainConstrain.ipadx = 0;

	// make an info/image split pane that will hold the details of an
	// entity and picture, if an image, or chain diagram, if a chain.
	Dimension pdim = new Dimension(100,100);
	holdsImage.setPreferredSize(pdim);
	Viewers = new JSplitPane(JSplitPane.VERTICAL_SPLIT, viewPane, holdsImage);
	Viewers.setOneTouchExpandable(true);
	Viewers.setResizeWeight(0.4);

	// Make a split pane that will hold the tab panel on the left,
	// and the info/image pane on the right.
	mainContents = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT,
				      tabPanel, Viewers);
	Rectangle r = tabPanel.getBounds(null);

	mainContents.setOneTouchExpandable(true);
	mainContents.setResizeWeight(0.2);

        mainConstrain.gridx = 0;
        mainConstrain.gridy = 2;
        mainConstrain.fill = GridBagConstraints.BOTH;
        mainConstrain.gridwidth = 5;
        mainConstrain.gridheight = GridBagConstraints.REMAINDER;
        mainConstrain.weightx = 1;
        mainConstrain.weighty = 1;
	workstationPanel.add(mainContents, mainConstrain);

    }


    /**
     * Component to hold a small iconic image
     */
    class DecalPanel extends Canvas {
	java.awt.Image image;

	/**
	 * Instantiate to hold the supplied image
	 * @param image  the image to paint on this area
	 */
	DecalPanel(java.awt.Image image) {
	    this.image = image;
	    setSize(image.getWidth(this),image.getHeight(this));
	}

	/**
	 *  Paint the image onto the surface whenever the runtime says to
	 * @param g Graphics context in which to paint
	 */
	public void paint(Graphics g) {
	    g.drawImage(image,0,0,this);
	}
    }


    /**
     *  Helper method to get this user's OME name
     */
    public String getUserName() {
	return(userName);
    }

    /**
     *  Helper method to get this user's OME group's name
     */
    public String getGroupName() {
	return(groupName);
    }

    /**
     * Mark that a project has been selected
     */
    public void setProjectSet() {
        projectSet = true;
    }

    /**
     * Tell whether or not a project has been selected
     * @return boolean
     */
    public boolean getProjectSet() {
        return (projectSet);
    }

    /**
     * Mark that a dataset has been selected
     */
    public void setDatasetSet() {
        datasetSet = true;
    }

    /**
     * Tell whether or not a dataset has been selected
     * @return boolean
     */
    public boolean getDatasetSet() {
        return (datasetSet);
    }

    /**
     * Mark that an image has been selected
     */
    public void setImageSet() {
        imageSet = true;
    }

    /**
     * Tell whether or not an image has been selected
     * @return boolean
     */
    public boolean getImageSet() {
        return (imageSet);
    }

    /**
     * Mark that an analysis chain has been selected
     */
    public void setChainSet() {
        chainSet = true;
    }

    /**
     * Tell whether or not an analysis chain has been selected
     * @return boolean
     */
    public boolean getChainSet() {
        return (chainSet);
    }

    /**
     * Sets a project as the active (selected) project. Save its
     * name, tell the remote side that this session has selected
     * this project, get its ID, locally mark that a project has
     * been selected, and update the status bar.
     *
     * @param project the selected project
     */
    public void SetProject(Project project) {
      projectName.insert(0, project.getName());
      projectName.setLength(project.getName().length());
      getAccessor().setActiveProject(project);

      int pID = project.getID();
      System.err.println("new active project id = "+pID);

      setProjectSet();
      statusBar.repaint();
    }

    /**
     *  Fill in info viewing pane with details of a single project
     * @param project the project to be detailed
     */
    public void SummarizeProject(Project project) {
	prV = new ProjectViewer(project, Accessor);
	SummarizeEntity(prV);
    }

    /**
     *  Gets the active project's name
     * @return project name as a string
     */
    public String getProjectName() {
        return (projectName.toString());
    }


    /**
     * Sets a dataset as the active (selected) dataset. Save its
     * name, tell the remote side that this session has selected
     * this dataset, get its ID, locally mark that a dataset has
     * been selected, enable menu items that only turn on after a
     * dataset has been selected, and update the status bar.
     *
     * @param dataset the selected dataset
     */
    public void SetDataset(Dataset dataset) {
      datasetName.insert(0, dataset.getName());
      datasetName.setLength(dataset.getName().length());
      getAccessor().setActiveDataset(dataset);

      int dID = dataset.getID();
      System.err.println("new active dataset id = "+dID);

      setDatasetSet();
      menu.setEnabling("gotDataset");
      statusBar.repaint();
    }


    /**
     *  Fill in info viewing pane with details of a single dataset
     * @param dataset the dataset to be detailed
     */
    public void SummarizeDataset(Dataset dataset) {
      dsV = new DatasetViewer(dataset);
      SummarizeEntity(dsV);
    }

    /**
     *  Gets the active datsset's name
     * @return dataset name as a string
     */
    public String getDatasetName() {
        return (datasetName.toString());
    }


    /**
     * Sets an image as the active (selected) image. Save its
     * name, locally mark that an image has been selected,
     * and update the status bar.
     *
     * @param image the selected image
     */
    public void SetImage(Image image) {
      imageName.insert(0, image.getName());
      imageName.setLength(image.getName().length());
      setImageSet();
      statusBar.repaint();
    }


    /**
     *  Fill in info viewing pane with details of a single image
     * @param image the image to be detailed
     */
    public void SummarizeImage(Image image) {
      imV = new ImageViewer(image);
      pixPanel.setSize(holdsImage.getSize(null));
      holdsImage.add(pixPanel);

      SummarizeEntity(imV);
      imV.repaint();
      imC.doLoadImageObject(image);
    }


    /**
     *  Gets the active image's name
     * @return image name as a string
     */
    public String getImageName() {
        return (imageName.toString());
    }


    /**
     * Sets an analysis chain as the active (selected) chain. Save its
     * name, locally mark that an analysis chain has been selected,
     * and update the status bar.
     *
     * @param image the selected image
     */
    public void SetChain(Chain chain) {
      chainName.insert(0, chain.getName());
      chainName.setLength(chain.getName().length());
      setChainSet();
      statusBar.repaint();
    }

    /**
     *  Fill in info viewing pane with details of a single chain
     * @param chain the chain to be detailed
     */
    public void SummarizeChain(Chain chain) {
	Rectangle hr = holdsImage.getBounds();
	System.err.println("   holdsImage after creattion: "+hr);
	chV = new ChainViewer(chain);
	SummarizeEntity(chV);
	holdsImage.setBackground(new Color(155, 175, 203));
	ClientChainPanel chPanel = getChainPix(chain);

	Rectangle r = holdsImage.getBounds(null);
        Rectangle recV = Viewers.getBounds();
	Point pntM = mainContents.getLocation();
	Point globalPanelStart = new Point(recV.x, r.y+pntM.y);
	System.err.println("holdsImage has bounds: "+r);

	holdsImage.removeAll();
	holdsImage.add((JPanel)chPanel);
	holdsImage.validate();
	Rectangle chb = chPanel.getBounds();
	System.err.println("this panel's bounds:: "+chb);

	PChainLibraryCanvas chCanvas = chPanel.setCanvas();
	chCanvas.validate();
	PCamera pCam = chCanvas.getCamera();
	chV.repaint();

	chPanel.dumpContents();

    }

    /**
     *  Gets the active chain's name
     * @return chain name as a string
     */
    public String getChainName() {
        return (chainName.toString());
    }


    /**
     * Fills in an info viewing pane with details on a passed entity.
     * @param entity the entity whose details are to be displayed
     */
    protected void SummarizeEntity(ClientViewerPane enV) {
	viewPane.removePane();
	viewPane.addPane(enV);
	viewPane.validate();
    }

    /**
     *  Add a selected dataset to the active project, recording
     * the association permanently in the server's database.
     */
    public void addDatasetToProject() {
	Project p = Accessor.getActiveProject();
	int pID = p.getID();
	System.err.println("  project ID = " + pID);
	Dataset d = (Dataset)(Accessor.getActiveDataset());
	int dID = d.getID();
	System.err.println("  dataset ID = " + dID);
	HashMap p2dMap = new HashMap();
	Integer prID = new Integer(pID);
	p2dMap.put("project_id", prID.toString());
	Integer dsID = new Integer(dID);
	p2dMap.put("dataset_id", dsID.toString());
	Factory f = Accessor.bindings.getFactory();
	String className = new String("OME::Project::DatasetMap");
	if (!f.objectExists(className, p2dMap)) {
	    System.err.println("mapping ds "+dID+" to project "+pID);
	    OMEObject obj = f.newObject(className, p2dMap);
	    if (obj != null) {
		obj.storeObject();
		Accessor.bindings.getSession().commitTransaction();
	    }
	}
    }

    /**
     * Gets the workstation's tab panel
     * @return the current tabPanel instance
     */
    public ClientTabs getTabPanel() {
	return tabPanel;
    }

    /**
     * Gets the workstation's DataAccess
     * @return the current accessor of the remote system -- the hook into the server
     */
    public DataAccess getAccessor() {
	return Accessor;
    }


    /**
     * Makes a schematic diagram of an analysis chain.
     */
    private ClientChainPanel getChainPix(Chain chain) {
	Connection conn;
	conn = new Connection(Accessor.bindings.getSession(),
			      Accessor.bindings.getFactory());
	Controller cn = new Controller(conn, chain);
	ClientChainPanel ccp = new ClientChainPanel(cn, conn);
        Rectangle recV = ccp.getBounds();
        System.err.println("ClientChainPanel start:: x:"+recV.x+" y:"+recV.y);
	return ccp;

    }

    public void paint(Graphics g) {
	Graphics2D g2 = (Graphics2D)g;
    }


    /**
     * Helper method to change to a wait cursor.
     */
    public void setWaitCursor() {
	JFrame f = getOurFrame();
	if (!f.equals(null)) {
	    f.setCursor(waitcur);
	}
    }

    /**
     * Helper method to change to a default cursor.
     */
    public void setDefaultCursor() {
	JFrame f = getOurFrame();
	if (!f.equals(null)) {
	    f.setCursor(defcur);
	}
    }


    /**
     * Reports runtime errors.
     * @param action the action where the error occured
     * @param msg the specific error message
     * @return nothing
     */

    public void reportRuntime(String what, String msg) {
	JFrame fe = new JFrame("Execution Error");
	JOptionPane.showMessageDialog(fe, msg, what,
					       JOptionPane.ERROR_MESSAGE);
	return;

    }

    private JFrame getOurFrame() {
	Component c = this;
	while(c != null && !(c instanceof JFrame)){
	    c = c.getParent();
	}
	return (JFrame)c;
    }

}





class MyPix extends JPanel {

    public MyPix() {
	setPreferredSize(new Dimension(100,100));
    }

    public void paint(Graphics g) {
	Graphics2D g2 = (Graphics2D)g;
	Rectangle2D r = new Rectangle2D.Float(50, 50, 20, 20);
	g2.setStroke(new BasicStroke(4));
	g2.setPaint(Color.yellow);
	g2.draw(r);
    }
}

