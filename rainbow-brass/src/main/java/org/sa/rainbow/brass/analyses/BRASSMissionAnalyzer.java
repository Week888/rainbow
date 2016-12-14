package org.sa.rainbow.brass.analyses;

import org.sa.rainbow.core.*;
import org.sa.rainbow.core.analysis.IRainbowAnalysis;
import org.sa.rainbow.core.error.RainbowConnectionException;
import org.sa.rainbow.core.ports.*;

/**
 * Created by schmerl on 12/13/2016.
 * Analyzes the current situation and triggers adaptation if necessary
 */
public class BRASSMissionAnalyzer extends AbstractRainbowRunnable implements IRainbowAnalysis {

    public static final String NAME = "BRASS Mission Evaluator";
    private IModelsManagerPort m_modelsManagerPort;
    private IModelUSBusPort m_modelUSPort;

    public BRASSMissionAnalyzer () {
        super(NAME);
        String per = Rainbow.instance ().getProperty (RainbowConstants.PROPKEY_MODEL_EVAL_PERIOD);
        if (per != null) {
            setSleepTime (Long.parseLong (per));
        } else {
            setSleepTime (IRainbowRunnable.LONG_SLEEP_TIME);
        }
    }

    @Override
    public void initialize (IRainbowReportingPort port) throws RainbowConnectionException {
        super.initialize (port);
        initializeConnections ();
    }

    private void initializeConnections () throws RainbowConnectionException {
        // Create a port to subscribe to model changes (if analyzer is event based)
        // m_modelChangePort = RainbowPortFactory.createModelChangeBusSubscriptionPort ();

        // Create a port to query things about a model
        m_modelsManagerPort = RainbowPortFactory.createModelsManagerRequirerPort ();

        // Create a port to change a model (e.g., to trigger adaptation, to set predicted score, etc.)
        m_modelUSPort = RainbowPortFactory.createModelsManagerClientUSPort (this);

    }

    @Override
    public void setProperty (String key, String value) {

    }

    @Override
    public String getProperty (String key) {
        return null;
    }

    @Override
    public void dispose () {
        m_reportingPort.dispose ();
        m_modelUSPort.dispose ();
    }

    @Override
    protected void log (String txt) {
        m_reportingPort.info (RainbowComponentT.ANALYSIS, txt);
    }

    @Override
    protected void runAction () {
        // Do the periodic analysis on the models of interest
    }

    @Override
    public RainbowComponentT getComponentType () {
        return RainbowComponentT.ANALYSIS;
    }
}
