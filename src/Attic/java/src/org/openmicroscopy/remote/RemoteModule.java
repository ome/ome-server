/*
 * org.openmicroscopy.remote.RemoteModule
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
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteModule
    extends RemoteOMEObject
    implements Module
{
    static
    {
        RemoteObject.addClass("OME::Module",RemoteModule.class);
        RemoteObject.addClass("OME::Module::FormalInput",
                              RemoteModule.FormalInput.class);
        RemoteObject.addClass("OME::Module::FormalOutput",
                              RemoteModule.FormalOutput.class);
    }

    public RemoteModule() { super(); }
    public RemoteModule(String reference) { super(reference); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String name)
    { setStringElement("name",name); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String description)
    { setStringElement("description",description); }

    public String getLocation()
    { return getStringElement("location"); }
    public void setLocation(String location)
    { setStringElement("location",location); }

    public String getModuleType()
    { return getStringElement("module_type"); }
    public void setModuleType(String moduleType)
    { setStringElement("module_type",moduleType); }

    public String getCategory()
    { return getStringElement("category"); }
    public void setCategory(String category)
    { setStringElement("category",category); }

    public String getDefaultIterator()
    { return getStringElement("default_iterator"); }
    public void setDefaultIterator(String defaultIterator)
    { setStringElement("default_iterator",defaultIterator); }

    public String getNewFeatureTag()
    { return getStringElement("new_feature_tag"); }
    public void setNewFeatureTag(String newFeatureTag)
    { setStringElement("new_feature_tag",newFeatureTag); }

    public String getExecutionInstructions()
    { return getStringElement("execution_instructions"); }
    public void setExecutionInstructions(String executionInstructions)
    { setStringElement("execution_instructions",executionInstructions); }

    public List getInputs()
    { return getRemoteListElement(FormalInput.class,"inputs"); }
    public Iterator iterateInputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_inputs");
        i.setClass(FormalInput.class);
        return i;
    }

    public List getOutputs()
    { return getRemoteListElement(FormalOutput.class,"outputs"); }
    public Iterator iterateOutputs()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_outputs");
        i.setClass(FormalOutput.class);
        return i;
    }

    public List getAnalyses()
    { return getRemoteListElement(RemoteModuleExecution.class,"analyses"); }
    public Iterator iterateAnalyses()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_analyses");
        i.setClass(RemoteModuleExecution.class);
        return i;
    }

    public String toString() { return getName(); }

    public static class FormalParameter
        extends RemoteOMEObject
        implements Module.FormalParameter
    {
        public FormalParameter() { super(); }
        public FormalParameter(String reference) { super(reference); }

        public Module getModule()
        { return (Module)
              getRemoteElement(RemoteModule.class,
                               "program"); }

        public String getParameterName()
        { return getStringElement("name"); }
        public void setParameterName(String parameterName)
        { setStringElement("name",parameterName); }

        public String getParameterDescription()
        { return getStringElement("description"); }
        public void setParameterDescription(String description)
        { setStringElement("description",description); }

        public SemanticType getSemanticType()
        { return (SemanticType) 
              getRemoteElement(RemoteSemanticType.class,"attribute_type"); }
        public void setSemanticType(SemanticType attributeType)
        { setRemoteElement("attribute_type",attributeType); }

        public boolean getOptional()
        { return getBooleanElement("optional"); }
        public void setOptional(boolean optional)
        { setBooleanElement("optional",optional); }

        public boolean getList()
        { return getBooleanElement("list"); }
        public void setList(boolean list)
        { setBooleanElement("list",list); }
    }

    public static class FormalInput
        extends FormalParameter
        implements Module.FormalInput
    {
        public FormalInput() { super(); }
        public FormalInput(String reference) { super(reference); }

        public LookupTable getLookupTable()
        { return (LookupTable) 
              getRemoteElement(RemoteLookupTable.class,"lookup_table"); }
        public void setLookupTable(LookupTable lookupTable)
        { setRemoteElement("lookup_table",lookupTable); }

        public boolean getUserDefined()
        { return getBooleanElement("user_defined"); }
        public void setUserDefined(boolean userDefined)
        { setBooleanElement("user_defined",userDefined); }
    }

    public static class FormalOutput
        extends FormalParameter
        implements Module.FormalOutput
    {
        public FormalOutput() { super(); }
        public FormalOutput(String reference) { super(reference); }

        public String getFeatureTag()
        { return getStringElement("feature_tag"); }
        public void setFeatureTag(String featureTag)
        { setStringElement("feature_tag",featureTag); }
    }
}
