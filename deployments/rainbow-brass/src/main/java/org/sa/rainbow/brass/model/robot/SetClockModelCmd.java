package org.sa.rainbow.brass.model.robot;

import org.sa.rainbow.core.models.IModelInstance;

public class SetClockModelCmd extends org.sa.rainbow.brass.model.p2_cp3.clock.SetClockModelCmd<RobotState> {

	public SetClockModelCmd(IModelInstance<RobotState> model, String target, String clockReference) {
		super(model, target, clockReference);
	}

	
	

}
