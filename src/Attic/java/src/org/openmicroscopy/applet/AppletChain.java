/*
 * org.openmicroscopy.applet.AppletChain
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

package org.openmicroscopy.applet;

import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class AppletChain
    extends SimpleChain
{
    public AppletChain(AppletParameters ap, String param)
    {
        super();

        id = ap.getIntParameter(param+"/ID",true,-1);
        setName(ap.getStringParameter(param+"/Name",false));
        setDescription(ap.getStringParameter(param+"/Description",true));
        //setOwner(ap.getStringParameter(param+"/Owner",true));
        setLocked(ap.getBooleanParameter(param+"/Locked",false));

        int numNodes = ap.getIntParameter(param+"/Nodes",false);
        Chain.Node  nodes[] = new Chain.Node[numNodes];
        for (int i = 0; i < numNodes; i++)
        {
            String nodeParam = param+"/Node"+i;
            int id = ap.getIntParameter(nodeParam+"/ID",true,-1);
            Module module = (Module)
                ap.getObjectParameter("Module",
                                      nodeParam+"/Module",
                                      false);
            String iteratorTag = ap.getStringParameter(nodeParam+"/IteratorTag",
                                                       true);
            String newFeatureTag = ap.getStringParameter(nodeParam+"/NewFeatureTag",
                                                         true);

            nodes[i] = addNode(id,module,iteratorTag,newFeatureTag);
        }

        int numLinks = ap.getIntParameter(param+"/Links",false);
        Chain.Link  links[] = new Chain.Link[numLinks];
        for (int i = 0; i < numLinks; i++)
        {
            String linkParam = param+"/Link"+i;
            int id = ap.getIntParameter(linkParam+"/ID",true,-1);
            Chain.Node fromNode = nodes[ap.getIntParameter(linkParam+"/FromNode",
                                                           false)];
            Module.FormalOutput  fromOutput = (Module.FormalOutput)
                ap.getObjectParameter("Module/FormalOutput",
                                      linkParam+"/FromOutput",
                                      false);
            Chain.Node toNode = nodes[ap.getIntParameter(linkParam+"/ToNode",
                                                         false)];
            Module.FormalInput  toInput = (Module.FormalInput)
                ap.getObjectParameter("Module/FormalInput",
                                      linkParam+"/ToInput",
                                      false);

            links[i] = addLink(id,fromNode,fromOutput,toNode,toInput);
        }

        ap.saveObject("Chain",param,this);
        for (int i = 0; i < numNodes; i++)
            ap.saveObject("Chain/Node",param+"/Node"+i,nodes[i]);
        for (int i = 0; i < numLinks; i++)
            ap.saveObject("Chain/Link",param+"/Link"+i,links[i]);
    }
}
