/*
 * org.openmicroscopy.semanticdemo.OTFManager
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

import java.util.*;

import org.openmicroscopy.Attribute;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.imageviewer.util.GrepOperator;

/**
 * NOTE: I haven't worked out what happens when two conditions pass.  For now,
 * it's going to be non-deterministic (except for all)
 * 
 * This probably works best if you have groups of objects to be lumped
 * together logically and then get a factory for-- that's why I'm not including
 * a getOverlay method.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class OTFManager
{
  private Map factoryMap;
  
  /**
   * A dummy comparator that says "true" for all objects except the null
   * object.
   */
  private static final GrepOperator all = new GrepOperator() {
    /* (non-Javadoc)
     * @see org.openmicroscopy.imageviewer.util.GrepOperator#eval(java.lang.Object)
     */
    public boolean eval(Object o)
    {
      if(o == null)
      {
        return false;
      }
      else return true;
    }
  };
    
  public OTFManager()
  {
    factoryMap = new HashMap();
  }
  
  private void generateWithoutCondition(Object theKey,
                                        OverlayTypeFactory theFactory)
  {
    if(theKey == null)
    {
      return;
    }
    if(theFactory == null)
    {
      if(factoryMap.containsKey(theKey))
      {
        factoryMap.remove(theKey);
      }
    }
    IdentityHashMap conditionMap = new IdentityHashMap();
    conditionMap.put(all,theFactory);
    factoryMap.put(theKey,conditionMap);
  }
  
  private void generateWithCondition(Object theKey,
                                     GrepOperator condition,
                                     OverlayTypeFactory theFactory)
  {
    if(theKey == null || condition == null)
    {
      return;
    }

    if(theFactory == null)
    {
      // take out matched condition, unless class not in map
      if(!factoryMap.containsKey(theKey))
      {
        return;
      }
      IdentityHashMap conditionMap =
        (IdentityHashMap)factoryMap.get(theKey);
  
      conditionMap.remove(condition);
    }

    if(!factoryMap.containsKey(theKey))
    {
      IdentityHashMap conditionMap = new IdentityHashMap();
      conditionMap.put(condition,theFactory);
      factoryMap.put(theKey,conditionMap);
    }

    IdentityHashMap conditionMap =
      (IdentityHashMap)factoryMap.get(theKey);
    conditionMap.put(condition,theFactory);
  }
  
  /**
   * Maps a particular Overlay factory to a particular class.  Adds a
   * default condition if only specific criteria have been mapped
   * to a class.
   * 
   * @param theClass
   * @param theFactory
   */
  public void generateByClass(Class theClass,
                              OverlayTypeFactory theFactory)
  {
    generateWithoutCondition(theClass,theFactory);
  }
  
  /**
   * Maps a particular Overlay factory to a particular semantic type.
   * Adds a default condition if only specific criteria have been mapped
   * to a class.
   * 
   * @param theClass
   * @param condition
   * @param theFactory
   */
  public void generateByType(SemanticType theType,
                             OverlayTypeFactory theFactory)
  {
    generateWithoutCondition(theType,theFactory);
  }
  
  /**
   * Maps a particular Overlay factory to a particular class, given
   * a particular condition.  You can support multiple classes by their
   * respective supertype, although this may be tricky and introduce
   * some issues (especially if two classes' lowest common denominator is
   * java.lang.Object)
   * 
   * @param theClass
   * @param condition
   * @param theFactory
   */
  public void generateByClassIf(Class theClass,
                                GrepOperator condition,
                                OverlayTypeFactory theFactory)
  {
    generateWithCondition(theClass,condition,theFactory);
  }
  
  /**
   * Maps a particular Overlay factory to a particular semantic type,
   * given a particular condition.  No multiple inheritance/classes
   * allowed here, not until there is semantic type inheritance.
   * 
   * @param theType
   * @param condition
   * @param theFactory
   */
  public void generateByTypeIf(SemanticType theType,
                               GrepOperator condition,
                               OverlayTypeFactory theFactory)
  {
    generateWithCondition(theType,condition,theFactory);
  }
  
  /**
   * NOTE: This might be nondeterministic when called repeatedly (relies on
   * the nondeterminism of getOverlayFactory).  Needs some sort of
   * prototype fix, I believe.  In other words, WARNING: may suck right now.
   * 
   * @param object The object to generate the Overlay for.
   * @return An overlay.  Yup.
   */
  public Overlay getOverlay(Object object)
  {
    return getOverlayFactory(object).generateOverlay(object);
  }
  
  private OverlayTypeFactory
    getOverlayFactoryByCondition(Object prototype,
                                 IdentityHashMap conditionMap)
  {
    boolean allIn = false;
    for(Iterator iter = conditionMap.keySet().iterator(); iter.hasNext();)
    {
      GrepOperator condition = (GrepOperator)iter.next();
      if(condition == all)
      {
        allIn = true;
        continue;
      }
      if(condition.eval(prototype))
      {
        return (OverlayTypeFactory)conditionMap.get(condition);
      }
    }
    if(allIn = true)
    {
      return (OverlayTypeFactory)conditionMap.get(all);
    }
    return null;
  }
  
  /**
   * Returns the factory that generates overlays for this semantic type.
   * 
   * @param type
   * @return
   */
  private IdentityHashMap getConditionMapByType(SemanticType type)
  {
    if(type == null)
    {
      return null;
    }
    if(factoryMap.containsKey(type))
    {
      return (IdentityHashMap)factoryMap.get(type);
    }
    else return null;
  }
  
  /**
   * Returns the factory that generates overlays for attributes of this
   * semantic type.
   * 
   * @param attribute
   * @return
   */
  private IdentityHashMap getConditionMapByAttribute(Attribute attribute)
  {
    return getConditionMapByType(attribute.getSemanticType());
  }
  
  /**
   * Recommended way for getting a type factory and then subsequently
   * rendering overlays based on new data.
   * 
   * @param prototype The prototype of the object.  WARNING: Might be the
   * wrong abstraction, as maybe a Class or Interface should be specified.
   * Instead, this method attempts to guess based on the class/interface
   * hierarchy of the object.  That introduces some nondeterminism, along
   * with the fact that an object could pass multiple conditions, whose
   * order is not internally consistent.
   * 
   * @return A factory for generating overlays for objects of this type
   *         or that meet the criteria specified by the object.
   */
  public OverlayTypeFactory getOverlayFactory(Object prototype)
  {
    if(prototype == null)
    {
      // no overlay for you
      return null;
    }
    
    // check by semantic type/attribute first (no inheritance)
    if(prototype instanceof Attribute)
    {
      Attribute attribute = (Attribute)prototype;
      IdentityHashMap conditionMap =
        getConditionMapByAttribute(attribute);
      return getOverlayFactoryByCondition(attribute,conditionMap);
    }
    else if(prototype instanceof SemanticType)
    {
      SemanticType type = (SemanticType)prototype;
      IdentityHashMap conditionMap =
        getConditionMapByType(type);
      return getOverlayFactoryByCondition(type,conditionMap);
    }
    
    // resort to default after all conditions tested
    boolean classTreeExhausted = false;
      
    // OK, here's the nondeterministic part which could be fixed with
    // some sort of priority.  Unfortunately, a LinkedHashMap
    // (predictable iteration) != an IdentityHashMap (reference equality)
    // so, I guess I could make a LinkedIdentityHashMap, but the initial
    // seeding on that would be arbitrary.  So I think some sort of
    // priority system is in order.  Maybe.  For now, nondeterminism.
    // Works great for finite automata and quantum physics.
    
    Class baseClass = prototype.getClass();
    Class realClass = prototype.getClass();
    Iterator ifaceIter = Arrays.asList(realClass.getInterfaces()).iterator();
    
    while(!classTreeExhausted)
    {
      boolean allIn = true;
      if(!factoryMap.containsKey(realClass))
      {
        if(realClass.equals(Object.class))
        {
          classTreeExhausted = true;
        }
        
        if(!ifaceIter.hasNext())
        {
          realClass = baseClass.getSuperclass();
          baseClass = realClass;
          ifaceIter = Arrays.asList(realClass.getInterfaces()).iterator();
          continue;
        }
        else
        {
          realClass = (Class)ifaceIter.next();
          continue;
        }
      }
      
      //guarantee to have a match down here (I think)
      IdentityHashMap conditionMap =
        (IdentityHashMap)factoryMap.get(realClass);
        
      OverlayTypeFactory factory =
        getOverlayFactoryByCondition(prototype,conditionMap);
      
      // found a match
      if(factory != null)
      {
        return factory;
      }
      
      // no conditions/classes found
      if(!ifaceIter.hasNext())
      {
        realClass = baseClass.getSuperclass();
        baseClass = realClass;
        ifaceIter = Arrays.asList(realClass.getInterfaces()).iterator();
        continue;
      }
      else
      {
        realClass = (Class)ifaceIter.next();
        continue;
      }
    }
    return null;
  }
}
