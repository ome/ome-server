/*
 * org.openmicroscopy.simple.SimpleModule
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




package org.openmicroscopy.simple;

import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import org.openmicroscopy.*;

public class SimpleModule
    extends SimpleObject
    implements Module, Comparable
{
    protected List    inputs, outputs;
    protected String  name, description, location, moduleType;
    protected String  defaultIterator, newFeatureTag;

    public SimpleModule()
    {
        super();
        this.inputs = new ArrayList();
        this.outputs = new ArrayList();
    }

    public SimpleModule(int    id,
                        String name,
                        String description,
                        String location,
                        String moduleType,
                        String category,
                        String defaultIterator,
                        String newFeatureTag)
    {
        super(id);
        this.name = name;
        this.description = description;
        this.location = location;
        this.moduleType = moduleType;
        this.defaultIterator = defaultIterator;
        this.newFeatureTag = newFeatureTag;
        this.inputs = new ArrayList();
        this.outputs = new ArrayList();
    }

    public String getName() 
    { return name; }
    public void setName(String name)
    { this.name = name; }

    public String getDescription() 
    { return description; }
    public void setDescription(String description) 
    { this.description = description; }

    public String getExecutionInstructions() { return null; }
    public void setExecutionInstructions(String instr) {}

    public String getLocation() 
    { return location; }
    public void setLocation(String location) 
    { this.location = location; }

    public String getModuleType() 
    { return moduleType; }
    public void setModuleType(String moduleType) 
    { this.moduleType = moduleType; }

    public ModuleCategory getCategory() 
    { return null; }
    public void setCategory(ModuleCategory category) 
    { }

    public String getDefaultIterator() 
    { return defaultIterator; }
    public void setDefaultIterator(String defaultIterator) 
    { this.defaultIterator = defaultIterator; }

    public String getNewFeatureTag() 
    { return newFeatureTag; }
    public void setNewFeatureTag(String newFeatureTag) 
    { this.newFeatureTag = newFeatureTag; }


    public int getNumInputs()
    { return inputs.size(); }
    public FormalInput getInput(int index)
    { return (FormalInput) inputs.get(index); }
    public Iterator iterateInputs()
    { return inputs.iterator(); }
    public List getInputs() { return inputs; }

    public FormalInput addInput(int           id,
                                String        name,
                                String        description,
                                SemanticType attributeType)
    {
        FormalInput input;

        inputs.add(input = new SimpleFormalInput(id,
                                                 name,
                                                 description,
                                                 attributeType));
        return input;
    }


    public int getNumOutputs()
    { return outputs.size(); }
    public FormalOutput getOutput(int index)
    { return (FormalOutput) outputs.get(index); }
    public Iterator iterateOutputs()
    { return outputs.iterator(); }
    public List getOutputs() { return outputs; }

    public FormalOutput addOutput(int           id,
                                  String        name,
                                  String        description,
                                  SemanticType attributeType,
                                  String        featureTag)
    {
        FormalOutput output;

        outputs.add(output = new SimpleFormalOutput(id,
                                                    name,
                                                    description,
                                                    attributeType,
                                                    featureTag));
        return output;
    }

    public List getExecutions() { return null; }
    public Iterator iterateExecutions() { return null; }

    public String toString()
    {
        return getName();
    }

    public int compareTo(Object o)
    {
        Module m = (Module) o;

        return this.name.compareTo(m.getName());
    }


    public class SimpleFormalParameter
        extends SimpleObject
        implements Module.FormalParameter
    {
        protected String         parameterName, parameterDescription;
        protected SemanticType  attributeType;
        
        private SimpleFormalParameter() { super(); }
        
        private SimpleFormalParameter(int           id,
                                      String        parameterName,
                                      String        parameterDescription,
                                      SemanticType attributeType)
        {
            super(id);
            this.parameterName = parameterName;
            this.parameterDescription = parameterDescription;
            this.attributeType = attributeType;
        }

        public Module getModule() { return SimpleModule.this; }

        public String getParameterName()
        { return parameterName; }
        public void setParameterName(String parameterName)
        { this.parameterName = parameterName; }

        public String getParameterDescription()
        { return parameterDescription; }
        public void setParameterDescription(String parameterDescription)
        { this.parameterDescription = parameterDescription; }

        public SemanticType getSemanticType()
        { return attributeType; }
        public void setSemanticType(SemanticType attributeType)
        { this.attributeType = attributeType; }

        public boolean getOptional() { return false; }
        public void setOptional(boolean optional) {}

        public boolean getList() { return false; }
        public void setList(boolean list) {}
    }
        

    public class SimpleFormalInput
        extends SimpleFormalParameter
        implements Module.FormalInput
    {
        public SimpleFormalInput() { super(); }

        public SimpleFormalInput(int           id,
                                 String        name,
                                 String        description,
                                 SemanticType attributeType)
        {
            super(id,name,description,attributeType);
        }

        public LookupTable getLookupTable() { return null; }
        public void setLookupTable(LookupTable table) {}

        public boolean getUserDefined() { return false; }
        public void setUserDefined(boolean ud) {}
    }


    public class SimpleFormalOutput
        extends SimpleFormalParameter
        implements Module.FormalOutput
    {
        protected String  featureTag;

        public SimpleFormalOutput() { super(); }

        public SimpleFormalOutput(int           id,
                                  String        name,
                                  String        description,
                                  SemanticType attributeType,
                                  String        featureTag)
        {
            super(id,name,description,attributeType);
            this.featureTag = featureTag;
        }

        public String getFeatureTag()
        { return featureTag; }
        public void setFeatureTag(String featureTag)
        { this.featureTag = featureTag; }
    }

}
