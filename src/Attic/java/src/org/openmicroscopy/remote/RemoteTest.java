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
import java.io.*;
import java.util.*;

public class RemoteTest
{
    public static void main(String[] args)
    {
        String urlString =
            (args.length > 0)?
            args[0]:
            "http://localhost:8002/";
        RemoteBindings  bindings = null;

        BufferedReader in =
            new BufferedReader(new InputStreamReader(System.in));

        try
        {
            System.out.print("Username? ");
            String username = in.readLine();
        
            System.out.print("Password? ");
            String password = in.readLine();

            bindings = new RemoteBindings();
            bindings.loginXMLRPC(urlString,username,password);
        } catch (Exception e) {
            System.err.println(e);
            System.exit(1);
        }

        Session  session = bindings.getSession();
        Factory  factory = bindings.getFactory();

        Project project = (Project) factory.loadObject("OME::Project",1);
        System.out.println(project);
        System.out.println(project.getDescription());

        Attribute owner = project.getOwner();
        System.out.println(owner);
        System.out.println(owner.getStringElement("FirstName"));

        {
            List  typeList = factory.findObjects("OME::SemanticType",null);
            Iterator i = typeList.iterator();
            while (i.hasNext())
            {
                SemanticType type = (SemanticType) i.next();
                System.out.println(type.getName());
            }
        }

        {
            Iterator i = factory.iterateObjects("OME::DataTable",null);
            while (i.hasNext())
            {
                DataTable table = (DataTable) i.next();
                System.out.println(table.getTableName());
            }
        }

        bindings.logoutXMLRPC();
    }
}
