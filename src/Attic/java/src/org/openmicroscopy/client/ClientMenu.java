/*
 * org.openmicroscopy.client.ClientMenu
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
import java.awt.geom.*;
import java.awt.Graphics2D;
import java.awt.event.KeyEvent;
import java.awt.event.*;
import java.lang.Runtime;
import java.lang.Runtime.*;
import java.util.Iterator;
import java.util.Vector;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.*;
import org.openmicroscopy.managers.*;


/**
 * Creates and manages the workstation's menus.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */


public class ClientMenu extends JFrame {

    ClientContents  ourClient;
    ClientLogin     ourLogin;
    ClientStatusBar statusBar;

    int currProjectID = 0;

    DataAccess  Accessor;
    Session     session;


    JMenuBar menuBar = new JMenuBar();

    /**
     * Main menu item for "Projects"
     */
    JMenu     jMenuProject         = new JMenu("Projects");
    JMenuItem jMenuProjectCreate   = new JMenuItem("Create");
    JMenuItem jMenuProjectAnnotate = new JMenuItem("Annotate");
    JMenuItem jMenuProjectSelect   = new JMenuItem("Select");
    JMenuItem jMenuProjectExit     = new JMenuItem("Exit");

    /**
     * Main menu item for "Datasets"
     */
    JMenu     jMenuDataset         = new JMenu("Datasets");
    private JMenuItem jMenuDatasetCreate   = new JMenuItem("Create");
    private JMenuItem jMenuDatasetAnnotate = new JMenuItem("Annotate");
    private JMenuItem jMenuDatasetSelect   = new JMenuItem("Select");
    private JMenuItem jMenuDatasetRemove   = new JMenuItem("Remove");

    /**
     * Main menu item for "Images"
     */
    JMenu     jMenuImages          = new JMenu("Images");
    private JMenuItem jMenuImagesSelect    = new JMenuItem("Select");
    private JMenuItem jMenuImagesImport    = new JMenuItem("Import");
    private JMenuItem jMenuImagesAnnotate  = new JMenuItem("Annotate");
    private JMenuItem jMenuImagesView      = new JMenuItem("Viewer");
    private JMenuItem jMenuImagesExport    = new JMenuItem("Export");
    private JMenuItem jMenuImagesRemove    = new JMenuItem("Remove");

    /**
     * Main menu item for "Analyses"
     */
    JMenu     jMenuAnalyze          = new JMenu("Analyses");
    private JMenuItem jMenuAnalysesSelect   = new JMenuItem("Select");
    private JMenuItem jMenuAnalysesAnnotate = new JMenuItem("Annotate");
    private JMenuItem jMenuAnalysesCreate   = new JMenuItem("Create");
    private JMenuItem jMenuAnalysesRun      = new JMenuItem("Run");

    /**
     * Main menu item for "Help"
     */
    JMenu     jMenuHelp            = new JMenu("Help");
    private JMenuItem jMenuHelpAbout       = new JMenuItem("About");


    Color backgnd       = new Color(232, 238, 0);


    /**
     * Creates the menu bar, populates it, adds mnemonics (keyboard shortcuts)
     * for many of the menu items, and add action handlers to respond to 
     * user actions in the menus.
     *
     * @param contents the ClientContents context
     * @param login  the current login context, used to get the remote accessor
     * @param status the workstation's status bar
     */
    public ClientMenu (ClientContents contents, ClientLogin login, ClientStatusBar status) {
	ourClient = contents;
	ourLogin = login;
	statusBar = status;
	Accessor = ourLogin.getAccessor();
	session  = Accessor.bindings.getSession();

        this.setSize(new Dimension(161, 17));


	// ********* Project menu ***************

	jMenuProject.setMnemonic(KeyEvent.VK_P);
	jMenuProject.add(jMenuProjectSelect);
	jMenuProjectSelect.setMnemonic(KeyEvent.VK_S);
	jMenuProjectSelect.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuProjectSelect_actionPerformed(e);
		  }
	      });

	jMenuProject.add(jMenuProjectAnnotate);
	jMenuProjectAnnotate.setMnemonic(KeyEvent.VK_A);
	jMenuProjectAnnotate.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuProjectAnnotate_actionPerformed(e);
		  }
	      });

	jMenuProject.add(jMenuProjectCreate);
	jMenuProjectCreate.setMnemonic(KeyEvent.VK_C);
	jMenuProjectCreate.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuProjectCreate_actionPerformed(e);
		}
	    });

	jMenuProject.addSeparator();
	jMenuProject.add(jMenuProjectExit);
	jMenuProjectExit.setMnemonic(KeyEvent.VK_X);
	jMenuProjectExit.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    ourLogin.logout();
		    System.exit(0);
		}
	    });



	// ************* Dataset menu *****************

	jMenuDataset.setMnemonic(KeyEvent.VK_D);
	jMenuDataset.add(jMenuDatasetSelect);
	jMenuDatasetSelect.setMnemonic(KeyEvent.VK_S);
	jMenuDatasetSelect.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuDatasetSelect_actionPerformed(e);
		  }
	      });

	jMenuDataset.add(jMenuDatasetAnnotate);
	jMenuDatasetAnnotate.setMnemonic(KeyEvent.VK_A);
	jMenuDatasetAnnotate.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuDatasetAnnotate_actionPerformed(e);
		  }
	      });

	jMenuDataset.add(jMenuDatasetCreate);
	jMenuDatasetCreate.setMnemonic(KeyEvent.VK_C);
	jMenuDatasetCreate.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuDatasetCreate_actionPerformed(e);
		}
	    });

	jMenuDataset.add(jMenuDatasetRemove);
	jMenuDatasetRemove.setMnemonic(KeyEvent.VK_R);
	jMenuDatasetRemove.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuDatasetRemove_actionPerformed(e);
		}
	    });



	// ************* Images menu *****************

	jMenuImages.setMnemonic(KeyEvent.VK_I);
	jMenuImages.add(jMenuImagesSelect);
	jMenuImagesSelect.setMnemonic(KeyEvent.VK_S);

	  jMenuImagesSelect.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuImageSelect_actionPerformed(e);
		  }
	      });

	jMenuImages.add(jMenuImagesAnnotate);
	jMenuImagesAnnotate.setMnemonic(KeyEvent.VK_A);
	jMenuImagesAnnotate.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuImageAnnotate_actionPerformed(e);
		  }
	      });

	jMenuImages.add(jMenuImagesImport);
	jMenuImagesImport.setMnemonic(KeyEvent.VK_I);
	jMenuImagesImport.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuImageImport_actionPerformed(e);
		}
	  });


	jMenuImages.add(jMenuImagesExport);
	jMenuImagesExport.setMnemonic(KeyEvent.VK_E);
	jMenuImagesExport.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuImageExport_actionPerformed(e);
		}
	  });

	jMenuImages.add(jMenuImagesView);
	jMenuImagesView.setMnemonic(KeyEvent.VK_V);
	jMenuImagesView.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuImageView_actionPerformed(e);
		  }
	      });

	jMenuImages.add(jMenuImagesRemove);
	jMenuImagesRemove.setMnemonic(KeyEvent.VK_R);
	jMenuImagesRemove.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuImageRemove_actionPerformed(e);
		  }
	      });



	// ************* Analysis menu *****************

	jMenuAnalyze.setMnemonic(KeyEvent.VK_A);
	jMenuAnalyze.add(jMenuAnalysesSelect);
	jMenuAnalysesSelect.setMnemonic(KeyEvent.VK_S);
	jMenuAnalysesSelect.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuAnalysisSelect_actionPerformed(e);
		}
	    });

	jMenuAnalyze.add(jMenuAnalysesAnnotate);
	jMenuAnalysesAnnotate.setMnemonic(KeyEvent.VK_A);
	jMenuAnalysesAnnotate.addActionListener(new java.awt.event.ActionListener() {
		  public void actionPerformed(ActionEvent e) {
		      jMenuAnalysesAnnotate_actionPerformed(e);
		  }
	      });

	jMenuAnalyze.add(jMenuAnalysesCreate);
	jMenuAnalysesCreate.setMnemonic(KeyEvent.VK_C);
	jMenuAnalysesCreate.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuAnalysesCreate_actionPerformed(e);
		}
	      });

	jMenuAnalyze.add(jMenuAnalysesRun);
	jMenuAnalysesRun.setMnemonic(KeyEvent.VK_R);
	jMenuAnalysesRun.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuAnalysesRun_actionPerformed(e);
		}
	      });



	// ************* Help menu *****************

	jMenuHelpAbout.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    jMenuHelpAbout_actionPerformed(e);
		}
	    });
	jMenuHelp.add(jMenuHelpAbout);
	jMenuHelp.setMnemonic(KeyEvent.VK_H);


	// Add the menus to the menu bar
	setEnabling("Start");

	menuBar.add(jMenuProject);
	menuBar.add(jMenuDataset);
	menuBar.add(jMenuImages);
	menuBar.add(jMenuAnalyze);
	/*
	  if (conn.getGroupID() == 1) {         // Group ID 1 is the admin group
	    menuBar.add(jMenuAdmin);
	}
	*/
	menuBar.add(jMenuHelp);

    }

    /**
     * Get the application's menu bar
     * @returns the created menu bar
    */
    public JMenuBar getOMEMenuBar() {
	return (JMenuBar)menuBar;
    }




    /**
     * Enables & disables menu items appropriate to current state.
     * Sets the menu state according to what menu selection has been made.
     */
    public void setEnabling (String state) {

	if (state.equals("Start")) {
	    setDisabled(new JMenuItem [] {jMenuProjectAnnotate, jMenuDatasetSelect,
					  jMenuDatasetAnnotate, jMenuDatasetCreate, jMenuDatasetRemove,
					  jMenuImagesSelect, jMenuImagesAnnotate, 
					  jMenuImagesImport, jMenuImagesRemove,
					  jMenuAnalysesSelect, jMenuAnalysesAnnotate,
					  jMenuAnalysesRun});


	}
	else if (state.equals("gotProject")) {
	    setEnabled(new JMenuItem [] {jMenuProjectAnnotate,
					   jMenuDatasetSelect,
					   jMenuDatasetCreate,
	                                   jMenuDatasetRemove});
	    setDisabled(new JMenuItem [] {jMenuDatasetAnnotate,
					   jMenuImagesAnnotate,
					   jMenuAnalysesSelect,
					   jMenuAnalysesAnnotate,
					   jMenuAnalysesRun,
	                                   jMenuImagesSelect,
	                                   jMenuImagesImport,
	                                   jMenuImagesRemove});
	}
	else if (state.equals("gotDataset")) {
	    setEnabled(new JMenuItem [] {jMenuDatasetAnnotate,
					   jMenuImagesAnnotate,
					   jMenuAnalysesSelect,
					   // If analysis chain selected
					   jMenuAnalysesAnnotate,
					   jMenuAnalysesRun,
					   // If dataset is still unlocked
	                                   jMenuImagesSelect,
	                                   jMenuImagesImport,
	                                   jMenuImagesRemove});
	}

    }



    /**
     * Disables passed menu items
     */
    public void setDisabled(JMenuItem[] disabled) {
	int i;

	for (i = 0; i < disabled.length; i++) {
	    disabled[i].setEnabled(false);
	}
    }

    /**
     * Enables passed menu items
     */
    public void setEnabled(JMenuItem[] enabled) {
	int i;

	for (i = 0; i < enabled.length; i++) {
	    enabled[i].setEnabled(true);
	}
    }



    // Action Performers

    /**
     * Action handler for: Project | Create action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuProjectCreate_actionPerformed(ActionEvent e) {
	ClientCreate Creator = new ClientCreate("Project",
					  ourLogin.getExperimenter(),
					  ourLogin.getGroup());
	Project p = (Project)Creator.getSelection(Accessor);
	if (p != null) {
	    ourClient.SetProject((Project)p);
	    ourClient.getTabPanel().updateDataset(p);
	    int id = p.getID();
	    setEnabling("gotProject");
	}
    }



    /**
     * Action handler for: Project | Select action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuProjectSelect_actionPerformed(ActionEvent e) {
	ClientSelect Selector = new ClientSelect("Projects", ourClient);
	Project p = (Project)Selector.getSelection();
	if (p != null) {
            ourClient.SetProject(p);
	    ourClient.SummarizeProject(p);
	    ourClient.getTabPanel().updateDataset(p);
	    int id = p.getID();
	    currProjectID = id;
	    setEnabling("gotProject");
	}
    }


    /**
     * Action handler for: Project | Annotate action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuProjectAnnotate_actionPerformed(ActionEvent e) {
      ClientViewerPane vp = (ClientViewerPane)ourClient.prV;
	String newDesc = getAnnotation(vp);
	if (newDesc != null) {
	    ourClient.prV.currPr.setDescription(newDesc);
	    storeChange((OMEObject)ourClient.prV.currPr);
	    ourClient.SummarizeProject(ourClient.prV.currPr);
	}

  }


    /**
     * Action handler for: Dataset | Create action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuDatasetCreate_actionPerformed(ActionEvent e) {
	ClientCreateDS Creator = new ClientCreateDS("Dataset",
                                              ourLogin.getExperimenter(),
					      ourLogin.getGroup());
	Dataset d;
	d = (Dataset)Creator.getSelection(Accessor);
	if (d != null) {
	    ourClient.SetDataset(d);
	    ourClient.SummarizeDataset(d);
	    ourClient.getTabPanel().updateImages(d);
	    ourClient.getTabPanel().updateChains(d);
	    setEnabling("gotDataset");
	    //ourClient.addDatasetToProject();
	    ProjectManager pm = session.getProjectManager();
	    Project p = Accessor.getActiveProject();
	    pm.addDataset(p, d);
	    ourClient.getTabPanel().updateDataset(Accessor.getActiveProject());
	}
    }



    /**
     * Action handler for: Dataset | Select action 
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuDatasetSelect_actionPerformed(ActionEvent e) {
        ClientSelect Selector = new ClientSelect("Datasets", ourClient);


	setCursor(null);

	Dataset d = (Dataset)Selector.getSelection();
        if (d != null) {
	  ourClient.setWaitCursor();
          ourClient.SetDataset(d);
	  ourClient.SummarizeDataset(d);
	  ourClient.getTabPanel().updateDataset(Accessor.getActiveProject());
	  ourClient.getTabPanel().updateImages(d);
	  ourClient.getTabPanel().updateChains(d);
          setEnabling("gotDataset");
	  ProjectManager pm = session.getProjectManager(); 
	  Project p = Accessor.getActiveProject();
	  pm.addDataset(p, d);
	  ourClient.setDefaultCursor();
	}
    }


    /**
     * Action handler for: Dataset | Annotate action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuDatasetAnnotate_actionPerformed(ActionEvent e) {
	ClientViewerPane vp = (ClientViewerPane)ourClient.dsV;
	String newDesc = getAnnotation(vp);
	if (newDesc != null) {
	    ourClient.dsV.currDS.setDescription(newDesc);
	    storeChange((OMEObject)ourClient.dsV.currDS);
	    ourClient.SummarizeDataset(ourClient.dsV.currDS);
	}
    }


    /**
     * Action handler for: Dataset | Remove action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuDatasetRemove_actionPerformed(ActionEvent e) {
        ClientSelect Selector = new ClientSelect("Datasets", ourClient);
	Dataset d = (Dataset)Selector.getSelection();
        if (d != null) {
	    System.err.println(" Remove dataset "+d);
	    notEnufGlue(new String("Remove dataset"));
	}
    }


    /**
     * Action handler for: Image | Select action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuImageSelect_actionPerformed(ActionEvent e) {
	System.err.println("select an image");
        ClientSelect Selector = new ClientSelect("Images", ourClient);
	org.openmicroscopy.Image img;
	img = (org.openmicroscopy.Image)Selector.getSelection();
	if (img != null) {
	    System.err.println("got selected image: "+img);
	    ourClient.setWaitCursor();
	    ourClient.SetImage(img);
	    ourClient.SummarizeImage(img);
	    ourClient.getTabPanel().updateImages(Accessor.getActiveDataset());
	    setEnabling("gotImage");
	    DatasetManager dm = session.getDatasetManager(); 
	    Dataset ds = session.getDataset();
	    ds.addImage(img);
	    //dm.addImage(img);
	    ourClient.setDefaultCursor();
	}
    }


    /**
     * Action handler for: Image | Annotate action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuImageAnnotate_actionPerformed(ActionEvent e) {
      if (ourClient.imV != null) {
	ClientViewerPane vp = (ClientViewerPane)ourClient.imV;
	String newDesc = getAnnotation(vp);
	if (newDesc != null) {
	    ourClient.imV.currIm.setDescription(newDesc);
	    storeChange((OMEObject)ourClient.imV.currIm);
	    ourClient.SummarizeImage(ourClient.imV.currIm);
	}
      }
  }
    /**
     * Action handle for: Image / Import action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuImageImport_actionPerformed(ActionEvent e) {
	Vector importSources = getImportSources();
	if (!importSources.isEmpty()) {
	    String status = doImporting(importSources);
	    if (status != null) {    // error message if not null
		ourClient.reportRuntime("Import error", status);
	    } else {
		ourClient.SummarizeDataset(ourClient.dsV.currDS);
		ourClient.getTabPanel().updateImages(ourClient.dsV.currDS);
	    }
	}
    }

    /**
     * Action handle for: Image / Export action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuImageExport_actionPerformed(ActionEvent e) {
	notEnufGlue(new String("ImageExport"));
    }



    /**
     * Action handler for: Image | View action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuImageView_actionPerformed(ActionEvent e) {
      try {
	  Process p = Runtime.getRuntime().exec("java -jar org.openmicroscopy.imageviewer.jar");
	  System.err.println(p.getErrorStream());
	  System.err.println("Process exited with: "+p.waitFor());
      } catch (Exception re) {
	  ourClient.reportRuntime("Running imageviewer",re.getMessage());
      }
  }



    /**
     * Action handler for: Image | Remove action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuImageRemove_actionPerformed(ActionEvent e) {
        ClientSelect Selector = new ClientSelect("Images", ourClient);
	org.openmicroscopy.Image i = (org.openmicroscopy.Image)Selector.getSelection();
        if (i != null) {
	    System.err.println(" Remove image "+i);
	    notEnufGlue(new String("Remove Image"));
	}

      }


    /**
     * Action handler for: Analysis | Select action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuAnalysisSelect_actionPerformed(ActionEvent e) {
	System.err.println("select a chain");
        ClientSelect Selector = new ClientSelect("Analyses", ourClient);
	//String ch = Selector.getSelection();
	Chain ch = (Chain)Selector.getSelection();
	if (ch != null) {
	    ourClient.setWaitCursor();
	    ourClient.SetChain(ch);
	    ourClient.SummarizeChain(ch);
	    ourClient.getTabPanel().updateChains(Accessor.getActiveDataset());
	    setEnabling("gotChain");
	    ourClient.setDefaultCursor();
	}

    }


    /**
     * Action handler for: Analysis | Annotate action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuAnalysesAnnotate_actionPerformed(ActionEvent e) {
      if (ourClient.chV != null) {
	ClientViewerPane vp = (ClientViewerPane)ourClient.chV;
	String newDesc = getAnnotation(vp);
	if (newDesc != null) {
	    ourClient.chV.currCh.setDescription(newDesc);
	    storeChange((OMEObject)ourClient.chV.currCh);
	    ourClient.SummarizeChain(ourClient.chV.currCh);
	}
      }
  }


    /**
     * Action handler for: Analysis | Create action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuAnalysesCreate_actionPerformed(ActionEvent e) {
      try {
	  Process p = Runtime.getRuntime().exec("java -jar org.openmicroscopy.vis.chains.jar");
	  System.err.println(p.getErrorStream());
	  int code = p.waitFor();
	  if (code != 0){
	      ourClient.reportRuntime("Creating analysis","process exit code"+code);
	  }
	  System.err.println("Process exited with: "+p.waitFor());
      } catch (Exception er) {
	  ourClient.reportRuntime("Running analysis",er.getMessage());
      }
  }


    /**
     * Action handler for: Analysis | Run action
     * Should not be directly called; only the run time knows when to call it
     */
  public void jMenuAnalysesRun_actionPerformed(ActionEvent e) {
      notEnufGlue(new String("Run analysis"));
  }


    /**
     * Action handler for: Help | About action
     * Should not be directly called; only the run time knows when to call it
     */
    public void jMenuHelpAbout_actionPerformed(ActionEvent e) {
	JFrame aboutFrame = new JFrame("About OME");
	JLabel aboutLabel = new JLabel("<html><b>&nbsp OME V2.0 alpha</b><br> copyright (c) 2003<br> Open Microscopy Environment<br>Image informatics for the microscopist<br>OME provides an environment for the management and analysis of microscope images <br></html>",
				       JLabel.CENTER);
	aboutFrame.getContentPane().setLayout(new BorderLayout());
	aboutFrame.getContentPane().add(aboutLabel);
	aboutFrame.setSize(300, 200);
	aboutFrame.setLocation(300,300);
	aboutFrame.setVisible(true);
    }



    /**
     * Helper method to get user edits to the description field of
     * various entities. Any entity that has a ClientViewerPane
     * representation and that has a 'description' text field
     * may call this helper.
     *
     * @param vp ClientViewerPane holding the informatio about the entity
     * @return String holding the new description contents
     */

    public String getAnnotation(ClientViewerPane vp) {
	String oldDesc = vp.description;
	String title = "Annotation for Dataset "+vp.name;
	
	JTextArea ta = new JTextArea();
	ta.setLineWrap(true);
	ta.setFont(new Font("Serif", Font.PLAIN, 14));
	ta.setBackground(new Color(232, 238, 238));
	ta.setText(oldDesc);

	String prompt = "Comments for this item";
	int result = JOptionPane.showOptionDialog(null, 
						  new Object [] { ta },
						  prompt,
						  JOptionPane.OK_CANCEL_OPTION,
						  JOptionPane.PLAIN_MESSAGE,
						  null, null, null);
	if (result == JOptionPane.OK_OPTION) {
	    // update description field in DB
	    System.err.println("Description is now: "+ta.getText());
	    return ta.getText();
	} else {
	    return null;
	}
    }


    /**
     * Method to control the import of the requested files.
     * @param filevector  vector of filenames to import
     * @returns status string containing any error messages
     */
    private String doImporting(Vector inFiles) {
	String infile = "";
	Iterator fileIt = inFiles.iterator();
	while (fileIt.hasNext()) {
	    infile = fileIt.next().toString();
	    System.err.println("Importing file "+infile);
	    
	}
	Dataset ds = Accessor.getActiveDataset();
	// TODO - detect no active dataset or DS locked
	ds.importImages(infile);
	return "import finished";
    }


    /**
     * Method to get user's choices of files to import
     * @returns vector of file names
     */
    private Vector getImportSources() {
	ClientFileChooser fc = new ClientFileChooser();
	Vector files = fc.getFiles("Import Files");

	return files;
    }

    /**
     * Method to write updated object back to the remote database.
     * @param OMEobject to write back
     */

    private void storeChange(OMEObject o) {
	o.storeObject();
	session.commitTransaction();

    }

    /*
     * Development placeholder function that tells the user
     * that this invoked menu item doesn't yet work all the
     * way through to the remote side.
     */

    private void notEnufGlue(String what) {
	String msg = new String("No action taken. Glue layer missing");
	ourClient.reportRuntime(what, msg);
	return;
    }

}


