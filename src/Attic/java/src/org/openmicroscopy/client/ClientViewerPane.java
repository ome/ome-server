/*
 * org.openmicroscopy.client.ClientViewerPane
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

import java.lang.Double;
import java.awt.*;
import java.awt.geom.*;
import java.awt.font.*;
import java.awt.event.*;
import java.awt.Image.*;
import java.util.List;
import java.util.Vector;
import java.util.Iterator;
import javax.swing.border.*;
import javax.swing.ImageIcon;
import javax.swing.*;
import org.openmicroscopy.*;


/**
 * Creates and handles the workstation's entity display pane.
 * Extends JPanel. Display details about a selected entity,
 * for instance a dataset selected from a list in the Dataset tab pane.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */

public class ClientViewerPane  extends JPanel {
    //public class ClientViewerPane  extends JScrollPane {
    String title = null;
    String name;
    String description;
    String owner;
    String group;
    int    startX = 0;
    int    startY = 0;
    int    descX  = 0;     // Upper left of description (annotation) field
    int    descY  = 0;
    int    gap;
    int    startCol2;
    int    leftMargin = 0;
    Font titleFont  = new Font("Serif", Font.BOLD, 18);
    Font labelFont  = new Font("Serif", Font.PLAIN, 14);
    Font nameFont   = new Font("SansSerif", Font.BOLD, 14);
    Font memberFont = new Font("SansSerif", Font.BOLD, 12);
    Font hdrFont    = new Font("SansSerif", Font.BOLD, 16);
    boolean showIcons = false;
    Toolkit toolkit;
    /**
     * small icon of a locked padlock
     */
    ImageIcon smallLockIcon = null;

    /**
     * small icon of an unlocked padlock
     */
    ImageIcon smallUnlockIcon = null;

    /**
     * icon of a locked padlock
     */
    ImageIcon LockIcon = null;

    /**
     * icon of aN unlocked padlock
     */
    ImageIcon UnlockIcon = null;


    /**
     * Create a blank viewer pane, complete with icons and display methods.
     * 
     */
    public ClientViewerPane () {
	java.awt.Image smallLock;
	java.awt.Image smallUnlock;
	java.awt.Image largeLock;
	java.awt.Image largeUnlock;

	setBorder(BorderFactory.createEtchedBorder());

	setPreferredSize(new Dimension(300,400));
	toolkit = Toolkit.getDefaultToolkit();
	smallLock = toolkit.getImage(getClass().getResource("lock.png"));
	System.err.println("  smallLock is "+smallLock);
	if (smallLock != null) {
	    showIcons = true;
	    smallLockIcon = new ImageIcon(smallLock);
	    smallUnlock = toolkit.getImage(getClass().getResource("unlock.png"));
	    System.err.println("  smallUnlock is "+smallUnlock);
	    smallUnlockIcon = new ImageIcon(smallUnlock);

	    largeLock = smallLock.getScaledInstance(24, 24, java.awt.Image.SCALE_AREA_AVERAGING);
	    LockIcon = new ImageIcon(largeLock);
	    largeUnlock = smallUnlock.getScaledInstance(24, 24, java.awt.Image.SCALE_AREA_AVERAGING);
	    UnlockIcon= new ImageIcon(largeUnlock);
	}
    }


    /**
     * Sets up the paint operations common to all viewer pane occupants.
     * Sets up dimensions, background color, location for text, then calls
     * method to paint.
     * @param g current Graphics context
     * @param backgnd  background color to use
     * @param hdr text to write as header line
     * @param showLock if true, show entity's lock state, else don't show
     * @param isLocked if true, entity is locked, else unlocked
     */
    protected void CommonViewerPaint (Graphics g, Color backgnd, String hdr,
				      boolean showLock, boolean isLocked) {
	Graphics2D g2 = (Graphics2D)g;

	setOpaque(true);
	int width  = getSize().width;
	int height = getSize().height;
	g2.setColor(backgnd);
	g2.fillRect(0, 1, width, height);
	g2.setColor(new Color(0,0,0));

	g2.setFont(nameFont);
	FontRenderContext frc = g2.getFontRenderContext();
	// find interline sep. & width longest label
	Rectangle2D box = nameFont.getStringBounds("Experimenter", frc);
	gap = (int)box.getHeight() + 5;
	startCol2 = (int)box.getWidth() + 40;

	paintCommonComponent(g, hdr, showLock, isLocked);
    }


    private void paintCommonComponent(Graphics g, String hdr,
				      boolean showLock, boolean isLocked) {
	if (title != null) {
	    startX = startY = 0;
	    Graphics2D g2 = (Graphics2D)g;
	    Rectangle bounds = getBounds();
	    //setBackground(new Color(50, 100, 150));
	    
	    DrawTitle(g2, bounds, titleFont, title);
	    DrawCommon(g2, name, description, owner, group);
	    if (showLock) {
		ShowLockState(g2, isLocked, startX, startY);
	    }
	    if (hdr != null) {
		DrawHeader(g2, bounds, hdrFont, hdr);
	    }
	}

    }


    /**
     * Draw the pane's title
     * @param g current Graphics context
     * @param bounds X,Y bounds of title's display box
     * @param titleFont what font to use when writing the title
     * @param title the actual string to draw
     */
    protected void DrawTitle (Graphics2D g, Rectangle bounds,
			    Font titleFont, String title) {
      Rectangle2D box;

      g.setFont(titleFont);
      FontRenderContext frc = g.getFontRenderContext();
      box = titleFont.getStringBounds(title, frc);
      int currY = startY + 40;
      int currX = startX + bounds.x + bounds.width/2 - (int)(box.getWidth()/2);

      g.drawString(title, currX, currY);
      startY += box.getHeight()/2;

      g.drawLine(currX, currY+4, currX + (int)box.getWidth(), currY+4);

      startX = 0;
      startY = currY;
    }

    /**
     * Draw the field's header
     * @param g current Graphics context
     * @param bounds X,Y bounds of text display box
     * @param hdrFont what font to use when writing the hdr string
     * @param header the actual string to draw
     */
    protected void DrawHeader (Graphics2D g, Rectangle bounds,
			    Font hdrFont, String header) {
      Rectangle2D box;

      g.setFont(hdrFont);
      FontRenderContext frc = g.getFontRenderContext();
      box = hdrFont.getStringBounds(header, frc);
      int currY = startY + 40;
      int currX = startX + bounds.x + bounds.width/2 - (int)(box.getWidth()/2);

      g.drawString(header, currX, currY);
      startY = currY + (int)box.getHeight()/2;

      g.drawLine(currX, currY+4, currX + (int)box.getWidth(), currY+4);

      //startX = 0;
      //startY = 0;
    }



    /**
     * Draw the common fields
     * @param g current Graphics context
     * @param name name of entity being displayed
     * @param description textual description of entity
     * @param experimenter name of owner
     * @param experimenter name of owner's group
     */
    protected void DrawCommon(Graphics2D g, String name, String description,
			      String experimenter, String group) {
	int lineSep;
	leftMargin = 60;
	Rectangle2D box;
	FontRenderContext frc;

	// Needs to be internationalized !
	String labels [] = new String [] {"Name", "Description", "Experimenter", "Group"};
	String names [] = new String [] {name, description, experimenter, "Sorger"};

	startY += 40;
	startX += leftMargin;
	for (int i = 0; i < labels.length; i++) {
	    DrawNameAndValue(g, labels[i], names[i]);
	}
	startX -= leftMargin;
    }


    /**
     * Draw a label and its contents
     * @param g current Graphics context
     * @param FldName name of field being displayed
     * @param FldValue contents of field
     */
    protected void DrawNameAndValue(Graphics2D g2, String FldName,
				    String FldValue) {
	int currX = startX;
	int currY = startY;

	g2.setFont(labelFont);
	g2.drawString(FldName, currX, currY);
	currX += startCol2;
	g2.setFont(nameFont);
	g2.drawString(FldValue, currX, currY);
	startY += gap;
    }


    private void ShowLockState(Graphics2D g2, boolean isLocked, int startX,
				  int startY) {
	int currX = startX;
	int currY = startY;

	if (showIcons) {
	    currX += leftMargin;
	    g2.setFont(labelFont);
	    g2.drawString("State", currX, currY);
	    currX += startCol2;
	    currY -= (LockIcon.getIconHeight() - 7);
	    if (isLocked) {
		LockIcon.paintIcon(this, g2, currX, currY);
	    } else {
		UnlockIcon.paintIcon(this, g2, currX, currY);
	    }
	}
    }



    public void showSelectedAnalysis(Chain chain) {

    }

    public void showSelectedImage(org.openmicroscopy.Image image) {

    }
}


/**
 * Displays information about a single project
 * Extends base ClientViewerPane
 */
class ProjectViewer extends ClientViewerPane {
    Project currPr;
    Vector dsNames = new Vector();
    Color  backgnd = new Color(160, 160, 145);

    /**
     * Extracts name, owner, and associated dataset names of
     * target project, and displays them.
     * @param project the project to display
     */
    public ProjectViewer (org.openmicroscopy.Project project) {
	title = "Project";
	name = project.getName();
	description = project.getDescription();
	//Attribute ownerAttr = project.getOwner();
	//owner = new String(ownerAttr.getStringElement("FirstName") + " " +
	//ownerAttr.getStringElement("LastName"));
	owner = "me";

	List dsList = project.getDatasets();
	//System.err.println("dataset: "+dataset+"imageList: "+imageList);
	Iterator dsI = dsList.iterator();
	while (dsI.hasNext()) {
	  dsNames.add(((org.openmicroscopy.Dataset)dsI.next()).getName());
	}
	repaint();
    }

    /**
     * Paints the project display.
     * @param g current Graphics context
     */
    public void paint(Graphics g) {
	Graphics2D g2 = (Graphics2D)g;

	CommonViewerPaint(g2, backgnd, "Datasets", false, false);

	int currX = leftMargin;
	int currY = startY + 60;
	int sz = dsNames.size();
	for (int i = 0; i < sz; i++) {
	    g2.drawString((String)dsNames.get(i), currX, currY);
	    currY += gap;
	}
    }
}	



/**
 * Displays information about a single dataset
 * Extends base ClientViewerPane
 */
class DatasetViewer extends ClientViewerPane {
    boolean locked;
    Dataset currDS;
    Vector imageNames = new Vector();
    Color  backgnd = new Color(190, 175, 150);

    /**
     * Extracts name, owner, description, locked state, 
     * and associated images of target dataset and displays them.
     * @param dataset the dataset to display
     */
    public DatasetViewer (Dataset dataset) {
	currDS = dataset;
	setBorder(BorderFactory.createEtchedBorder());
	title = "Dataset";
	name = dataset.getName();
	System.err.println("  dataset: "+dataset+" name: "+name);
	description = dataset.getDescription();
	Attribute ownerAttr = dataset.getOwner();
	owner = new String(ownerAttr.getStringElement("FirstName") + " " +
			   ownerAttr.getStringElement("LastName"));


	//HashMap criteria = new HashMap();
	//criteria.put(new String("group_id"), 
	//OMEObject grpObj= accessor.Lookup("groups",criteria);

	//Attribute groupAttr = dataset.getGroup();
	//group = groupAttr.GetStringElement("Group");
	locked = dataset.isLocked();

	List imageList = dataset.getImages();
	System.err.println("dataset: "+dataset+"imageList: "+imageList);
	Iterator imI = imageList.iterator();
	while (imI.hasNext()) {
	  imageNames.add(((org.openmicroscopy.Image)imI.next()).getName());
	}
    }
	
    /**
     * Paints the dataset display.
     * @param g current Graphics context
     */
    public void paint(Graphics g) {
	Graphics2D g2 = (Graphics2D)g;

	CommonViewerPaint(g2, backgnd, "Images", true, locked);

	int currX = leftMargin;
	int currY = startY + 60;
	int sz = imageNames.size();
	for (int i = 0; i < sz; i++) {
	    g2.drawString((String)imageNames.get(i), currX, currY);
	    currY += gap;
	}

    }

}



/**
 * Displays information about a single image
 * Extends base ClientViewerPane
 */
class ImageViewer extends ClientViewerPane {
    Iterator imI;
    org.openmicroscopy.Image  currIm;
    String created;
    String inserted;
    Color  backgnd = new Color(180, 160, 145);

    /**
     * Extracts name, owner, description, created and inserted date/times,
     * and displays them.
     * @param dataset the dataset to display
     */
    public ImageViewer (org.openmicroscopy.Image image) {
	currIm = image;
	title = "Image";
	name = image.getName();
	description = image.getDescription();
	Attribute ownerAttr = image.getExperimenter();
	owner = new String(ownerAttr.getStringElement("FirstName") + " " +
			   ownerAttr.getStringElement("LastName"));
	created = image.getCreated();
	inserted = image.getInserted();

	repaint();
    }
	

    /**
     * Paints the image display.
     * @param g current Graphics context
     */
    public void paint(Graphics g) {
	System.err.println("  repainting imv");
	Graphics2D g2 = (Graphics2D)g;
	CommonViewerPaint(g2, backgnd, null, false, false);

	startX += leftMargin;
	startY += gap;
	DrawNameAndValue(g2, "Created", created);
	DrawNameAndValue(g2, "Loaded",  inserted);
    }
}


/**
 * Displays information about a single analysis chain
 * Extends base ClientViewerPane
 */
class ChainViewer extends ClientViewerPane {
    boolean locked;
    Chain  currCh;
    AnalysisPath path;
    Vector nodes = new Vector();
    Color  backgnd = new Color(200, 185, 155);

    /**
     * Extracts name, owner, description, and locked state
     * for target analysis chain  and displays them.
     * @param dataset the dataset to display
     */
    public ChainViewer (Chain chain) {
	currCh = chain;
	Chain.Node nd;

	title = "Analysis Chain";
	name = chain.getName();
	description = chain.getDescription();
	Attribute ownerID = chain.getOwner();
	Attribute ownerAttr = chain.getOwner();
	owner = new String(ownerAttr.getStringElement("FirstName") + " " +
			   ownerAttr.getStringElement("LastName"));
	locked = chain.getLocked();


	repaint();
    }
	

    /**
     * Paints the analysis chain display.
     * @param g current Graphics context
     */
    public void paint(Graphics g) {
	System.err.println("  repainting chv");
	Graphics2D g2 = (Graphics2D)g;
	CommonViewerPaint(g2, backgnd, "Chain Diagram", true, locked);
	startX += leftMargin;
	startY += gap;

	int sz = nodes.size();
	for (int i = 0; i < sz; i++) {
	    DrawNameAndValue(g2,"node:", (String)nodes.get(i));
	}

	int currX = leftMargin;
	int currY = startY + 60;

    }

    private String GetLastComponent(String s, int ch) {
	return(s.substring(s.lastIndexOf(ch)+1));
    }

    private void MakePath(Chain chain) {
	int maxBreadth = 0;
	int breadth = 0;
	Iterator chI;
	Chain.Node nd;
	Chain.Node parent;
	Chain.Node child;
	Vector v = new Vector();
	Vector path = new Vector();
	Vector parents = new Vector();

	chI = chain.iterateNodes();
	while (chI.hasNext()) {
	    v.add(chI.next());
	}

	// Get root node of path
	for (int i = 0; i < v.size(); i++) {
	    if (((Chain.Node)v.get(i)).getInputLinks().size() == 0) {
		parent = (Chain.Node)v.get(i);
		path.add(parent);
		parents.add(parent);
		v.remove(i);
		breadth = 1;
		System.err.println("Chain start: " + parent.getModule().getName());
		break;
	    }
	}
	if (breadth > maxBreadth) { maxBreadth = breadth; }

	// Arrange in breadth first order & place in path vector
	while (v.size() > 0) {
	    Vector newParents = new Vector();
	    breadth = 0;
	    while (parents.size() > 0) {
		System.err.println("parents size = " + parents.size());
		parent = (Chain.Node)parents.remove(0);
		System.err.println("Checking parent: "+ parent.getModule().getName());
		Iterator children = parent.iterateOutputLinks();
		while (children.hasNext()) {
		    child = ((Chain.Link)children.next()).getToNode();
		    System.err.println("   child link to: "+child.getModule().getName());
		    for (int i = 0; i < v.size(); i++) {
			System.err.println("     v.size = "+v.size());
			if (child.equals(v.get(i))) {
			    System.err.println("Child "+child.getModule().getName());
			    breadth++;
			    path.add(v.get(i));
			    newParents.add(v.get(i));
			    v.remove(i);
			}
		    }
		}
	    }
	    if (breadth > maxBreadth) { maxBreadth = breadth; }
	    System.err.println("breadth this level = " + breadth);
	    parents = newParents;
	}

	// Scan path array & build visual graph 
	int i = 0;
	while (i < path.size()) {
	    Vector kids = new Vector();
	    Chain.Node root = (Chain.Node)path.get(i++);
	    while (i < path.size()) {
		Chain.Node kid = (Chain.Node)path.get(i);
		Iterator pLinks = kid.iterateInputLinks();
		boolean isKid = false;
		while (pLinks.hasNext()) {
		    if (pLinks.next().equals(root)) {
			isKid = true;
			kids.add(kid);
			break;
		    }
		}
		if (isKid == false) {
		    break;
		}
		i++;
	    }
	}

    }


}

