/*
 * org.openmicroscopy.client.ClientLogin
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
import java.net.URL;
import java.util.HashMap;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.remote.*;
import org.openmicroscopy.*;



/**
 * Handles logging in to OME server. Puts up a dialog box with labeled
 * fields for the OME server address, the user name and the password. 
 * Passes the collected information to the OME server and collects the 
 * response. Passes control back to caller if server OKs the login.
 * Else, sees if the user wants to try again. If so, tries the login
 * again, else exits the entire process.
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   OME 2.0.3
 */

public class ClientLogin {
    boolean logged_in = false;
    String  OMEprompt;
    String  OMEtitle;
    String  loginURL;
    String  experimenter;
    String  group;
    DataAccess Accessor;

    /**
     * Creates login dialog box with specified prompt and box title.
     * When user gets logged in, then
     * gets, saves an accessor to the OME server, and then calls
     * an internal routine that keeps trying for a good login
     * until the user succeeds or gives up.
     */
    public ClientLogin(String prompt, String title) {
	try {
	  Accessor = new DataAccess();
	} catch (Exception e) {
            System.err.println(e);
            System.exit(1);
        }

	OMEprompt = prompt;
	OMEtitle = title;
	logged_in = login();
    }


    /**
     * Notifies the OME server that workstation is logging out.
     * Changes the stored login state to false.
     */
    public void logout() {
	Accessor.Logout();
	logged_in = false;
    }

    /**
     * Gets the value of the stored login state;
     * @return current state of login
     */
    public boolean isLoggedIn() { return logged_in; }

    /**
     * Retrieves the current OMEserver's accessor.
     * @return OME server's accessor
     */
    public DataAccess getAccessor() { return Accessor; }


    /**
     * Gets the user's name.
     * @return String
     */
    public String  getExperimenter() {	return experimenter; }

    /**
     * Gets the user's group name.
     * @return user's group name
     */
    public String  getGroup() {	return group; }


  private boolean login() {
    boolean logged_in = false;
    String [] NamePassURL;

    while (!logged_in) {
	NamePassURL = getLoginInfo();
	if (NamePassURL[0].equals("")) {
	    System.exit(1);
	} else {
	    logged_in = doLogin(NamePassURL);
	}
    }
    return logged_in;
  }

  private boolean doLogin(String [] NamePassURL) {
      boolean logged_in = false;
      Attribute attrUser;
    String urlString =
        (NamePassURL[2].equals("")) ?
        "http://localhost:8002/" :
	  NamePassURL[2] ;
    URL url = null;
      System.err.println("Logging in for "+NamePassURL[0]+" on "+urlString);

    try
	{
	    url = new URL(urlString);
	    Accessor.Login(urlString, NamePassURL[0], NamePassURL[1]);
	    experimenter = NamePassURL[0];
	    attrUser = Accessor.getUser();
	    Attribute attrGroup = attrUser.getAttributeElement("Group");
	    group = attrGroup.getStringElement("Name");
	    logged_in = true;
	    System.err.println("login group: "+group);
	} catch (Exception e) {
	    System.err.println("Took exception to: " + e);
	    if (tryAgain() == false) {
		System.exit(1);
	    }
	}

    return logged_in;
  }


    private boolean tryAgain() {
	int status;
	JFrame fe = new JFrame("Login Error");
	String msg = new String("Error in login. Try again?");

	status = JOptionPane.showOptionDialog(fe,
					      new Object [] {msg},
					      new String("Login Error"),
					      JOptionPane.OK_CANCEL_OPTION,
					      JOptionPane.QUESTION_MESSAGE,
					      null, null, null);
	return (status == JOptionPane.OK_OPTION);
    }

  private String[] getLoginInfo() {
      int status;
      String [] result = {"", "", ""};
      JFrame f = new JFrame("Login");

      JPanel host = new JPanel();
      host.add("West", new JLabel("Host"));
      //JComboBox hostURL = new JComboBox(new String [] {"http://localhost:8002"});
      JComboBox hostURL = new JComboBox(new String [] {"http://localhost:8002"});
      hostURL.setEditable(true);
      host.add("East", hostURL);
      JLabel message = new JLabel(OMEprompt);
      Object [] hostPart = new Object [] {host, message};
      

      JTextField user = new JTextField();
      JPasswordField passwd = new JPasswordField();
      status = JOptionPane.showOptionDialog(f,
                                            new Object [] {hostPart, user, passwd},
                                            OMEtitle,
                                            JOptionPane.OK_CANCEL_OPTION,
                                            JOptionPane.QUESTION_MESSAGE,
                                            null,null,null);
      if (status == JOptionPane.OK_OPTION) {
          result[0] = user.getText();
          result[1] = new String(passwd.getPassword());
	  result[2] = hostURL.getSelectedItem().toString();
      }
      return result;
  }

    private String getGroup(String experimenter) {
	String myGroup;
	HashMap    criteria = new HashMap();
	//System.err.println("getGroup will use Session: "+bindings.getSession());
	criteria.put(new String("ome_name"), experimenter);
	System.err.println("criteria: "+criteria.toString());
	try {
	    System.err.println("Got remote factory");
	    //bindings.getFactory().findObject(new String("OME::Experimenter"), criteria);
	    Accessor.Lookup("OME::Experimenter", criteria);
	}
	catch (Exception e) {
	    System.err.println("find Experimenters exception: "+e.toString());
	}
	return "myGroup";

    }

}



