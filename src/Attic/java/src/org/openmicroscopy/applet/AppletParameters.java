/*
 * org.openmicroscopy.applet.AppletParameters
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




package org.openmicroscopy.applet;

import java.applet.*;
import java.util.Map;
import java.util.HashMap;

public class AppletParameters
{
    protected Applet applet;
    protected Map    savedObjects = new HashMap();

    public AppletParameters(Applet applet)
    {
        this.applet = applet;
    }

    public void saveObject(String type, String name, Object object)
    {
        savedObjects.put(type+"/"+name,object);
    }

    public Object getSavedObject(String type, String name)
    {
        return savedObjects.get(type+"/"+name);
    }

    protected String getParam(String name, boolean allowNull)
    {
        String param = applet.getParameter(name);
        if ((param == null) && (!allowNull))
            throw new IllegalArgumentException("Applet parameter "+name+
                                               " cannot be null");
        return param;
    }

    public String getStringParameter(String name)
    {
        return getStringParameter(name,true);
    }

    public String getStringParameter(String name, boolean allowNull)
    {
        return getStringParameter(name,allowNull,"");
    }

    public String getStringParameter(String  name,
                                     boolean allowNull,
                                     String  def)
    {
        String param = getParam(name,allowNull);

        if (param == null)
            return def;

        return param;
    }

    public int getIntParameter(String name)
    {
        return getIntParameter(name,true);
    }

    public int getIntParameter(String name, boolean allowNull)
    {
        return getIntParameter(name,allowNull,0);
    }

    public int getIntParameter(String name, boolean allowNull, int def)
    {
        String param = getParam(name,allowNull);

        if (param == null)
            return def;

        return Integer.parseInt(param);
    }

    public boolean getBooleanParameter(String name)
    {
        return getBooleanParameter(name,true);
    }

    public boolean getBooleanParameter(String name, boolean allowNull)
    {
        return getBooleanParameter(name,allowNull,false);
    }

    public boolean getBooleanParameter(String  name,
                                       boolean allowNull,
                                       boolean def)
    {
        String param = getParam(name,allowNull);

        if (param == null)
            return def;

        return 
            param.equalsIgnoreCase("true") ||
            param.equalsIgnoreCase("t") ||
            param.equalsIgnoreCase("yes") ||
            param.equalsIgnoreCase("y") ||
            param.equalsIgnoreCase("1");
    }

    public Object getObjectParameter(String type, String name)
    {
        return getObjectParameter(type,name,true);
    }

    public Object getObjectParameter(String type, String name, boolean allowNull)
    {
        return getObjectParameter(type,name,allowNull,null);
    }

    public Object getObjectParameter(String  type,
                                     String  name,
                                     boolean allowNull,
                                     Object  def)
    {
        String param = getParam(name,allowNull);

        if (param == null)
            return def;

        Object object = getSavedObject(type,param);
        if ((object == null) && (!allowNull))
            throw new IllegalArgumentException("Applet parameter "+name+
                                               " hasn't been loaded yet!");
        return object;
    }
}
