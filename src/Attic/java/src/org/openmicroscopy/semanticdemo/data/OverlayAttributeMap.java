/*
 * org.openmicroscopy.semanticdemo.data.VisualizationAttributeMap
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

import org.openmicroscopy.Dataset;
import org.openmicroscopy.Factory;
import org.openmicroscopy.Feature;
import org.openmicroscopy.Image;
import org.openmicroscopy.SemanticType;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class OverlayAttributeMap extends AttributeMap
{

  public OverlayAttributeMap(Factory factory, Dataset dataset)
  {
    DBVisualizationFactory visFactory =
      DBVisualizationFactory.getInstance(factory);
    
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
    
    SemanticType[] datasetTypes = library.getDatasetTypes();
    
    List visualizations = visFactory.getVisualizations();
    
    for(int i=0;i<datasetTypes.length;i++)
    {
      for(int j=0;j<visualizations.size();j++)
      {
        Visualization v = (Visualization)visualizations.get(j);
        if(v.getSemanticType().equals(datasetTypes[i]))
        {
          if(v.getDisplayType() == Visualization.DisplayType.BOUNDS ||
             v.getDisplayType() == Visualization.DisplayType.POINT ||
             v.getDisplayType() == Visualization.DisplayType.LINE)
          {
            Map datasetMap = new HashMap();
            datasetMap.put("dataset_id",new Integer(dataset.getID()));
            List attributeList =
              factory.findAttributes(datasetTypes[i].getName(),datasetMap);
            typeMap.put(datasetTypes[i],attributeList);
            
            // break out
            j = visualizations.size();
          }
        }
      }
    }
  }
  
  public OverlayAttributeMap(Factory factory, Image image)
  {
    DBVisualizationFactory visFactory =
      DBVisualizationFactory.getInstance(factory);
  
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
  
    SemanticType[] imageTypes = library.getImageTypes();
  
    List visualizations = visFactory.getVisualizations();
  
    for(int i=0;i<imageTypes.length;i++)
    {
      for(int j=0;j<visualizations.size();j++)
      {
        Visualization v = (Visualization)visualizations.get(j);
        if(v.getSemanticType().equals(imageTypes[i]))
        {
          if(v.getDisplayType() == Visualization.DisplayType.BOUNDS ||
             v.getDisplayType() == Visualization.DisplayType.POINT ||
             v.getDisplayType() == Visualization.DisplayType.LINE)
          {
            Map imageMap = new HashMap();
            imageMap.put("image_id",new Integer(image.getID()));
            List attributeList =
              factory.findAttributes(imageTypes[i].getName(),imageMap);
            typeMap.put(imageTypes[i],attributeList);
          
            // break out
            j = visualizations.size();
          }
        }
      }
    }
  }
  
  public OverlayAttributeMap(Factory factory, Feature feature)
  {
    DBVisualizationFactory visFactory =
      DBVisualizationFactory.getInstance(factory);
  
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
  
    SemanticType[] featureTypes = library.getFeatureTypes();
  
    List visualizations = visFactory.getVisualizations();
  
    for(int i=0;i<featureTypes.length;i++)
    {
      for(int j=0;j<visualizations.size();j++)
      {
        Visualization v = (Visualization)visualizations.get(j);
        if(v.getSemanticType().equals(featureTypes[i]))
        {
          if(v.getDisplayType() == Visualization.DisplayType.BOUNDS ||
             v.getDisplayType() == Visualization.DisplayType.POINT ||
             v.getDisplayType() == Visualization.DisplayType.LINE)
          {
            Map datasetMap = new HashMap();
            datasetMap.put("feature_id",new Integer(feature.getID()));
            List attributeList =
              factory.findAttributes(featureTypes[i].getName(),datasetMap);
            typeMap.put(featureTypes[i],attributeList);
          
            // break out
            j = visualizations.size();
          }
        }
      }
    }
  }
}
