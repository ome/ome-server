/*
 * org.openmicroscopy.remote.RemoteAttribute
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.remote;

import org.openmicroscopy.*;

public class RemoteAttribute
    extends RemoteObject
    implements Attribute
{
    static
    {
        RemoteObjectCache.addClass("OME::SemanticType::Superclass",
                                   RemoteAttribute.class);
    }

    public RemoteAttribute() { super(); }
    public RemoteAttribute(RemoteSession session, String reference)
    { super(session,reference); }


    public int getID()
    { return ((Integer) caller.dispatch(this,"id")).intValue(); }

    public void writeObject() 
    { caller.dispatch(this,"writeObject"); }

    public Session getSession()
    { return (Session)
            getRemoteElement("OME::Session",
                             "Session"); }

    public SemanticType getSemanticType()
    { return (SemanticType)
            getRemoteElement("OME::SemanticType",
                             "semantic_type"); }

    public ModuleExecution getModuleExecution()
    { return (ModuleExecution)
            getRemoteElement("OME::ModuleExecution",
                             "module_execution"); }

    public OMEObject getTarget()
    {
        SemanticType type = getSemanticType();
        int granularity = type.getGranularity();
        String remoteClass = null;
        if (granularity == Granularity.GLOBAL)
            return null;
        else if (granularity == Granularity.DATASET)
            remoteClass = "OME::Dataset";
        else if (granularity == Granularity.IMAGE)
            remoteClass = "OME::Image";
        else if (granularity == Granularity.FEATURE)
            remoteClass = "OME::Feature";
        else
            return null;
        return (OMEObject)
            getRemoteElement(remoteClass,"target");
    }

    public Dataset getDataset()
    { return (Dataset) getTarget(); }
    public Image getImage()
    { return (Image) getTarget(); }
    public Feature getFeature()
    { return (Feature) getTarget(); }

    public void verifySemanticType(SemanticType type)
    { verifySemanticType(type.getName()); }

    public void verifySemanticType(String typeName)
    {
        SemanticType myType = getSemanticType();
        if (!myType.getName().equals(typeName))
            throw new ClassCastException(this+" is not of type "+typeName);
    }

    public boolean getBooleanElement(String element)
    { return super.getBooleanElement(element); }
    public void setBooleanElement(String element, boolean value)
    { super.setBooleanElement(element,value); }

    public int getIntElement(String element)
    { return super.getIntElement(element); }
    public void setIntElement(String element, int value)
    { super.setIntElement(element,value); }

    public long getLongElement(String element)
    { return super.getLongElement(element); }
    public void setLongElement(String element, long value)
    { super.setLongElement(element,value); }

    public float getFloatElement(String element)
    { return super.getFloatElement(element); }
    public void setFloatElement(String element, float value)
    { super.setFloatElement(element,value); }

    public double getDoubleElement(String element)
    { return super.getDoubleElement(element); }
    public void setDoubleElement(String element, double value)
    { super.setDoubleElement(element,value); }

    public String getStringElement(String element)
    { return super.getStringElement(element); }
    public void setStringElement(String element, String value)
    { super.setStringElement(element,value); }

    public Object getObjectElement(String element)
    { return super.getObjectElement(element); }
    public void setObjectElement(String element, Object value)
    { super.setObjectElement(element,value); }

    public Attribute getAttributeElement(String element)
    { return super.getAttributeElement(element); }
    public void setAttributeElement(String element, Attribute value)
    { super.setAttributeElement(element,value); }

}
