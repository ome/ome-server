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

import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.AbstractManager;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.FormalInput;
import org.openmicroscopy.ds.dto.ModuleExecution;
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
    extends AbstractManager
{
    /**
     * Creates a new <code>ModuleExecutionManager</code> which
     * communicates with a data server using the specified {@link
     * RemoteCaller}.  This {@link RemoteCaller} is first wrapped in
     * an instance of {@link InstantiatingCaller}.
     */
    public ModuleExecutionManager(RemoteCaller caller) { super(caller); }

    /**
     * Creates a new <code>ModuleExecutionManager</code> which
     * communicates with a data server using the specified {@link
     * InstantiatingCaller}.
     */
    public ModuleExecutionManager(InstantiatingCaller caller) { super(caller); }

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
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "G",
                                null,
                                iteratorTag,
                                newFeatureTag
                            });
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
     * ModuleExecution} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     String iteratorTag,
                                     String newFeatureTag,
                                     FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "G",
                                null,
                                iteratorTag,
                                newFeatureTag,
                                fields
                            });
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
                                     Dataset target,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "D",
                                new Integer(target.getID()),
                                iteratorTag,
                                newFeatureTag
                            });
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
     * ModuleExecution} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     Dataset target,
                                     String iteratorTag,
                                     String newFeatureTag,
                                     FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "D",
                                new Integer(target.getID()),
                                iteratorTag,
                                newFeatureTag,
                                fields
                            });
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
                                     Image target,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "I",
                                new Integer(target.getID()),
                                iteratorTag,
                                newFeatureTag
                            });
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
     * ModuleExecution} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ModuleExecution createMEX(Module module,
                                     Image target,
                                     String iteratorTag,
                                     String newFeatureTag,
                                     FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(module.getID()),
                                "I",
                                new Integer(target.getID()),
                                iteratorTag,
                                newFeatureTag,
                                fields
                            });
    }

    /**
     * <p>Creates a new module execution of the given module.  It is
     * marked as having the given dependence and target.  The
     * <code>dependence</code> parameter should be either
     * <code>"G"</code>, <code>"D"</code>, or <code>"I"</code>.  Some
     * basic sanity checking is performed.  If <code>dependence</code>
     * is <code>"G"</code>, <code>target</code> will be ignored.  If
     * <code>dependence</code> is <code>"D"</code>,
     * <code>target</code> should be the ID of a {@link Dataset} object.
     * If <code>dependence</code> is <code>"I"</code>,
     * <code>target</code> should be the ID of a {@link Image} object.  If
     * this is not the case, an error is thrown.</p>
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
    public ModuleExecution createMEX(int moduleID,
                                     String dependence,
                                     int targetID,
                                     String iteratorTag,
                                     String newFeatureTag)
    {
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(moduleID),
                                dependence,
                                new Integer(targetID),
                                iteratorTag,
                                newFeatureTag
                            });
    }

    /**
     * <p>Creates a new module execution of the given module.  It is
     * marked as having the given dependence and target.  The
     * <code>dependence</code> parameter should be either
     * <code>"G"</code>, <code>"D"</code>, or <code>"I"</code>.  Some
     * basic sanity checking is performed.  If <code>dependence</code>
     * is <code>"G"</code>, <code>target</code> will be ignored.  If
     * <code>dependence</code> is <code>"D"</code>,
     * <code>target</code> should be the ID of a {@link Dataset} object.
     * If <code>dependence</code> is <code>"I"</code>,
     * <code>target</code> should be the ID of a {@link Image} object.  If
     * this is not the case, an error is thrown.</p>
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
     * ModuleExecution} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ModuleExecution createMEX(int moduleID,
                                     String dependence,
                                     int targetID,
                                     String iteratorTag,
                                     String newFeatureTag,
                                     FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ModuleExecution)
            caller.dispatch(ModuleExecution.class,
                            "createMEX",
                            new Object[] {
                                new Integer(moduleID),
                                dependence,
                                new Integer(targetID),
                                iteratorTag,
                                newFeatureTag,
                                fields
                            });
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
        return (ActualInput)
            caller.dispatch(ActualInput.class,
                            "addActualInput",
                            new Object[] {
                                new Integer(outputMEX.getID()),
                                new Integer(inputMEX.getID()),
                                new Integer(formalInput.getID())
                            });
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
     * <p>This version of the method will return an {@link
     * ActualInput} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ActualInput addActualInput(ModuleExecution outputMEX,
                                      ModuleExecution inputMEX,
                                      FormalInput formalInput,
                                      FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ActualInput)
            caller.dispatch(ActualInput.class,
                            "addActualInput",
                            new Object[] {
                                new Integer(outputMEX.getID()),
                                new Integer(inputMEX.getID()),
                                new Integer(formalInput.getID()),
                                fields
                            });
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
    public ActualInput addActualInput(int outputMEXID,
                                      int inputMEXID,
                                      int formalInputID)
    {
        return (ActualInput)
            caller.dispatch(ActualInput.class,
                            "addActualInput",
                            new Object[] {
                                new Integer(outputMEXID),
                                new Integer(inputMEXID),
                                new Integer(formalInputID)
                            });
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
     * <p>This version of the method will return an {@link
     * ActualInput} object with the fields specified by the
     * <code>spec</code> parameter filled in.</p>
     */
    public ActualInput addActualInput(int outputMEXID,
                                      int inputMEXID,
                                      int formalInputID,
                                      FieldsSpecification spec)
    {
        Map fields = spec.getFieldsWanted();
        return (ActualInput)
            caller.dispatch(ActualInput.class,
                            "addActualInput",
                            new Object[] {
                                new Integer(outputMEXID),
                                new Integer(inputMEXID),
                                new Integer(formalInputID),
                                fields
                            });
    }

}
