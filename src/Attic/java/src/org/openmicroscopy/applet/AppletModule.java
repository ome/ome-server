/*
 * org.openmicroscopy.applet.AppletModule
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




package org.openmicroscopy.applet;

import org.openmicroscopy.*;
import org.openmicroscopy.simple.*;

public class AppletModule
    extends SimpleModule
{
    public AppletModule(AppletParameters ap, String param)
    {
        super();

        id = ap.getIntParameter(param+"/ID",true,-1);
        setName(ap.getStringParameter(param+"/Name",false));
        setDescription(ap.getStringParameter(param+"/Description",true));
        setLocation(ap.getStringParameter(param+"/Location",false));
        setModuleType(ap.getStringParameter(param+"/ModuleType",false));
        // Fix category if needed
        //setCategory(ap.getStriNgparameter(param+"/Category",true));
        setDefaultIterator(ap.getStringParameter(param+"/DefaultIterator",true));
        setNewFeatureTag(ap.getStringParameter(param+"/NewFeatureTag",true));
        
        int numInputs = ap.getIntParameter(param+"/FormalInputs",false);
        Module.FormalInput  inputs[] = new Module.FormalInput[numInputs];
        for (int i = 0; i < numInputs; i++)
        {
            String inputParam = param+"/FormalInput"+i;
            int id = ap.getIntParameter(inputParam+"/ID",true,-1);
            String name = ap.getStringParameter(inputParam+"/Name",false);
            String description = ap.getStringParameter(inputParam+"/Description",
                                                       true);
            SemanticType  atype = (SemanticType)
                ap.getObjectParameter("SemanticType",
                                      inputParam+"/SemanticType",
                                      false);

            inputs[i] = addInput(id,name,description,atype);
        }

        int numOutputs = ap.getIntParameter(param+"/FormalOutputs",false);
        Module.FormalOutput  outputs[] = new Module.FormalOutput[numOutputs];
        for (int i = 0; i < numOutputs; i++)
        {
            String outputParam = param+"/FormalOutput"+i;
            int id = ap.getIntParameter(outputParam+"/ID",true,-1);
            String name = ap.getStringParameter(outputParam+"/Name",false);
            String description = ap.getStringParameter(outputParam+"/Description",
                                                       true);
            SemanticType  atype = (SemanticType)
                ap.getObjectParameter("SemanticType",
                                      outputParam+"/SemanticType",
                                      false);
            String featureTag = ap.getStringParameter(outputParam+"/FeatureTag",
                                                      true);

            outputs[i] = addOutput(id,name,description,atype,featureTag);
        }

        ap.saveObject("Module",param,this);
        for (int i = 0; i < numInputs; i++)
            ap.saveObject("Module/FormalInput",param+"/FormalInput"+i,inputs[i]);
        for (int i = 0; i < numOutputs; i++)
            ap.saveObject("Module/FormalOutput",param+"/FormalOutput"+i,outputs[i]);
    }
}
