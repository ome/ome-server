/*
 * org.openmicroscopy.browser.tests.DataAttributeTest
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
package org.openmicroscopy.browser.tests;

import java.util.List;

import org.openmicroscopy.browser.datamodel.DataAttribute;
import org.openmicroscopy.browser.datamodel.DataElementType;

import junit.framework.TestCase;

/**
 * Test cases for DataAttribute (this needs to be right, just about everything
 * else can go down the tube)
 * 
 * TODO: complete this (later)
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version 2.2
 * @since 2.2
 */
public class DataAttributeTest extends TestCase
{
  private DataAttribute testAttribute;
  /**
   * Constructor for DataAttributeTest.
   * @param arg0
   */
  public DataAttributeTest(String arg0)
  {
    super(arg0);
  }
  

  public static void main(String[] args)
  {
    junit.swingui.TestRunner.run(DataAttributeTest.class);
  }

  public void testDataAttribute()
  {
    DataAttribute attribute = new DataAttribute("mom");
    assertNotNull(attribute);
    assertEquals(0,attribute.getElementNames().size());
    assertEquals(attribute.getAttributeName(),"mom");
    
    boolean caught = false;
    try
    {
      DataAttribute nullAttribute = new DataAttribute(null);
    }
    catch(IllegalArgumentException e)
    {
      caught = true;
    }
    assertTrue(caught);
  }

  public void testGetElementNames()
  {
    DataAttribute attribute = new DataAttribute("test");
    assertTrue(attribute.defineElement("bollocks",DataElementType.STRING));
    assertTrue(attribute.defineElement("element2",DataElementType.STRING));
    assertTrue(attribute.defineElement("element3",DataElementType.STRING));
    
    List elementList = attribute.getElementNames();
    assertEquals(3,elementList.size());
    String firstElement = (String)elementList.get(0);
    String secondElement = (String)elementList.get(1);
    String thirdElement = (String)elementList.get(2);
    
    assertEquals("bollocks",firstElement);
    assertEquals("element2",secondElement);
    assertEquals("element3",thirdElement);
  }

  public void testGetAttributeName()
  {
    DataAttribute attribute = new DataAttribute("test");
    assertEquals("test",attribute.getAttributeName());
  }

  public void testGetElementType()
  {
    DataAttribute attribute = new DataAttribute("test");
    attribute.defineElement("int",DataElementType.INT);
    attribute.defineElement("double",DataElementType.DOUBLE);
    attribute.defineElement("float",DataElementType.FLOAT);
    attribute.defineElement("string",DataElementType.STRING);
    attribute.defineElement("long",DataElementType.LONG);
    attribute.defineElement("bool",DataElementType.BOOLEAN);
    attribute.defineElement("obj",DataElementType.OBJECT);
    attribute.defineElement("attr",DataElementType.ATTRIBUTE);
    
    assertEquals(DataElementType.INT,attribute.getElementType("int"));
    assertEquals(DataElementType.DOUBLE,attribute.getElementType("double"));
    assertEquals(DataElementType.FLOAT,attribute.getElementType("float"));
    assertEquals(DataElementType.LONG,attribute.getElementType("long"));
    assertEquals(DataElementType.STRING,attribute.getElementType("string"));
    assertEquals(DataElementType.BOOLEAN,attribute.getElementType("bool"));
    assertEquals(DataElementType.OBJECT,attribute.getElementType("obj"));
    assertEquals(DataElementType.ATTRIBUTE,attribute.getElementType("attr"));
  }

  public void testGetElement()
  {
  }

  public void testGetObjectElement()
  {
  }

  public void testSetObjectElement()
  {
  }

  public void testGetIntElement()
  {
  }

  public void testSetIntElement()
  {
  }

  public void testGetFloatElement()
  {
  }

  public void testSetFloatElement()
  {
  }

  public void testGetLongElement()
  {
  }

  public void testSetLongElement()
  {
  }

  public void testGetDoubleElement()
  {
  }

  public void testSetDoubleElement()
  {
  }

  public void testGetBooleanElement()
  {
  }

  public void testSetBooleanElement()
  {
  }

  public void testGetStringElement()
  {
  }

  public void testSetStringElement()
  {
  }

  public void testGetAttributeElement()
  {
  }

  public void testSetAttributeElement()
  {
  }

  public void testDefineElement()
  {
  }

  public void testSetElementNull()
  {
  }

}
