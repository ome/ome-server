/*
 * org.openmicroscopy.alligator.Controller
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




package org.openmicroscopy.alligator;

import java.awt.*;
import java.awt.event.*;
import java.net.MalformedURLException;
import javax.swing.*;
//import javax.swing.table.TableModel;
import java.util.List;
import java.util.ArrayList;
//import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;
import org.openmicroscopy.remote.RemoteBindings;
import org.openmicroscopy.remote.RemoteException;
import org.openmicroscopy.analysis.ui.ModuleTreeModel;

public class Controller
{
    RemoteBindings  remote;
    Session         session;
    Factory         factory;
    MainFrame       mainFrame;

    List  localTypes;

    SemanticTypeTableModel  localTypesTableModel, remoteTypesTableModel;
    ModuleTreeModel         remoteModulesTreeModel;

    Map  typeFrames;
    Map  elementTableModels;

    public Controller()
    {
        this.mainFrame = null;
        this.remote = null;
        this.session = null;
        this.factory = null;
        this.localTypes = new ArrayList();
        this.localTypesTableModel = new SemanticTypeTableModel(this);
        this.remoteTypesTableModel = new SemanticTypeTableModel(this);
        this.remoteModulesTreeModel = new ModuleTreeModel();
        this.typeFrames = new HashMap();
        this.elementTableModels = new HashMap();

        SimpleDataTable table = new SimpleDataTable(1,
                                                    "TEST_TYPES",
                                                    "No description",
                                                    Granularity.IMAGE);
        SimpleDataTable.Column columnX =
            table.addColumn(2,"X","No description","integer");
        SimpleDataTable.Column columnY =
            table.addColumn(3,"Y","No description","integer");

        SimpleSemanticType type = new SimpleSemanticType(1,
                                                         "Test type",
                                                         "No description",
                                                         Granularity.IMAGE);
        type.addElement(2,"X","No description",columnX);
        type.addElement(3,"Y","No description",columnY);

        localTypes.add(type);
    }

    public void initialize()
    {
        localTypesTableModel.update(localTypes);
        refreshLocalTables();
        refreshRemoteTables();
        updateConnectedLabel();
        enableActions();
    }

    public void enableActions()
    {
        LOGIN_ACTION.setEnabled(session == null);
        LOGOUT_ACTION.setEnabled(session != null);
    }

    public void setMainFrame(MainFrame mainFrame)
    {
        this.mainFrame = mainFrame;
    }

    public void refreshLocalTables()
    {
        localTypesTableModel.fireTableDataChanged();
    }

    public void refreshRemoteTables()
    {
        if (session == null)
        {
            remoteTypesTableModel.updateList(null);
            remoteModulesTreeModel.updateCategories(null);
        } else {
            remoteTypesTableModel.update(factory);
            remoteModulesTreeModel.
                updateCategories(factory.findObjects("OME::Module::Category",
                                                     null));
        }
    }

    public void updateConnectedLabel()
    {
        if (session == null)
        {
            mainFrame.jConnectedLabel.setText("Not connected to OME");
        } else {
            Attribute user = session.getUser();
            mainFrame.jConnectedLabel.setText("Connected to OME as "+
                                              user.getStringElement("FirstName")+
                                              " "+
                                              user.getStringElement("LastName"));
        }
    }

    private int progresses = 0;

    public void startProgress()
    {
        if (progresses == 0)
            mainFrame.jRemoteProgressBar.setIndeterminate(true);
        progresses++;
    }

    public void stopProgress()
    {
        progresses--;
        if (progresses == 0)
        {
            mainFrame.jRemoteProgressBar.setIndeterminate(false);
        }
    }

    public void performLogin(final String url,
                             final String username,
                             final String password)
    {
        if (session != null)
            return;

        new Thread(new Runnable()
            {
                public void run()
                {
                    try
                    {
                        mainFrame.jRemoteProgressBar.setEnabled(true);
                        startProgress();

                        if (remote == null)
                            remote = new RemoteBindings();

                        remote.loginXMLRPC(url,username,password);
                        session = remote.getSession();
                        factory = remote.getFactory();

                        refreshRemoteTables();
                    } catch (ClassNotFoundException e) {
                        System.err.println(e);
                        session = null;
                        factory = null;
                    } catch (MalformedURLException e) {
                        System.err.println(e);
                        session = null;
                        factory = null;
                    } catch (RemoteException e) {
                        System.err.println(e);
                        session = null;
                        factory = null;
                    } finally {
                        enableActions();
                        updateConnectedLabel();
                        stopProgress();
                    }
                }
            }).start();
    }

    public void performLogout()
    {
        if (session == null)
            return;

        new Thread(new Runnable()
            {
                public void run()
                {
                    try
                    {
                        startProgress();
                        remote.logoutXMLRPC();

                        session = null;
                        factory = null;

                        refreshRemoteTables();
                    } catch (RemoteException e) {
                        session = null;
                        factory = null;
                        System.err.println(e);
                    } finally {
                        enableActions();
                        updateConnectedLabel();
                        stopProgress();
                        mainFrame.jRemoteProgressBar.setEnabled(false);
                    }
                }
            }).start();

    }

    public SemanticElementTableModel getElementTableModel(SemanticType type)
    {
        if (type == null) return null;

        SemanticElementTableModel  model =
            (SemanticElementTableModel)
            elementTableModels.get(new Integer(type.getID()));

        if (model == null)
        {
            model = new SemanticElementTableModel(this);
            elementTableModels.put(new Integer(type.getID()),model);
        }

        return model;
    }

    public void displaySemanticType(SemanticType type, boolean canEdit)
    {
        SemanticTypeFrame stFrame =
            (SemanticTypeFrame) typeFrames.get(new Integer(type.getID()));

        if (stFrame == null)
        {
            stFrame = new SemanticTypeFrame(this,type,canEdit);
            stFrame.pack();
            typeFrames.put(new Integer(type.getID()),stFrame);
        } else {
            stFrame.refreshUI();
        }

        stFrame.setVisible(true);
        stFrame.toFront();
    }

    private static int COMMAND_MASK =
        Toolkit.getDefaultToolkit().getMenuShortcutKeyMask();

    public abstract class AlligatorAction
        extends AbstractAction
    {
        public AlligatorAction(String name)
        {
            super(name);
        }

        public AlligatorAction(String name, int key)
        {
            super(name);
            putValue(ACCELERATOR_KEY,
                     KeyStroke.getKeyStroke(key,COMMAND_MASK));
        }

        public AlligatorAction(String name, int key, int modifiers)
        {
            super(name);
            putValue(ACCELERATOR_KEY,
                     KeyStroke.getKeyStroke(key,COMMAND_MASK | modifiers));
        }

        public KeyStroke getAccelerator()
        {
            return (KeyStroke) getValue(ACCELERATOR_KEY);
        }
    }

    private class LoginAction
        extends AlligatorAction
    {
        public LoginAction() { super("Login...",KeyEvent.VK_L); }

        public void actionPerformed(ActionEvent e)
        {
            if (session != null)
                return;

            LoginDialog  loginDialog = new LoginDialog(mainFrame);
            loginDialog.show();
            if (loginDialog.okay)
                performLogin(loginDialog.jURLField.getText(),
                             loginDialog.jUsernameField.getText(),
                             new String(loginDialog.jPasswordField.getPassword()));
        }
    }

    private class LogoutAction
        extends AlligatorAction
    {
        public LogoutAction() { super("Logout...",KeyEvent.VK_L,
                                      InputEvent.SHIFT_MASK); }

        public void actionPerformed(ActionEvent e)
        {
            performLogout();
        }
    }

    private class QuitAction
        extends AlligatorAction
    {
        public QuitAction() { super("Quit",KeyEvent.VK_Q); }

        public void actionPerformed(ActionEvent e)
        {
            performLogout();
            System.exit(0);
        }
    }

    public AlligatorAction LOGIN_ACTION = new LoginAction();
    public AlligatorAction LOGOUT_ACTION = new LogoutAction();
    public AlligatorAction QUIT_ACTION = new QuitAction();
}
