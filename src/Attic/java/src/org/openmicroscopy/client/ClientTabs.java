/*
 * org.openmicroscopy.client.ClientTabs
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
import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.BorderFactory;
import javax.swing.border.Border;
import org.openmicroscopy.*;

/**
 * Handles the client workstation's tabs pane.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   OME 2.0.3
 */


/**
 * Creates a Tab pane for displaying accessible Datasets, Images, and
 * Analyses. The panel supports selecting entities directly from
 * each tab's list of entities.
 */

public class ClientTabs extends JTabbedPane {
    ClientContents ourClient;
    JList datasetSelect;
    JList imageSelect;
    JList chainSelect;
    private JScrollPane dsSelectBox = new JScrollPane();
    private JScrollPane imageSelectBox = new JScrollPane();
    private JScrollPane analysisSelectBox = new JScrollPane();
    Border raisedbevel = BorderFactory.createRaisedBevelBorder();
    Color backgnd = new Color(255, 230, 100);
    ChangeListener tabsChanged;


    MouseListener ml;
    static final int DS_INDEX = 0;
    static final int IM_INDEX = 1;
    static final int CH_INDEX = 2;
    static final String NO_DATASETS = "no datasets to show";
    static final String NO_IMAGES   = "no images to show";
    static final String NO_ANALYSES = "no analyses to show";
    static final String DS_TABTIP =
	"See the datasets associated with the project";
    static final String IM_TABTIP = 
	"See what images the selected dataset contains";
    static final String CH_TABTIP = 
	"See the analyses associated with the dataset";

    /**
     * Construct a tab panel with an empty tab for each of the
     * entities that the panel shows. Populate each tab with an
     * empty list for holding entity names, paint each tab with a distinct
     * color and give each a separate entity type name as label.
     * Add a separate mouse listener to each tab.
     *
     * @param  Client   current ClientContents class instance
     * @param Accessor  current DataAccess class instance
     * @see    org.openmicroscopy.client.ClientContents
     * @see    org.openmicroscopy.client.DataAccess
     */
    public ClientTabs (ClientContents Client, DataAccess  Accessor) {
	final DataAccess accessor = Accessor;
	ourClient = Client;
	Color dsColor = new Color(255, 215, 175);
	Color imColor = new Color(255, 200, 186);
	Color anColor = new Color(255, 190, 186);


	String none = "none";
	String appName = "Status";
	StringBuffer projectName  = new StringBuffer();
	projectName.insert(0, none);
	projectName.setLength(none.length());

        setToolTipText("Select dataset, view dataset images, and work with analyses");

	String[] datasetList = {ClientTabs.NO_DATASETS};
	datasetSelect = new JList(datasetList);
	datasetSelect.setCellRenderer(new dsTabRenderer(Client, Accessor));
	dsSelectBox.getViewport().setView(datasetSelect);
	ml = new MouseAdapter() {
		public void mouseClicked(MouseEvent e) {
		    int index = datasetSelect.locationToIndex(e.getPoint());
		    System.err.println("  dataset index: "+index);
		    if (index > -1) {
		        String selName = (String)datasetSelect.getSelectedValue();
			if (selName.equals(NO_DATASETS)) {
			    return;
			}
			Dataset d = accessor.getDataset(selName);
			if (e.getClickCount() == 2) {
			    ourClient.SetDataset(d);
			    //setEnabling("gotDataset");
			} else {
			  System.err.println("  dataset name: "+selName);
			  System.err.println("  resolves to dataset: "+d);
			  ourClient.SummarizeDataset(d);
			  ourClient.getTabPanel().updateDataset(accessor.getActiveProject());
			}
		    }
		}
	    };
	datasetSelect.addMouseListener(ml);

	String[] imageList = {NO_IMAGES};
	imageSelect = new JList(imageList);
	imageSelect.setCellRenderer(new imTabRenderer(Client, Accessor));
	imageSelectBox.getViewport().setView(imageSelect);
	ml = new MouseAdapter() {
		public void mouseClicked(MouseEvent e) {
		    int index = imageSelect.locationToIndex(e.getPoint());
		    System.err.println("  image index: "+index);
		    if (index > -1) {
			if (e.getClickCount() == 1) {
			    String selName = (String)imageSelect.getSelectedValue();
			    if (selName.equals(NO_IMAGES)) {
				return;
			    }
			    org.openmicroscopy.Image i = accessor.getImage(selName);
			    System.err.println("  image name: "+selName);
			    System.err.println("  resolves to image: "+i);
			    ourClient.SummarizeImage(i);
			    ourClient.getTabPanel().updateImages(accessor.getActiveDataset());
			}
		    }
		}
	    };
	imageSelect.addMouseListener(ml);

	String[] analList = {NO_ANALYSES};
	chainSelect = new JList(analList);
	chainSelect.setCellRenderer(new chTabRenderer(Client, Accessor));
	analysisSelectBox.getViewport().setView(chainSelect);
	ml = new MouseAdapter() {
		public void mouseClicked(MouseEvent e) {
		    int index = chainSelect.locationToIndex(e.getPoint());
		    System.err.println("  chain index: "+index);
		    if (index > -1) {
		        String selName = (String)chainSelect.getSelectedValue();
			if (selName.equals(NO_ANALYSES)) {
			    return;
			}
			Chain c = accessor.getChain(selName);

			if (e.getClickCount() == 2) {
			    ourClient.SetChain(c);
			} else {
			  System.err.println("  chain name: "+selName);
			  System.err.println("  resolves to chain: "+c);
			  ourClient.SummarizeChain(c);
			  ourClient.getTabPanel().updateChains(accessor.getActiveDataset());
			}
		    }
		}
	    };
	chainSelect.addMouseListener(ml);

	datasetSelect.setBackground(dsColor);
	imageSelect.setBackground(imColor);
	chainSelect.setBackground(anColor);
        addTab("Datasets", null, datasetSelect, DS_TABTIP);
        addTab("Images", null, imageSelect, IM_TABTIP);
        addTab("Analyses", null, chainSelect, CH_TABTIP);
        setBackgroundAt(0, dsColor);
        setBackgroundAt(1, imColor);
        setBackgroundAt(2, anColor);

        setBorder(raisedbevel);
    }


    /** Assemble a list of all the datasets contained in 
     * the passed project.
     * @param  project  the Project instance to examine
     */

    public void updateDataset (Project project) {
	Dataset ds;
	java.util.List dsList = project.getDatasets();
	Iterator dsI = dsList.iterator();
	//Iterator dsI = project.iterateDatasets();
	Vector names = new Vector();
	System.err.println("  ---updateDataset for "+project.getName());
	while (dsI.hasNext()) {
	    ds = (Dataset)dsI.next();
	    //System.err.println("   dataset: " + ds.getName());
	    names.add(ds.getName());
	}
	datasetSelect.setListData(names);

    }


    /** Assemble a list of all the images contained in 
     * the passed dataset.
     * @param  dataset  the Dataset instance to examine
     */

    public void updateImages (Dataset dataset) {
	org.openmicroscopy.Image im;
	java.util.List imList = dataset.getImages();
	Iterator imI = imList.iterator();
	Vector names = new Vector();
	System.err.println("  ---updateImage for "+dataset.getName());
	while (imI.hasNext()) {
	    im = (org.openmicroscopy.Image)imI.next();
	    System.err.println("   image: " + im.getName());
	    names.add(im.getName());
	}
	imageSelect.setListData(names);
    }


    /** Assemble a list of all the analysis chains
     * available to be executed.
     * @param  dataset  the Dataset instance to examine
     */

    public void updateChains (Dataset dataset) {
	org.openmicroscopy.Chain ch;
	ClientSelect clSel = new ClientSelect(ourClient);
	Vector chV = clSel.getEntityList("Analyses")[0];
	//java.util.List chList = dataset.getChains();
	Iterator chI = chV.iterator();
	Vector names = new Vector();
	System.err.println("  ---updateChain for "+dataset.getName());
	while (chI.hasNext()) {
	    //ch = (org.openmicroscopy.Chain)chI.next();
	    //System.err.println("   chain: " + ch.getName());
	    //names.add(ch.getName());
	    names.add(chI.next());
	}
	chainSelect.setListData(names);
    }

}
