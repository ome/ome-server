/*
 * org.openmicroscopy.vis.chains.ChainSaveFrame
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
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JLabel;
import javax.swing.BoxLayout;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import javax.swing.Box;
import java.awt.event.ActionListener;
import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.FlowLayout;


/** 
 * A frame containing fields used when saving a chain
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ChainSaveFrame extends JFrame implements ActionListener {
	
	private ChainFrame frame;
	private JButton cancel;
	private JButton save;
	
	private static int GAP=5;
	
	JTextField nameField;
	JTextArea descField;
	
	/**
	 * 
	 * @param The {@link Chain Frame} that contains the chain being saved
	 */
	public ChainSaveFrame(ChainFrame frame) {
		super("Save Chain");
		this.frame = frame;
		setResizable(false);
		
		setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		
		Container pane  = getContentPane();
		pane.setLayout(new BoxLayout(pane,BoxLayout.Y_AXIS));

		JPanel formPanel = new JPanel();
		formPanel.setLayout(new BoxLayout(formPanel,BoxLayout.Y_AXIS));
		
		pane.add(formPanel);
		
		Dimension heightGap = new Dimension(0,GAP);
		Dimension widthGap = new Dimension(GAP,0);
		
		formPanel.add(Box.createRigidArea(heightGap));
		JPanel namePanel = new JPanel();
		namePanel.setLayout(new BoxLayout(namePanel,BoxLayout.X_AXIS));
		namePanel.add(Box.createRigidArea(widthGap));
		formPanel.add(namePanel);
		
		JLabel nameLabel = new JLabel("Name:");
		nameLabel.setAlignmentY(Component.TOP_ALIGNMENT);
		namePanel.add(nameLabel);
		namePanel.add(Box.createRigidArea(widthGap));
		nameField = new JTextField(20);
		nameField.setAlignmentY(Component.TOP_ALIGNMENT);
		namePanel.add(nameField);
		
		formPanel.add(Box.createRigidArea(heightGap));
		JPanel descPanel = new JPanel();
		
		descPanel.setLayout(new BoxLayout(descPanel,BoxLayout.X_AXIS));
		formPanel.add(descPanel);		
		descPanel.add(Box.createRigidArea(widthGap));
		JLabel desc  = new JLabel("Description:");
		desc.setAlignmentY(Component.TOP_ALIGNMENT);
		descPanel.add(desc);
		
		descPanel.add(Box.createRigidArea(widthGap));
		descField =  new JTextArea(5,20);
		descField.setAlignmentY(Component.TOP_ALIGNMENT);
		descPanel.add(descField);
		
		
		Dimension d = new Dimension((int) desc.getPreferredSize().getWidth(),
			(int) nameLabel.getPreferredSize().getHeight());
		nameLabel.setPreferredSize(d); 
	
		formPanel.add(Box.createRigidArea(heightGap));
		JPanel buttonPanel  = new JPanel();
		//buttons
	//	buttonPanel.setLayout(new BoxLayout(buttonPanel,BoxLayout.X_AXIS));
		buttonPanel.setLayout(new FlowLayout(FlowLayout.RIGHT));
		pane.add(buttonPanel);
		
		save = new JButton("Save");
		buttonPanel.add(save);
		save.addActionListener(this);
		
		cancel = new JButton("Cancel");
		buttonPanel.add(cancel);
		cancel.addActionListener(this);
		
		pack();
	}	
	
	/**
	 * Processing of user selection of the buttons.
	 * 
	 * @param e The user event
	 */
	public void actionPerformed(ActionEvent e) {
		JButton src = (JButton) e.getSource();
		if (src == save)
			frame.completeSave(nameField.getText(),descField.getText());
		dispose();
	}
	
}
