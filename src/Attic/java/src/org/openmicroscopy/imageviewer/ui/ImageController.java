/*
 * org.openmicroscopy.imageviewer.ui.ImageController
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
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.imageviewer.ui;

import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.awt.image.BufferedImage;
import java.util.Iterator;
import java.util.List;

import org.openmicroscopy.imageviewer.OMEException;
import org.openmicroscopy.imageviewer.OMEModel;

import org.openmicroscopy.remote.*;
import org.openmicroscopy.*;

/**
 * Controls the actions in the image viewer and regulates interaction between
 * the view and the data model.  This controller is detached from a particular
 * view visualization, as it interacts only with UI interfaces, and not the
 * UI classes themselves.  View objects can attach themselves to this
 * controller to receive and send data by calling ImageController.getInstance(),
 * and then invoking one of the setWidget methods.5
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ImageController
{
  private ListWidget imageListWidget;
  private MessageWidget statusWidget;
  private OMELoginWidget loginWidget;
  private ImageWidget imageWidget;
  private OMEImageFilterWidget imageFilterWidget;
  
  private OMEModel dataModel;
  
  private static ImageController controller;
  
  // singleton constructor
  private ImageController()
  {
    dataModel = new OMEModel();
  }
  
  // alternate singleton constructor w/remote bindings
  private ImageController(RemoteBindings bindings)
  {
    dataModel = new OMEModel(bindings);
  }
  
  /**
   * Returns the instance of the controller, so that widgets can subscribe and
   * publish events.  ImageController is a singleton class, so only one such
   * instance exists.
   * 
   * @return The instance of this image controller.
   */
  public static ImageController getInstance()
  {
    if(controller == null)
    {
      controller = new ImageController();
    }
    return controller;
  }
  
  public static ImageController getInstance(RemoteBindings bindings)
  {
    if(controller == null)
    {
      controller = new ImageController(bindings);
    }
    return controller;
  }
  
  /**
   * Sets the login UI widget to the specified widget.
   * 
   * @param loginWidget The login widget to control.
   */
  public void setLoginWidget(OMELoginWidget loginWidget)
  {
    this.loginWidget = loginWidget;
  }
  
  /**
   * Sets the image list UI widget to the specified widget.
   * 
   * @param listWidget The list widget to control.
   */
  public void setImageListWidget(ListWidget listWidget)
  {
    this.imageListWidget = listWidget;
  }
  
  /**
   * Sets the image filter UI widget to the specified widget.
   * 
   * @param filterWidget The filter widget to control.
   */
  public void setImageFilterWidget(OMEImageFilterWidget filterWidget)
  {
    this.imageFilterWidget = filterWidget;
  }
  
  /**
   * Sets the image display UI widget to the specified widget.
   * 
   * @param imageWidget The image widget to control.
   */
  public void setImageWidget(ImageWidget imageWidget)
  {
    this.imageWidget = imageWidget;
  }
  
  /**
   * Sets the status/reporting widget target of this controller to the
   * specified MessageWidget.  Setting statusWidget to be null will disconnect
   * any status widget from the controller.
   * 
   * @param statusWidget The widget through which this controller should display
   *                     status messages; null if this is not desired.
   */
  public void setStatusWidget(MessageWidget statusWidget)
  {
    this.statusWidget =  statusWidget;
  }
  
  // the internal login action
  protected void doLogin()
  {
    if(loginWidget != null)
    {
      String url = loginWidget.getRemoteURL();
      String username = loginWidget.getUsername();
      String password = loginWidget.getPassword();
      try
      {
        dataModel.login(url,username,password);
        showMessage("Logged in as " + username);
      }
      catch(OMEException oe)
      {
        showError(oe.getMessage());
      }
    }
  }
  
  // the internal logout action
  protected void doLogout()
  {
    try
    {
      dataModel.logout();
      showMessage("Logged out.");
    }
    catch(OMEException oe)
    {
      showError(oe.getMessage());
    }
  }
  
  // the internal load selected image action
  protected void doLoadSelectedImage()
  {
    if(imageListWidget == null)
    {
      return;
    }
    int selected = imageListWidget.getSelectedIndex();
    dataModel.loadImage(selected);
    
    if(imageWidget == null)
    {
      return;
    }
    if(imageFilterWidget != null)
    {
      imageFilterWidget.updatePossibleValues(dataModel.getImageInformation());
    }
    try
    {
      // really dumb data (should be the same as SVG image viewer)
      // TODO: get viewer preferences somehow
      imageWidget.displayImage(dataModel.getImageSlice(0,0,1,0,0,true,true,false));
      if(imageFilterWidget != null)
      {
        imageFilterWidget.loadDefaults(0,0,1,0,0,true,true,false);
      }
    }
    catch(OMEException oe)
    {
      showError(oe.getMessage());
    }
  }
  
  // load an image object
  public void doLoadImageObject(Image img) 
  {
    if(img == null)
    {
      return;
    }
    
    dataModel.loadImageObject(img); 
    if(imageWidget == null)
    {
      return;
    }
    if(imageFilterWidget != null)
    {
      imageFilterWidget.updatePossibleValues(dataModel.getImageInformation());
    }
    try
    {
      // really dumb data (should be the same as SVG image viewer)
      // TODO: get viewer preferences somehow
      //imageWidget.displayImage(dataModel.getImageSlice(13,0,1,0,0,true,true,false));
      imageWidget.displayImage(dataModel.getImageSlice(0,0,0,0,0,true,false,false));
      if(imageFilterWidget != null)
      {
        //imageFilterWidget.loadDefaults(13,0,1,0,0,true,true,false);
        imageFilterWidget.loadDefaults(0,0,1,0,0,true,true,false);
      }
    }
    catch(OMEException oe)
    {
      showError(oe.getMessage());
    }
  }

  
  // load all available images internal action
  protected void doLoadImages()
  {
    dataModel.loadImageRecords();
    
    if(imageListWidget != null)
    {
      List keys = dataModel.getImageKeys();
      List names = dataModel.getImageNames();
      
      int i=0;
      for(Iterator iter = keys.iterator(); iter.hasNext(); i++)
      {
        int key = ((Integer)iter.next()).intValue();
        String name = (String)names.get(i);
        imageListWidget.addEntry(String.valueOf(key)+": "+name);
      }
      imageListWidget.doUpdate();
    }
  }
  
  // internal color/channel filter action
  protected void doFilterImage()
  {
    if(imageFilterWidget != null)
    {
      int z = imageFilterWidget.getCurrentZ();
      int t = imageFilterWidget.getCurrentT();
      int cR = imageFilterWidget.getRedChannel();
      int cG = imageFilterWidget.getGreenChannel();
      int cB = imageFilterWidget.getBlueChannel();
      boolean rOn = imageFilterWidget.getRedOn();
      boolean gOn = imageFilterWidget.getGreenOn();
      boolean bOn = imageFilterWidget.getBlueOn();
  
      if(imageWidget != null)
      {
        try
        {
          BufferedImage image = dataModel.getImageSlice(z,t,cR,cG,cB,
                                                        rOn,gOn,bOn);
          if(image == null)
          {
            System.err.println("null slice");
          }
          imageWidget.displayImage(image);
        }
        catch(Exception e)
        {
          e.printStackTrace();
          showError("Error changing filter information");
        }
      }
    }
  }
  
  /**
   * Shows a general status message in the predefined status widget.
   * @param message The message to show.
   */
  protected void showMessage(String message)
  {
    if(statusWidget != null)
    {
      statusWidget.displayMessage(message);
    }
  }
  
  /**
   * Shows an error message in the predefined status widget.
   * @param error The error to show.
   */
  protected void showError(String error)
  {
    if(statusWidget != null)
    {
      statusWidget.displayError(error);
    }
  }  
  
  // login wrapper action
  private class LoginAction extends ControllerAction
  {
    public LoginAction()
    {
      super("Login",KeyEvent.VK_L);
    }
    
    public void actionPerformed(ActionEvent ae)
    {
      doLogin();
    }
  }
  
  // logout wrapper action
  private class LogoutAction extends ControllerAction
  {
    public LogoutAction()
    {
      super("Logout",KeyEvent.VK_L,KeyEvent.SHIFT_MASK);
    }
    
    public void actionPerformed(ActionEvent ae)
    {
      doLogout();
    }
  }
  
  // load images wrapper action
  private class LoadImageAction extends ControllerAction
  {
    public LoadImageAction()
    {
      super("Load Images",KeyEvent.VK_I);
    }
    
    public void actionPerformed(ActionEvent ae)
    {
      doLoadImages();
    }
  }
  
  // display image wrapper action
  private class DisplayImageAction extends ControllerAction
  {
    public DisplayImageAction()
    {
      super("Display Selected Image",KeyEvent.VK_D);
    }
    
    public void actionPerformed(ActionEvent ae)
    {
      doLoadSelectedImage();
    }
  }
  
  // update color filter wrapper action
  private class UpdateFilterAction extends ControllerAction
  {
    public UpdateFilterAction()
    {
      super("Update Filter",KeyEvent.VK_U);
    }
    
    public void actionPerformed(ActionEvent ae)
    {
      doFilterImage();
    }
  }
  
  /**
   * The login action to invoke.
   */
  public final ControllerAction LOGIN_ACTION = new LoginAction();
  
  /**
   * The logout action to invoke.
   */
  public final ControllerAction LOGOUT_ACTION = new LogoutAction();
  
  /**
   * The image load action to invoke.
   */
  public final ControllerAction LOAD_IMAGE_ACTION = new LoadImageAction();
  
  /**
   * The display image action to invoke.
   */
  public final ControllerAction DISPLAY_IMAGE_ACTION = new DisplayImageAction();
  
  /**
   * The update filter action to invoke.
   */
  public final ControllerAction UPDATE_FILTER_ACTION = new UpdateFilterAction();
}
