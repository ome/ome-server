/*
 * org.openmicroscopy.semanticdemo.data.DBVisualizationFactory
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
package org.openmicroscopy.semanticdemo.data;

import java.util.*;
import java.awt.Color;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Line2D;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import java.sql.*;

import org.openmicroscopy.Attribute;
import org.openmicroscopy.Factory;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.imageviewer.util.GrepOperator;
import org.openmicroscopy.semanticdemo.AnnotationFactory;
import org.openmicroscopy.semanticdemo.BasicOverlay;
import org.openmicroscopy.semanticdemo.OTFManager;
import org.openmicroscopy.semanticdemo.Orientation;
import org.openmicroscopy.semanticdemo.Overlay;
import org.openmicroscopy.semanticdemo.OverlayTypeFactory;
import org.openmicroscopy.semanticdemo.SemanticMethod;


/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class DBVisualizationFactory
{
  private Connection connection;
  private static DBVisualizationFactory dbFactory;
  private Factory omeFactory;
  private OTFManager overlayManager;
  
  
  
  private DBVisualizationFactory(Factory omeFactory)
  {
    this.omeFactory = omeFactory;
    try
    {
      Class.forName("org.postgresql.Driver");
      connection = DriverManager.getConnection("jdbc:postgresql:ome","ome","99boBotw");
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
  }
  
  public static DBVisualizationFactory getInstance(Factory omeFactory)
  {
    if(dbFactory == null)
    {
      dbFactory = new DBVisualizationFactory(omeFactory);
    }
    return dbFactory;
  }
  
  /**
   * Does the niceties.  Accesses the database a bunch, so this should
   * probably only be called once (perhaps this should be done at
   * initialization?)
   * 
   * @return
   */
  public OTFManager getDefaultOTFManager()
  {
    List list = getVisualizations();
    Visualization[] vs= new Visualization[list.size()];
    list.toArray(vs);
    OTFManager manager = createOverlayManager(vs);
    return manager;
  }
  
  public List getVisualizations()
  {
    List visualizations = new ArrayList();
    Statement statement = null;
    try
    {
      statement = connection.createStatement();
      ResultSet rs = statement.executeQuery("select * from visualizations");
      
      while(rs.next())
      {
        int ID = rs.getInt("vis_id");
        int semanticTypeID = rs.getInt("semantic_type_id");
        String objectType = rs.getString("ome_type");
        String displayType = rs.getString("vis_type");
        
        Visualization vis = new Visualization(ID);
        if(semanticTypeID != 0)
        {
          Map idMap = new HashMap();
          idMap.put("id",new Integer(semanticTypeID));
          SemanticType type =
            (SemanticType)omeFactory.findObject("OME::SemanticType",idMap);
          vis.setSemanticType(type);
        }
        else
        {
          vis.setObjectType(objectType);
        }
        
        if(displayType.equalsIgnoreCase("annotation"))
        {
          vis.setDisplayType(Visualization.DisplayType.ANNOTATION);
        }
        else if(displayType.equalsIgnoreCase("point"))
        {
          vis.setDisplayType(Visualization.DisplayType.POINT);
        }
        else if(displayType.equalsIgnoreCase("bounds"))
        {
          vis.setDisplayType(Visualization.DisplayType.BOUNDS);
        }
        else if(displayType.equalsIgnoreCase("line"))
        {
          vis.setDisplayType(Visualization.DisplayType.LINE);
        }
        
        visualizations.add(vis);
      }
      return visualizations;
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
    finally
    {
      try
      {
        statement.close();
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }
    }
    return visualizations;
  }
  
  public AnnotationFactory getAnnotationFactory(Visualization v)
  {
    return null;
  }
  
  public OTFManager createOverlayManager(Visualization[] vs)
  {
    OTFManager manager = new OTFManager();
    if(vs == null || vs.length == 0)
    {
      return manager;
    }
    for(int i=0;i<vs.length;i++)
    {
      OverlayTypeFactory otf = getOverlayFactory(vs[i]);
      // ignore constraint filters for now
      manager.generateByType(vs[i].getSemanticType(),otf);
    }
    return manager;
  }
  
  public OverlayTypeFactory getOverlayFactory(Visualization v)
  {
    int ID = v.getID();
    Statement statement = null;
    try
    {
      statement = connection.createStatement();
      ResultSet baseRule =
        statement.executeQuery("select * from overlays where vis_id = " + ID);
      
      // gonna hope that the invariant on one rule works
      OverlayTypeFactory.Method method = null;
      
      final OverlayInfo overlayInfo = new OverlayInfo();
      
      if(baseRule.next())
      {
        overlayInfo.setTextSource(baseRule.getString("txt_src"));
        StringTokenizer xTok = new StringTokenizer(baseRule.getString("x_srcs"),",");
        
        List xSrcList = new ArrayList();
        while(xTok.hasMoreTokens())
        {
          String src = xTok.nextToken();
          xSrcList.add(src);
        }
        String[] xStrings = new String[xSrcList.size()];
        xSrcList.toArray(xStrings);
        
        StringTokenizer yTok = new StringTokenizer(baseRule.getString("y_srcs"),",");
        
        List ySrcList = new ArrayList();
        while(yTok.hasMoreTokens())
        {
          String src = yTok.nextToken();
          ySrcList.add(src);
        }
        String[] yStrings = new String[ySrcList.size()];
        ySrcList.toArray(yStrings);
        
        boolean scaling = baseRule.getBoolean("scales");
        String orString = baseRule.getString("orientation");
        Orientation orientation = Orientation.getStringInstance(orString);
        
        overlayInfo.setScales(scaling);
        overlayInfo.setOrientation(orientation);
        overlayInfo.setXSources(xStrings);
        overlayInfo.setYSources(yStrings);
        
        // convert orientation string to actual object
        
        if(v.isSemantic())
        {
          final SemanticType type = v.getSemanticType();
          Visualization.DisplayType displayType = v.getDisplayType();
          
          if(displayType == Visualization.DisplayType.POINT)
          {
            method = new SemanticMethod() {
              
              public Overlay generateOverlay(Object dataPoint)
              {
                if(!isApplicable(dataPoint,type))
                {
                  return null;
                }
                Attribute attribute = (Attribute)dataPoint;
                String xSrc = overlayInfo.getXSources()[0];
                String ySrc = overlayInfo.getYSources()[0];
                
                double x = attribute.getDoubleElement(xSrc);
                double y = attribute.getDoubleElement(ySrc);
                
                System.err.println("x="+x+",y="+y);
                
                // going with default circle for point (demo)
                Overlay overlay = new BasicOverlay(new Ellipse2D.Double(0,0,5,5));
                overlay.setFillColor(Color.red);
                overlay.setOutlineColor(Color.black);
                overlay.setAbsolutePoint(new Point2D.Double(x,y));
                overlay.setOrientation(overlayInfo.getOrientation());
                overlay.setScaling(overlayInfo.isScales());
                
                return overlay;
              }

            };
          }
          else if(displayType == Visualization.DisplayType.BOUNDS)
          {
            method = new SemanticMethod() {
  
              public Overlay generateOverlay(Object dataPoint)
              {
                if(!isApplicable(dataPoint,type))
                {
                  return null;
                }
                Attribute attribute = (Attribute)dataPoint;
                String xSrc = overlayInfo.getXSources()[0];
                String ySrc = overlayInfo.getYSources()[0];
                String wSrc = overlayInfo.getXSources()[1];
                String hSrc = overlayInfo.getYSources()[1];
    
                double x = attribute.getDoubleElement(xSrc);
                double y = attribute.getDoubleElement(ySrc);
                double w = attribute.getDoubleElement(wSrc);
                double h = attribute.getDoubleElement(hSrc);
    
                // going with default circle for point (demo)
                Overlay overlay = new BasicOverlay(new Rectangle2D.Double(0,0,w,h));
                overlay.setFillColor(new Color(0,0,255,64));
                overlay.setOutlineColor(Color.black);
                overlay.setAbsolutePoint(new Point2D.Double(x,y));
                overlay.setOrientation(overlayInfo.getOrientation());
                overlay.setScaling(true); // override
    
                return overlay;
              }

            };
          }
          else if(displayType == Visualization.DisplayType.LINE)
          {
            method = new SemanticMethod() {
  
              public Overlay generateOverlay(Object dataPoint)
              {
                if(!isApplicable(dataPoint,type))
                {
                  return null;
                }
                Attribute attribute = (Attribute)dataPoint;
                String x1Src = overlayInfo.getXSources()[0];
                String y1Src = overlayInfo.getYSources()[0];
                String x2Src = overlayInfo.getXSources()[1];
                String y2Src = overlayInfo.getYSources()[1];
    
                double x1 = attribute.getDoubleElement(x1Src);
                double y1 = attribute.getDoubleElement(y1Src);
                double x2 = attribute.getDoubleElement(x2Src);
                double y2 = attribute.getDoubleElement(y2Src);
    
                // going with default circle for point (demo)
                Overlay overlay =
                  new BasicOverlay(new Line2D.Double(0,0,x2-x1,y2-y1));
                overlay.setFillColor(Color.red);
                overlay.setOutlineColor(Color.green);
                overlay.setAbsolutePoint(new Point2D.Double(x1,y1));
                
                // ignore for now (line)
                overlay.setOrientation(Orientation.NW);
                overlay.setScaling(overlayInfo.isScales());
    
                return overlay;
              }

            };
          }
          else
          {  
            method = null;
          }
        }
        else if(v.isObjective())
        {
          // don't do anything yet.  abstraction not yet clear.
        }
      }
      return new OverlayTypeFactory(method);
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
    finally
    {
      try
      {
        statement.close();
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }
    }
    return null;
  }
  
  public List getConstraints(int visualizationID)
  {
    // do nothing yet... base case is just to display it
    // add later
    List constraints = new ArrayList();
    return constraints;
  }
  
  public void finalize()
  {
    try
    {
      connection.close();
      connection = null;
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
  }
}
