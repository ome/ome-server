/*
 * org.openmicroscopy.ds.PrimitiveConverters
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds;

public class PrimitiveConverters
{
    public static Short convertToShort(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Short)
            return (Short) o;
        else if (o instanceof Number)
            return new Short(((Number) o).shortValue());
        else if (o instanceof String) {
        		String s = (String) o;
        		if (s.length() == 0)
        			return null;
        		else return Short.valueOf(s);
        }
         
        else
            throw new NumberFormatException("Expected an int, got a "+
                                            o.getClass());

    }

    public static Integer convertToInteger(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Integer)
            return (Integer) o;
        else if (o instanceof Number)
            return new Integer(((Number) o).intValue());
        else if (o instanceof String) {
        	    String s = (String) o;
        	    if (s.length() == 0)
        	    		return null;
        	    else 
        	    		return Integer.valueOf(s);
        }
        else
            throw new NumberFormatException("Expected an int, got a "+
                                            o.getClass());

    }

    public static Long convertToLong(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Long)
            return (Long) o;
        else if (o instanceof Number)
            return new Long(((Number) o).longValue());
        else if (o instanceof String) {
        		String s = (String) o;
        		if (s.length() == 0)
        			return null;
        		else
        			return Long.valueOf(s);
        }
        else
            throw new NumberFormatException("Expected a long, got a "+
                                            o.getClass());

    }

    public static Float convertToFloat(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Float)
            return (Float) o;
        else if (o instanceof Number)
            return new Float(((Number) o).floatValue());
        else if (o instanceof String) {
        		String s = (String) o;
        		if (s.length() == 0)
        			return null;
        		else 
        			return Float.valueOf(s);
        }
            
        else
            throw new NumberFormatException("Expected a float, got a "+
                                            o.getClass());

    }

    public static Double convertToDouble(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Double)
            return (Double) o;
        else if (o instanceof Number)
            return new Double(((Number) o).doubleValue());
        else if (o instanceof String) {
        		String s = (String) o;
        		if (s.length() == 0)
        			return null;
        		else
        			return Double.valueOf(s);
        }
            
        else
            throw new NumberFormatException("Expected a double, got a "+
                                            o.getClass());

    }

    public static Boolean convertToBoolean(Object o)
        throws NumberFormatException
    {
        if (o == null)
            return null;
        else if (o instanceof Boolean)
            return (Boolean) o;
        else if (o instanceof Number)
            return new Boolean(((Number) o).intValue() != 0);
        else if (o instanceof String) {
            String s = (String) o;
            return new Boolean(
                s.equalsIgnoreCase("true") ||
                s.equalsIgnoreCase("t") ||
                s.equalsIgnoreCase("yes") ||
                s.equalsIgnoreCase("y") ||
                s.equalsIgnoreCase("1"));
        } else
            throw new NumberFormatException("Expected a boolean, got a "+
                                            o.getClass());

    }

}