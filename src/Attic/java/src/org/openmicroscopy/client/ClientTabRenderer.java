/*
 * org.openmicroscopy.client.ClientTabRenderer
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

import java.awt.*;
import javax.swing.*;
import java.net.*;
import java.util.List;
import org.openmicroscopy.*;

/**
 * Renders a single tab pane in a tab panel. Provides rendering methods that
 * are common to all the tabs in the tab panel. Extend this class to 
 * provide renderers for a specific tab.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */
public class ClientTabRenderer  extends JLabel {
    /**
     * Holds the current instance of overall ClientContents.
     */
    ClientContents contents;

    /**
     * holds the current instance of DataAccess for remote data access
     */
    DataAccess accessor;

    /**
     * Construct an initialize instance.
     * @param ourClient  current ClientContents context
     * @param Accessor   current DataAccess for remote data access
     */
    public ClientTabRenderer(ClientContents ourClient, DataAccess Accessor) {
	contents = ourClient;
	accessor = Accessor;
    }


    /** Display a single list element, presented according to its selection
     *  status. Set whether the tab is enabled according to the enabled
     *  status of the contained list.
     * @param o           Object representing text to display
     * @param folderIcon  Icon to show nex to the text
     * @param list        the list to populate
     * @param isSelected  whether the item is selected or not
     */
    public void showElement(Object o, ImageIcon folderIcon, JList list,
			    boolean isSelected) {
	String s;

	if (!o.equals(null)) {
	    setText(o.toString());
	}

	setIcon(folderIcon);
	
	if (isSelected) {
	    setBackground(list.getSelectionBackground());
	    setForeground(list.getSelectionForeground());
	} else {
	    setBackground(list.getBackground());
	    setForeground(list.getForeground());
	}
	setEnabled(list.isEnabled());
    }
}


/**
 * Renders the current list of datasets in the Datasets tab.
 * Implements a ListCellRenderer, extends the {@link #ClientTabRenderer} class.
 */
class dsTabRenderer extends ClientTabRenderer implements ListCellRenderer {
    static ImageIcon dsIcon;
    ImageIcon folderIcon;
    URL iconURL;

    /**
     * Create class instance, initialized with current ClientContents, 
     * DataAccess, and item icon.
     * @param ourClient  current ClientContents context
     * @param Accessor   current DataAccess for remote data access
     */
    public dsTabRenderer(ClientContents ourClient, DataAccess Accessor) {
	super(ourClient, Accessor);
	setOpaque(true);
	folderIcon= null;
	URL iconURL = getClass().getResource("Open24.gif");
	System.err.println("  icon resource: "+iconURL);
	if (iconURL != null) {
	    folderIcon = new ImageIcon(iconURL, "a dataset");
	}
	else { System.err.println("  Lost icon"); }
    }

    /**
     *  Render an element on the list. Java run time deals with this method.
     * @param list  the list that is being rendered
     * @param dsName an Object that contains a name
     * @param index  index of cell to be rendered
     * @param isSelected  true: cell selected - may affect display
     * @param cellHasFocus  true: is currently in focus -may affect display
     * @returns Component the rendered component
     */
   public Component getListCellRendererComponent (
      final JList list,
      Object dsName,            // Dataset's name
      int index,                // cell index
      boolean isSelected,       // is the cell selected
      boolean cellHasFocus) {   // the list and the cell have the focus


       if (dsName.toString().equals(ClientTabs.NO_DATASETS)) {
	   super.showElement(dsName, null, list, isSelected);
       } else {
	   super.showElement(dsName, folderIcon, list, isSelected);
       }

    return this;
  }

}


/**
 * Renders the current list of images in the Images tab.
 * Implements a ListCellRenderer, extends the {@link #ClientTabRenderer} class.
 */
class imTabRenderer extends ClientTabRenderer implements ListCellRenderer {
    static ImageIcon dsIcon;
    ImageIcon imageIcon;
    URL iconURL;

    /**
     * Create class instance, initialized with current ClientContents, 
     * DataAccess, and item icon.
     * @param ourClient  current ClientContents context
     * @param Accessor   current DataAccess for remote data access
     */
    public imTabRenderer(ClientContents ourClient, DataAccess Accessor) {
	super(ourClient, Accessor);
	setOpaque(true);
	imageIcon= null;
    }

    /**
     *  Render an element on the list. Java run time deals with this method.
     * @param list  the list that is being rendered
     * @param dsName an Object that contains a name
     * @param index  index of cell to be rendered
     * @param isSelected  true: cell selected - may affect display
     * @param cellHasFocus  true: is currently in focus -may affect display
     * @returns Component the rendered component
     */
   public Component getListCellRendererComponent (
      final JList list,
      Object imName,            // Dataset's name
      int index,                // cell index
      boolean isSelected,       // is the cell selected
      boolean cellHasFocus) {   // the list and the cell have the focus


    super.showElement(imName, imageIcon, list, isSelected);

    return this;
  }

}


/**
 * Renders the current list of analyses in the Analyses tab.
 * Implements a ListCellRenderer, extends the {@link #ClientTabRenderer} class.
 */
class chTabRenderer extends ClientTabRenderer implements ListCellRenderer {
    static ImageIcon dsIcon;
    ImageIcon chainIcon;
    URL iconURL;

    /**
     * Create class instance, initialized with current ClientContents, 
     * DataAccess, and item icon.
     * @param ourClient  current ClientContents context
     * @param Accessor   current DataAccess for remote data access
     */
    public chTabRenderer(ClientContents ourClient, DataAccess Accessor) {
	super(ourClient, Accessor);
	setOpaque(true);
	chainIcon= null;
    }

    /**
     *  Render an element on the list. Java run time deals with this method.
     * @param list  the list that is being rendered
     * @param dsName an Object that contains a name
     * @param index  index of cell to be rendered
     * @param isSelected  true: cell selected - may affect display
     * @param cellHasFocus  true: is currently in focus -may affect display
     * @returns Component the rendered component
     */
   public Component getListCellRendererComponent (
      final JList list,
      Object chName,            // Dataset's name
      int index,                // cell index
      boolean isSelected,       // is the cell selected
      boolean cellHasFocus) {   // the list and the cell have the focus


    super.showElement(chName, chainIcon, list, isSelected);

    return this;
  }

}
