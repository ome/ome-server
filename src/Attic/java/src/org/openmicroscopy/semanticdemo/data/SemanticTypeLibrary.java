/*
 * org.openmicroscopy.semanticdemo.data.SemanticTypeLibrary
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

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmicroscopy.Factory;
import org.openmicroscopy.SemanticType;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class SemanticTypeLibrary
{
  private static Map factoryMap;
  
  private Set globalTypeSet;
  private Set datasetTypeSet;
  private Set imageTypeSet;
  private Set featureTypeSet;
  
  private SemanticTypeLibrary(Factory factory)
  {
    globalTypeSet = new HashSet();
    datasetTypeSet = new HashSet();
    imageTypeSet = new HashSet();
    featureTypeSet = new HashSet();
    
    System.err.println("initializing library..");
    
    if(factory == null)
    {
      return;
    }
    
    factoryMap.put(factory,this);
    
    Map granMap = new HashMap();
    granMap.put("granularity","G");
    
    List globalTypes = factory.findObjects("OME::SemanticType",granMap);
    for(Iterator iter = globalTypes.iterator(); iter.hasNext();)
    {
      SemanticType type = (SemanticType)iter.next();
      globalTypeSet.add(type);
    }
    
    granMap.put("granularity","D");
    List datasetTypes = factory.findObjects("OME::SemanticType",granMap);
    for(Iterator iter = datasetTypes.iterator(); iter.hasNext();)
    {
      SemanticType type = (SemanticType)iter.next();
      datasetTypeSet.add(type);
    }
    
    granMap.put("granularity","I");
    List imageTypes = factory.findObjects("OME::SemanticType",granMap);
    for(Iterator iter = imageTypes.iterator(); iter.hasNext();)
    {
      SemanticType type = (SemanticType)iter.next();
      imageTypeSet.add(type);
    }
    
    granMap.put("granularity","F");
    List featureTypes = factory.findObjects("OME::SemanticType",granMap);
    for(Iterator iter = featureTypes.iterator(); iter.hasNext();)
    {
      SemanticType type = (SemanticType)iter.next();
      featureTypeSet.add(type);
    }
  }
  
  /**
   * Gets an instance of a semantic type library given a factory.
   * @param factory
   * @return
   */
  public static SemanticTypeLibrary getInstance(Factory factory)
  {
    if(factory == null)
    {
      return null;
    }
    
    if(factoryMap == null)
    {
      factoryMap = new HashMap();
    }
    
    if(factoryMap.containsKey(factory))
    {
      return (SemanticTypeLibrary)factoryMap.get(factory);
    }
    else
    {
      SemanticTypeLibrary library = new SemanticTypeLibrary(factory);
      factoryMap.put(factory,library);
      return library;
    }
  }
  
  public SemanticType[] getGlobalTypes()
  {
    SemanticType[] types = new SemanticType[globalTypeSet.size()];
    globalTypeSet.toArray(types);
    return types;
  }
  
  public SemanticType[] getDatasetTypes()
  {
    SemanticType[] types = new SemanticType[datasetTypeSet.size()];
    datasetTypeSet.toArray(types);
    return types;
  }
  
  public SemanticType[] getImageTypes()
  {
    SemanticType[] types = new SemanticType[imageTypeSet.size()];
    imageTypeSet.toArray(types);
    return types;
  }
  
  public SemanticType[] getFeatureTypes()
  {
    SemanticType[] types = new SemanticType[featureTypeSet.size()];
    featureTypeSet.toArray(types);
    return types;
  }
}
