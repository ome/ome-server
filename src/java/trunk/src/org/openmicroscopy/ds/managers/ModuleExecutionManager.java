/*
 * org.openmicroscopy.ds.managers.ModuleExecutionManager
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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


package org.openmicroscopy.ds.managers;

import java.util.Map;

import org.openmicroscopy.ds.RemoteServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.DuplicateObjectException;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.AnalysisNode;
import org.openmicroscopy.ds.dto.FormalInput;
import org.openmicroscopy.ds.dto.ModuleExecution;
import org.openmicroscopy.ds.dto.ChainExecution;
import org.openmicroscopy.ds.dto.NodeExecution;
import org.openmicroscopy.ds.dto.ActualInput;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Image;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class ModuleExecutionManager
    extends AbstractService
{
    protected InstantiatingCaller icaller = null;
    protected DataFactory factory = null;

    public ModuleExecutionManager() { super(); }

    /**
     * Creates a new <code>ModuleExecutionManager</code> which
     * communicates with a data server using the specified {@link
     * RemoteCaller}.  This {@link RemoteCaller} is first wrapped in
     * an instance of {@link InstantiatingCaller}.
     */
    public ModuleExecutionManager(RemoteCaller caller)
    {
        super();
        initializeService(RemoteServices.getInstance(caller));
    }

    /**
     * Creates a new <code>ModuleExecutionManager</code> which
     * communicates with a data server using the specified {@link
     * InstantiatingCaller}.
     */
    public ModuleExecutionManager(InstantiatingCaller caller)
    {
        super();
        initializeService(RemoteServices.
                          getInstance(caller.getRemoteCaller()));
    }

    public void initializeService(RemoteServices services)
    {
        super.initializeService(services);
        icaller = (InstantiatingCaller)
            services.getService(InstantiatingCaller.class);
        factory = (DataFactory)
            services.getService(DataFactory.class);
    }

    /**
     * <p>Creates a new module execution of the given module with
     * global dependence.</p>
     *
     * <p>This method does <i>not</i> check whether the specified
     * dependence is valid for the specified module.  For one thing,
     * this is not entirely defined until all of the actual inputs are
     * specified.  For another, it's often unnecessary, and slows down
     * this method.</p>
     *
     * <p>If the <code>iteratorTag</code> or
     * <code>newFeatureTag</code> parameters are given, then they
     * provide values for the MEX fields of the same name.  If either
     * is <code>null</code>, that value is copied from the
     * <code>default_iterator</code> or <code>new_feature_tag</code>
     * column, respectively, of the module.</p>
     *
     * <p>This version of the method will return a {@link
     * ModuleExecution} object with the following fields filled in:</p>
     *
     * <ul>
     * <li><code>id</code></li>
     * <li><code>dependence</code></li>
     * <li><code>dataset</code></li>
     * <li><code>dataset.id</code></li>
     * <li><code>dataset.name</code></li>
     * <li><code>image</code></li>
     * <li><code>image.id</code></li>
     * <li><code>image.name</code></li>
     * <li><code>feature</code></li>
     * <li><code>feature.id</code></li>
     * <li><code>feature.name</code></li>
     * <li><code>module</code></li>
     * <li><code>module.id</code></li>
     * <li><code>module.name</code></li>
     * </ul>
     *
     * <p>To populate a different set of fields for the returned
     * module execution object, call the version of this method which
     * takes in a {@link FieldsSpecification} parameter.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        if (module == null)
            throw new IllegalArgumentException("Module cannot be null");

        if (iteratorTag == null || iteratorTag.equals(""))
            iteratorTag = module.getDefaultIterator();

        if (newFeatureTag == null || newFeatureTag.equals(""))
            newFeatureTag = module.getNewFeatureTag();

        ModuleExecution mex = (ModuleExecution)
            factory.createNew(ModuleExecution.class);
        mex.setModule(module);
        mex.setDependence("G");
        mex.setDataset(null);
        mex.setImage(null);
        mex.setIteratorTag(iteratorTag);
        mex.setNewFeatureTag(newFeatureTag);
        mex.setTimestamp("now");
        mex.setStatus("UNFINISHED");
        factory.markForUpdate(mex);

        return mex;
    }

    /**
     * <p>Creates a new module execution of the given module with
     * dataset dependence.</p>
     *
     * <p>This method does <i>not</i> check whether the specified
     * dependence is valid for the specified module.  For one thing,
     * this is not entirely defined until all of the actual inputs are
     * specified.  For another, it's often unnecessary, and slows down
     * this method.</p>
     *
     * <p>If the <code>iteratorTag</code> or
     * <code>newFeatureTag</code> parameters are given, then they
     * provide values for the MEX fields of the same name.  If either
     * is <code>null</code>, that value is copied from the
     * <code>default_iterator</code> or <code>new_feature_tag</code>
     * column, respectively, of the module.</p>
     *
     * <p>This version of the method will return a {@link
     * ModuleExecution} object with the following fields filled in:</p>
     *
     * <ul>
     * <li><code>id</code></li>
     * <li><code>dependence</code></li>
     * <li><code>dataset</code></li>
     * <li><code>dataset.id</code></li>
     * <li><code>dataset.name</code></li>
     * <li><code>image</code></li>
     * <li><code>image.id</code></li>
     * <li><code>image.name</code></li>
     * <li><code>feature</code></li>
     * <li><code>feature.id</code></li>
     * <li><code>feature.name</code></li>
     * <li><code>module</code></li>
     * <li><code>module.id</code></li>
     * <li><code>module.name</code></li>
     * </ul>
     *
     * <p>To populate a different set of fields for the returned
     * module execution object, call the version of this method which
     * takes in a {@link FieldsSpecification} parameter.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     Dataset dataset,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        if (module == null)
            throw new IllegalArgumentException("Module cannot be null");
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");

        if (iteratorTag == null || iteratorTag.equals(""))
            iteratorTag = module.getDefaultIterator();

        if (newFeatureTag == null || newFeatureTag.equals(""))
            newFeatureTag = module.getNewFeatureTag();

        ModuleExecution mex = (ModuleExecution)
            factory.createNew(ModuleExecution.class);
        mex.setModule(module);
        mex.setDependence("D");
        mex.setDataset(dataset);
        mex.setImage(null);
        mex.setIteratorTag(iteratorTag);
        mex.setNewFeatureTag(newFeatureTag);
        mex.setTimestamp("now");
        mex.setStatus("UNFINISHED");
        factory.markForUpdate(mex);

        return mex;
    }

    /**
     * <p>Creates a new module execution of the given module with
     * image dependence.</p>
     *
     * <p>This method does <i>not</i> check whether the specified
     * dependence is valid for the specified module.  For one thing,
     * this is not entirely defined until all of the actual inputs are
     * specified.  For another, it's often unnecessary, and slows down
     * this method.</p>
     *
     * <p>If the <code>iteratorTag</code> or
     * <code>newFeatureTag</code> parameters are given, then they
     * provide values for the MEX fields of the same name.  If either
     * is <code>null</code>, that value is copied from the
     * <code>default_iterator</code> or <code>new_feature_tag</code>
     * column, respectively, of the module.</p>
     *
     * <p>This version of the method will return a {@link
     * ModuleExecution} object with the following fields filled in:</p>
     *
     * <ul>
     * <li><code>id</code></li>
     * <li><code>dependence</code></li>
     * <li><code>dataset</code></li>
     * <li><code>dataset.id</code></li>
     * <li><code>dataset.name</code></li>
     * <li><code>image</code></li>
     * <li><code>image.id</code></li>
     * <li><code>image.name</code></li>
     * <li><code>feature</code></li>
     * <li><code>feature.id</code></li>
     * <li><code>feature.name</code></li>
     * <li><code>module</code></li>
     * <li><code>module.id</code></li>
     * <li><code>module.name</code></li>
     * </ul>
     *
     * <p>To populate a different set of fields for the returned
     * module execution object, call the version of this method which
     * takes in a {@link FieldsSpecification} parameter.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     Image image,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        if (module == null)
            throw new IllegalArgumentException("Module cannot be null");
        if (image == null)
            throw new IllegalArgumentException("Image cannot be null");

        if (iteratorTag == null || iteratorTag.equals(""))
            iteratorTag = module.getDefaultIterator();

        if (newFeatureTag == null || newFeatureTag.equals(""))
            newFeatureTag = module.getNewFeatureTag();

        ModuleExecution mex = (ModuleExecution)
            factory.createNew(ModuleExecution.class);
        mex.setModule(module);
        mex.setDependence("I");
        mex.setDataset(null);
        mex.setImage(image);
        mex.setIteratorTag(iteratorTag);
        mex.setNewFeatureTag(newFeatureTag);
        mex.setTimestamp("now");
        mex.setStatus("UNFINISHED");
        factory.markForUpdate(mex);

        return mex;
    }

    /**
     * <p>Adds an actual input to a module execution.  Actual inputs
     * are specified as links between module executions.  This method
     * specifies that the outputs of the <code>outputMEX</code> module
     * execution should be used to provide input to the
     * <code>formalInput</code> of the <code>inputMEX</code> module
     * execution.  Note that a formal output of the
     * <code>outputMEX</code> is not specified; all of the attributes
     * of the appropriate type created by that module execution are
     * used as input.</p>
     *
     * <p>The {@link ActualInput} object which is created is returned.
     * If there is already an actual input connecting the output MEX
     * to the specified input of the input MEX, an exception is
     * thrown.</p>
     *
     * <p>This version of the method will return an {@link
     * ActualInput} object with the following fields filled in:</p>
     *
     * <ul>
     * <li><code>id</code></li>
     * <li><code>module_execution</code></li>
     * <li><code>module_execution.id</code></li>
     * <li><code>formal_input</code></li>
     * <li><code>formal_input.id</code></li>
     * <li><code>input_module_execution</code></li>
     * <li><code>input_module_execution.id</code></li>
     * </ul>
     *
     * <p>To populate a different set of fields for the returned
     * module execution object, call the version of this method which
     * takes in a {@link FieldsSpecification} parameter.</p>
     */
    public ActualInput addActualInput(ModuleExecution outputMEX,
                                      ModuleExecution inputMEX,
                                      FormalInput formalInput)
    {
        if (outputMEX == null)
            throw new IllegalArgumentException("Output MEX cannot be null");
        if (inputMEX == null)
            throw new IllegalArgumentException("Input MEX cannot be null");
        if (formalInput == null)
            throw new IllegalArgumentException("Formal input cannot be null");

        Criteria crit = new Criteria();
        crit.addWantedField("id");
        crit.addFilter("module_execution",inputMEX);
        crit.addFilter("formal_input",formalInput);
        crit.addFilter("input_module_execution",outputMEX);

        ActualInput ai = (ActualInput)
            factory.retrieve(ActualInput.class,crit);

        if (ai != null)
            throw new DuplicateObjectException("That actual input already exists");

        ai = (ActualInput) factory.createNew(ActualInput.class);
        ai.setModuleExecution(inputMEX);
        ai.setFormalInput(formalInput);
        ai.setInputMEX(outputMEX);
        factory.markForUpdate(ai);

        return ai;
    }

    /**
     * <p>Adds an actual input to a module execution.  Actual inputs
     * are specified as links between module executions.  This method
     * specifies that the outputs of the <code>outputMEX</code> module
     * execution should be used to provide input to the
     * <code>formalInput</code> of the <code>inputMEX</code> module
     * execution.  Note that a formal output of the
     * <code>outputMEX</code> is not specified; all of the attributes
     * of the appropriate type created by that module execution are
     * used as input.</p>
     *
     * <p>The {@link ActualInput} object which is created is returned.
     * If there is already an actual input connecting the output MEX
     * to the specified input of the input MEX, an exception is
     * thrown.</p>
     *
     * <p>This version of the method will return an {@link
     * ActualInput} object with the following fields filled in:</p>
     *
     * <ul>
     * <li><code>id</code></li>
     * <li><code>module_execution</code></li>
     * <li><code>module_execution.id</code></li>
     * <li><code>formal_input</code></li>
     * <li><code>formal_input.id</code></li>
     * <li><code>input_module_execution</code></li>
     * <li><code>input_module_execution.id</code></li>
     * </ul>
     *
     * <p>To populate a different set of fields for the returned
     * module execution object, call the version of this method which
     * takes in a {@link FieldsSpecification} parameter.</p>
     *
     * @throws RemoteServerErrorException if <code>inputMEX</code>
     * does not contain a formal input called <code>formalInput</code>
     */
    public ActualInput addActualInput(ModuleExecution outputMEX,
                                      ModuleExecution inputMEX,
                                      String formalInputName)
    {
        Module inputModule = inputMEX.getModule();

        Criteria crit = new Criteria();
        crit.addWantedField("id");
        crit.addWantedField("name");
        crit.addFilter("module",inputModule);
        crit.addFilter("name",formalInputName);
        FormalInput formalInput = (FormalInput)
            factory.retrieve(FormalInput.class,crit);

        if (formalInput == null)
            throw new IllegalArgumentException("That formal input does not exist");

        return addActualInput(outputMEX,inputMEX,formalInput);
    }

    public NodeExecution createNEX(ModuleExecution mex,
                                   ChainExecution chex,
                                   AnalysisNode node)
    {
        if (mex == null)
            throw new IllegalArgumentException("MEX cannot be null");

        if ((chex == null && node != null) ||
            (chex != null && node == null))
            throw new IllegalArgumentException("CHEX and node must either both be null or neither");

        NodeExecution nex = (NodeExecution)
            factory.createNew(NodeExecution.class);
        nex.setModuleExecution(mex);
        nex.setChainExecution(chex);
        nex.setNode(node);
        factory.markForUpdate(nex);

        return nex;
    }

}
