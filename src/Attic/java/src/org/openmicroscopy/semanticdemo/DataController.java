/*
 * org.openmicroscopy.semanticdemo.DataController
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
package org.openmicroscopy.semanticdemo;

import java.awt.image.BufferedImage;
import java.util.*;

import org.openmicroscopy.Attribute;
import org.openmicroscopy.Image;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.imageviewer.OMEModel;
import org.openmicroscopy.semanticdemo.data.AnnotationAttributeMap;
import org.openmicroscopy.semanticdemo.data.DBVisualizationFactory;
import org.openmicroscopy.semanticdemo.data.OverlayAttributeMap;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class DataController
{
  private Set annotationSet;
  private Set overlaySet;
  private Set typeViewSet; // maybe necessary, maybe not
  
  private OMEModel dataModel;
  private DBVisualizationFactory dbvFactory;
  private OTFManager manager;
  private OverlayAttributeMap vam;
  private AnnotationAttributeMap aam;
  
  private OverlayTypesContainer typesContainer;
  private AnnotationsContainer notesContainer;
  
  // HACK
  private OverlayImagePanel imagePanel;
  
  private class AnnotationImpl implements AnnotationsContainer
  {
    Map keyMap;
    
    public AnnotationImpl()
    {
      keyMap = new HashMap();
    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.AnnotationsContainer#addAnnotation(java.lang.String, java.lang.String)
     */
    public void addAnnotation(String key, String annotation)
    {
      // TODO Auto-generated method stub
      if(!keyMap.containsKey(key))
      {
        List valueList = new ArrayList();
        valueList.add(annotation);
        keyMap.put(key,valueList);
      }
      else
      {
        List valueList = (List)keyMap.get(key);
        valueList.add(annotation);
      }

    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.AnnotationsContainer#getAnnotations(java.lang.String)
     */
    public Collection getAnnotations(String key)
    {
      return (Collection)keyMap.get(key);
    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.AnnotationsContainer#getKeyNames()
     */
    public List getKeyNames()
    {
      List nameList = new ArrayList(keyMap.keySet());
      Collections.sort(nameList);
      return nameList;
    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.AnnotationsContainer#setAnnotation(java.lang.String, java.lang.Object)
     */
    public void setAnnotation(String key, Object annotation)
    {
      if(annotation == null)
      {
        keyMap.remove(key);
      }
      else if(annotation instanceof String)
      {
        keyMap.put(key,annotation);
      }
      else if(annotation instanceof String[])
      {
        String[] strings = (String[])annotation;
        keyMap.put(key,Arrays.asList(strings));
      }
      else if(annotation instanceof Collection)
      {
        keyMap.put(key,annotation);
      }

    }


  }
  
  private class ContainerImpl implements OverlayTypesContainer
  {
    Map typeMap;
    
    public ContainerImpl()
    {
      typeMap = new HashMap();
    }
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.OverlayTypesContainer#addOverlayType(java.lang.String, java.util.Collection)
     */
    public void addOverlayType(String typeName, Collection overlays)
    {
      typeMap.put(typeName,overlays);
    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.OverlayTypesContainer#getOverlays(java.lang.String)
     */
    public Collection getOverlays(String typeName)
    {
      // TODO Auto-generated method stub
      return (Collection)typeMap.get(typeName);
    }
    
    /* (non-Javadoc)
     * @see org.openmicroscopy.semanticdemo.OverlayTypesContainer#getTypeNames()
     */
    public List getTypeNames()
    {
      List nameList = new ArrayList(typeMap.keySet());
      Collections.sort(nameList);
      return nameList;
    }
  }
  
  public DataController(OverlayImagePanel panel)
  {
    this.imagePanel = panel;
    annotationSet = new HashSet();
    overlaySet = new HashSet();
    typeViewSet = new HashSet();
    dataModel = new OMEModel();
    typesContainer = new ContainerImpl();
    notesContainer = new AnnotationImpl();
    
    try
    {
      dataModel.login("http://localhost:8005","jmellen","iLLibihiw930");
      dbvFactory = DBVisualizationFactory.getInstance(dataModel.getFactory());
      manager = dbvFactory.getDefaultOTFManager();
      
      Map imageMap = new HashMap();
      imageMap.put("id",new Integer(1));
      
      Image image = (Image)(dataModel.getFactory().findObject("OME::Image",imageMap));
      dataModel.loadImageObject(image);
      BufferedImage bi = dataModel.getImageSlice(31,0,1,0,0,true,true,false);
      
      panel.displayImage(bi);
      vam = new OverlayAttributeMap(dataModel.getFactory(),image);
      aam = new AnnotationAttributeMap(dataModel.getFactory(),image);
      
      SemanticType[] types = vam.getSupportedTypes();
      for(int i=0;i<types.length;i++)
      {
        System.err.println("Supported type:"+types[i].getName());
        OverlayTypeFactory factory = manager.getOverlayFactory(types[i]);
        Attribute[] attributes = vam.getAttributesByType(types[i]);
        Overlay[] overlays = new Overlay[attributes.length];
        for(int j=0;j<attributes.length;j++)
        {
          overlays[j] = factory.generateOverlay(attributes[j]);
        }
        typesContainer.addOverlayType(types[i].getName(),Arrays.asList(overlays));
        
      }
      
      // TODO: the same for annotations + the factory methods to extract from
      // the database
         
      
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
  }
  
  public String[] getOverlayNames()
  {
    List nameList = typesContainer.getTypeNames();
    String[] names = new String[nameList.size()];
    nameList.toArray(names);
    return names;
  }
  
  public void loadOverlays(String typeName)
  {
    Collection overlaySet = typesContainer.getOverlays(typeName);
    Overlay[] overlays = new Overlay[overlaySet.size()];
    overlaySet.toArray(overlays);
    imagePanel.setOverlays(overlays);
  }
  
  public void addAnnotationReceiver(AnnotationReceiver ar)
  {
    if(ar != null)
    {
      annotationSet.add(ar);
    }
  }
  
  public AnnotationReceiver removeAnnotationReceiver(AnnotationReceiver ar)
  {
    if(ar != null)
    {
      if(annotationSet.contains(ar))
      {
        annotationSet.remove(ar);
      }
      return ar;
    }
    return null;
  }
  
  public void addOverlayReceiver(OverlayReceiver or)
  {
    if(or != null)
    {
      overlaySet.add(or);
    }
  }
  
  public OverlayReceiver removeOverlayReceiver(OverlayReceiver or)
  {
    if(or != null)
    {
      if(overlaySet.contains(or))
      {
        overlaySet.remove(or);
      }
      return or;
    }
    return null;
  }
}
