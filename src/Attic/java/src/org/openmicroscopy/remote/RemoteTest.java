/*
 * org.openmicroscopy.remote.RemoteTest
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

package org.openmicroscopy.remote;

import org.openmicroscopy.*;

import java.net.URL;

public class RemoteTest
{
    public static void main(String[] args)
    {
        try
        {
            Class.forName("org.openmicroscopy.remote.RemoteSession");
            Class.forName("org.openmicroscopy.remote.RemoteFactory");
            Class.forName("org.openmicroscopy.remote.RemoteExperimenter");
        } catch (Exception e) {
            System.err.println(e);
            System.exit(0);
        }

        String urlString =
            (args.length > 0)?
            args[0]:
            "http://localhost:8002/";
        URL url = null;
        try
        {
            url = new URL(urlString);
        } catch (Exception e) {
            System.err.println(e);
            System.exit(1);
        }

        XmlRpcCaller  xmlRpcCaller = new XmlRpcCaller(url);
        xmlRpcCaller.login("dcreager"," ");
        RemoteObject.setRemoteCaller(xmlRpcCaller);

        Session  session = xmlRpcCaller.getSession();
        Factory  factory = session.getFactory();
        Experimenter experimenter = 
            (Experimenter) factory.loadObject("OME::Experimenter",1);
        System.out.println(experimenter.getFirstName()+" "+
                           experimenter.getLastName());
    }
}
