/*
 * org.openmicroscopy.soap.SoapTest
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy.soap;

import org.apache.axis.client.Call;
import org.apache.axis.client.Service;
import javax.xml.namespace.QName;
import java.net.URL;

import java.util.*;

import org.apache.log4j.Logger;
import org.apache.log4j.Level;
import org.apache.log4j.BasicConfigurator;

public class SoapTest
{
    static Logger logger = Logger.getLogger(SoapTest.class);

    static Service service;
    static Call    call;

    static Object invoke(String method, Object[] params)
    {
        try
        {
            System.err.println("*** "+method);
            logger.info("Setting operation name");
            call.setOperationName(new QName("OME/Remote/Dispatcher",
                                            method));
            logger.info("Invoking method");
            Object retval = call.invoke(params);

            logger.info("Printing return value");
            System.out.println(retval);
            System.out.println(retval.getClass());

            return retval;
        } catch (Exception e) {
            System.err.println(e.toString());
        }
        return null;
    }

    public static void main(String[] args)
    {
        BasicConfigurator.configure();
        logger.setLevel((Level) Level.WARN);

        try
        {
            String  urlString =
                (args.length > 0)?
                args[0]:
                "http://localhost/soap/SOAP.pl";

            URL  url = new URL(urlString);

            service = new Service();
            call = (Call) service.createCall();

            logger.info("Setting endpoint address");
            call.setTargetEndpointAddress(url);

            Map map = new HashMap();
            map.put("A",new Integer(1));
            map.put("B",new Integer(2));
            map.put("C",new Integer(3));

            Object version = invoke("versionInfo",new Object[] {map});
            /*
            Object session = invoke("createSession",new Object[] {"dcreager"," "});
            Object factory = invoke("dispatch",
                                    new Object[] {session,session,"Factory"});
            Object program = invoke("dispatch",
                                    new Object[] {session,factory,
                                                  "loadObject",
                                                  "OME::Project",
                                                  new Integer(1)});
            Object name = invoke("dispatch",
                                 new Object[] {session,program,"name"});
            invoke("dispatch",
                   new Object[] {session,program,"name","Test"});
            invoke("dispatch",new Object[] {session,program,"writeObject"});
            invoke("closeSession",new Object[] {session});
            */
        } catch (Exception e) {
            System.err.println(e.toString());
        }
    }
}
