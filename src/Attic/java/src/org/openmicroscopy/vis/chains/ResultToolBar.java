/*
 * org.openmicroscopy.vis.chains.ResultToolbar
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.ome.CChainExecution;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.vis.chains.SelectionState;
import javax.swing.Box;
import javax.swing.JToolBar;
import javax.swing.JLabel;
import javax.swing.JComboBox;
import javax.swing.JList;
import javax.swing.DefaultComboBoxModel;
import javax.swing.SwingConstants;
import javax.swing.ListCellRenderer;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.Component;
import java.util.Collection;

/** 
 * Toolbar for a {@link ChainFrame}. This toolbar contains a "save" button
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ResultToolBar extends JToolBar implements ActionListener{
	
	protected Connection connection;
	
	protected CmdTable cmd;
	
	
	protected JLabel chainName;
	
	protected JComboBox execList;
	
	protected ResultFrame frame;
	
	private SelectionState selectionState;
	
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ResultToolBar(ResultFrame frame,Controller controller,
			Connection connection) {
		super();
		
		this.frame = frame;
		this.connection = connection;
		
		cmd=controller.getCmdTable();
		
		selectionState = controller.getControlPanel().getSelectionState();
		setFloatable(false);
		Dimension dim = new Dimension(5,0);
		
		add(Box.createRigidArea(dim));
	
		
		add(Box.createRigidArea(dim));
		String[] data = {"NONE"};
		
		add(Box.createRigidArea(dim));
		
		JLabel chains = new JLabel("Chain: ");
		add(chains);

		chainName = new JLabel("None");
		
		add(chainName);
		add(Box.createHorizontalGlue());
		add(Box.createRigidArea(dim));
		JLabel exes = new JLabel("Executions");
		add(exes);
			
		execList = new JComboBox(data);
		execList.addActionListener(this);
		execList.setEditable(false);
		execList.setMaximumSize(execList.getMinimumSize());
		execList.setRenderer(new ExecutionsRenderer());
		add(execList);
		add(Box.createRigidArea(dim));	
	}
	
	
	public void actionPerformed(ActionEvent e) {
		CChainExecution exec = (CChainExecution) execList.getSelectedItem();
		frame.setExecution(exec);
	}
	
	public void updateExecutionChoices(CChain chain) {
		Collection execs = chain.getCurrentDatasetExecutions(selectionState);
		System.err.println("populating toolbar pulldown with "+
			execs.size()+" executions");
		Object[] a = new Object[0];
		a = execs.toArray(a);
		DefaultComboBoxModel model = new DefaultComboBoxModel(a);
		execList.setModel(model);
		// set initial
		CChainExecution exec = (CChainExecution) a[0];
		chainName.setText(chain.getName());
		frame.setExecution(exec);
	}
}

class ExecutionsRenderer  extends JLabel implements ListCellRenderer {
	
	public ExecutionsRenderer() {
		setOpaque(true);
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			if (value instanceof CChainExecution) {
				CChainExecution  exec = (CChainExecution) value;
				//setText(Integer.toString(exec.getID()));
				setText(exec.getID()+") "+exec.getTimestamp());
			}
			else 
				setText("None");
			if (isSelected) {
				setBackground(list.getSelectionBackground());
				setForeground(list.getSelectionForeground());
			} else {
				setBackground(list.getBackground());
				setForeground(list.getForeground());
			}
			 
			return this;
	}
}


