/*
 * org.openmicroscopy.semanticdemo.data.AttributeMap
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

import org.openmicroscopy.Attribute;
import org.openmicroscopy.Dataset;
import org.openmicroscopy.Factory;
import org.openmicroscopy.Feature;
import org.openmicroscopy.Image;
import org.openmicroscopy.SemanticType;

import java.util.*;

/**
 * Specifies loading attributes at once. Should there be a lazy version?
 * I guess if you want lazy, you should just use the SemanticTypeLibrary
 * directly and use Factory to load by SemanticType.  This just eats it.
 * Mmmmm.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class AttributeMap
{
  protected Map typeMap;
  
  protected AttributeMap()
  {
    // do nothing
  }
  
  /**
   * Finds all semantic information in the database pertaining to the
   * specified dataset.
   * 
   * @param factory
   * @param dataset
   */
  public AttributeMap(Factory factory, Dataset dataset)
  {
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
    
    SemanticType[] types = library.getDatasetTypes();
    
    Map imageMap = new HashMap();
    // does this have to be consistent?
    imageMap.put("dataset_id",new Integer(dataset.getID()));
    for(int i=0;i<types.length;i++)
    {
      List attributeList = factory.findAttributes(types[i].getName(),imageMap);
      typeMap.put(types[i],attributeList);
    }
  }
  
  /**
   * Finds all semantic information in the database pertaining to the
   * specified image. (this could be problematic re: pixels)
   * 
   * @param factory
   * @param image
   */
  public AttributeMap(Factory factory, Image image)
  {
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
    
    SemanticType[] types = library.getImageTypes();
    
    Map imageMap = new HashMap();
    // does this have to be consistent?
    imageMap.put("image_id",new Integer(image.getID()));
    for(int i=0;i<types.length;i++)
    {
      List attributeList = factory.findAttributes(types[i].getName(),imageMap);
      typeMap.put(types[i],attributeList);
    }
  }
  
  /**
   * Finds all semantic information in the database pertaining to
   * the specified feature.
   * 
   * @param factory
   * @param feature
   */
  public AttributeMap(Factory factory, Feature feature)
  {
    SemanticTypeLibrary library = SemanticTypeLibrary.getInstance(factory);
    typeMap = new HashMap();
    
    SemanticType[] types = library.getFeatureTypes();
    
    Map imageMap = new HashMap();
    // does this have to be consistent?
    imageMap.put("feature_id",new Integer(feature.getID()));
    for(int i=0;i<types.length;i++)
    {
      List attributeList = factory.findAttributes(types[i].getName(),imageMap);
      typeMap.put(types[i],attributeList);
    }
  }
  
  public Attribute[] getAttributesByType(SemanticType type)
  {
    if(typeMap.containsKey(type))
    {
      List attributesList = (List)typeMap.get(type);
      Attribute[] attributes = new Attribute[attributesList.size()];
      attributesList.toArray(attributes);
      return attributes;
    }
    else return null;
  }
  
  public SemanticType[] getSupportedTypes()
  {
    List keyList = new ArrayList(typeMap.keySet());
    Collections.sort(keyList,new SemanticTypeComparator());
    SemanticType[] types = new SemanticType[keyList.size()];
    keyList.toArray(types);
    return types;
  }
  
  private class SemanticTypeComparator implements Comparator
  {
    /* (non-Javadoc)
     * @see java.util.Comparator#compare(java.lang.Object, java.lang.Object)
     */
    public int compare(Object o1, Object o2)
    {
      if(o1 == null)
      {
        return -1;
      }
      if(o2 == null)
      {
        return 1;
      }
      if(!(o1 instanceof SemanticType))
      {
        return -1;
      }
      if(!(o2 instanceof SemanticType))
      {
        return 1;
      }
      SemanticType st1 = (SemanticType)o1;
      SemanticType st2 = (SemanticType)o2;
      
      return st1.getName().compareTo(st2.getName());
    }
    
    public boolean equals(Object o)
    {
      return compare(this,o) == 0;
    }

  }
}
