/*
 * org.openmicroscopy.analysis.Module
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

package org.openmicroscopy.analysis;

import java.util.List;
import java.util.ArrayList;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.Iterator;

public class Module
    implements Comparable
{
    protected List    inputs, outputs;
    protected String  name, description, location, moduleType;
    protected String  category, defaultIterator, newFeatureTag;

    protected static SortedMap  categories = new TreeMap();

    public static SortedMap getCategories()
    { return categories; }
    public static SortedSet getCategory(String category)
    { return (SortedSet) categories.get(category); }

    public Module()
    {
	this.inputs = new ArrayList();
	this.outputs = new ArrayList();
    }

    public Module(String name,
                  String description,
                  String location,
                  String moduleType,
                  String category,
                  String defaultIterator,
                  String newFeatureTag)
    {
        this.name = name;
        this.description = description;
        this.location = location;
        this.moduleType = moduleType;
        this.category = category;
        this.defaultIterator = defaultIterator;
        this.newFeatureTag = newFeatureTag;
	this.inputs = new ArrayList();
	this.outputs = new ArrayList();

        SortedSet categoryList = (SortedSet) categories.get(category);
        if (categoryList == null)
        {
            categoryList = new TreeSet();
            categories.put(category,categoryList);
        }
        categoryList.add(this);
    }

    public String getName() 
    { return name; }
    public void setName(String name)
    { this.name = name; }

    public String getDescription() 
    { return description; }
    public void setDescription(String description) 
    { this.description = description; }

    public String getLocation() 
    { return location; }
    public void setLocation(String location) 
    { this.location = location; }

    public String getModuleType() 
    { return moduleType; }
    public void setModuleType(String moduleType) 
    { this.moduleType = moduleType; }

    public String getCategory() 
    { return category; }
    public void setCategory(String category) 
    { 
        if (this.category != null)
        {
            SortedSet  categoryList = (SortedSet) categories.get(this.category);
            if (categoryList != null)
                categoryList.remove(this);
        }

        this.category = category; 
        SortedSet  categoryList = (SortedSet) categories.get(category);
        if (categoryList == null)
        {
            categoryList = new TreeSet();
            categories.put(category,categoryList);
        }
        categoryList.add(this);
    }

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
    public Iterator getInputIterator()
    { return inputs.iterator(); }
    public List getInputs() { return inputs; }

    public FormalInput addInput(String        name,
                                String        description,
                                AttributeType attributeType)
    {
        FormalInput input;

        inputs.add(input = new FormalInput(name,
                                           description,
                                           attributeType));
        return input;
    }


    public int getNumOutputs()
    { return outputs.size(); }
    public FormalOutput getOutput(int index)
    { return (FormalOutput) outputs.get(index); }
    public Iterator getOutputIterator()
    { return outputs.iterator(); }
    public List getOutputs() { return outputs; }

    public FormalOutput addOutput(String        name,
                                  String        description,
                                  AttributeType attributeType,
                                  String        featureTag)
    {
        FormalOutput output;

        outputs.add(output = new FormalOutput(name,
                                              description,
                                              attributeType,
                                              featureTag));
        return output;
    }


    public String toString()
    {
        return getName();
    }

    public int compareTo(Object o)
    {
        Module m = (Module) o;

        return this.name.compareTo(m.name);
    }


    private class FormalParameter
    {
        protected String         parameterName, parameterDescription;
        protected AttributeType  attributeType;
        
        private FormalParameter()
        {
        }
        
        private FormalParameter(String        parameterName,
                                String        parameterDescription,
                                AttributeType attributeType)
        {
            this.parameterName = parameterName;
            this.parameterDescription = parameterDescription;
            this.attributeType = attributeType;
        }

        public Module getModule() { return Module.this; }
        
        public String getParameterName()
        { return parameterName; }
        public void setParameterName(String parameterName)
        { this.parameterName = parameterName; }

        public String getParameterDescription()
        { return parameterDescription; }
        public void setParameterDescription(String parameterDescription)
        { this.parameterDescription = parameterDescription; }

        public AttributeType getAttributeType()
        { return attributeType; }
        public void setAttributeType(AttributeType attributeType)
        { this.attributeType = attributeType; }
    }
        

    public class FormalInput extends FormalParameter
    {
        //protected Something lookupTable;

        public FormalInput() { super(); }

        public FormalInput(String        name,
                           String        description,
                           AttributeType attributeType)
        {
            super(name,description,attributeType);
        }
    }


    public class FormalOutput extends FormalParameter
    {
        protected String  featureTag;

        public FormalOutput() { super(); }

        public FormalOutput(String        name,
                            String        description,
                            AttributeType attributeType,
                            String        featureTag)
        {
            super(name,description,attributeType);
            this.featureTag = featureTag;
        }

        public String getFeatureTag()
        { return featureTag; }
        public void setFeatureTag(String featureTag)
        { this.featureTag = featureTag; }
    }

}
