package acmetests;

import java.util.List;
import org.acmestudio.acme.element.IAcmeComponent;
import org.acmestudio.acme.element.IAcmeSystem;
import org.acmestudio.standalone.resource.StandaloneResource;
import org.acmestudio.standalone.resource.StandaloneResourceProvider;
import org.junit.Before;
import org.junit.Test;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.sa.rainbow.core.event.IRainbowMessage;
import org.sa.rainbow.core.ports.IModelChangeBusPort;
import org.sa.rainbow.core.ports.eseb.ESEBConstants;
import org.sa.rainbow.core.ports.eseb.RainbowESEBMessage;
import org.sa.rainbow.model.acme.AcmeModelOperation;
import org.sa.rainbow.model.acme.AcmeRainbowOperationEvent.CommandEventT;
import org.sa.rainbow.model.acme.znn.ZNNModelUpdateOperatorsImpl;
import auxtestlib.DefaultTCase;
import org.sa.rainbow.testing.prepare.RainbowMocker;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class TestSetLoadCmd extends DefaultTCase {

    @Before
    public void setUp() {
        RainbowMocker.injectRainbow();
    }

    @Test
    public void test () throws Exception {

        // Construct SetLoadCmd from CommandFactory
        StandaloneResource resource = StandaloneResourceProvider.instance ().acmeResourceForString (
                "src/test/resources/acme/znn.acme");
        IAcmeSystem sys = resource.getModel ().getSystems ().iterator ().next ();
        assertTrue (sys.getDeclaredTypes ().iterator ().next ().isSatisfied ());
        ZNNModelUpdateOperatorsImpl znn = new ZNNModelUpdateOperatorsImpl (sys, "src/test/resources/acme/znn.acme");
        IAcmeComponent server = sys.getComponent("s0");
        AcmeModelOperation cns = znn.getCommandFactory ().setLoadCmd (server, (float)0.32);

        // Execute SetLoadCmd
        IModelChangeBusPort announcePort = mock(IModelChangeBusPort.class);
        when(announcePort.createMessage()).thenAnswer(new Answer<IRainbowMessage>() {
            /**
             * @param invocation the invocation on the mock.
             * @return the value to be returned
             * @throws Throwable the throwable to be thrown
             */
            @Override
            public IRainbowMessage answer(InvocationOnMock invocation) throws Throwable {
                return new RainbowESEBMessage();
            }
        });
        assertTrue (cns.canExecute ());
        List<? extends IRainbowMessage> generatedEvents = cns.execute (znn, announcePort);

        // assert and print its results
        assertTrue (cns.canUndo ());
        assertFalse (cns.canExecute ());
        assertFalse (cns.canRedo ());
        outputMessages (generatedEvents);
        checkEventProperties (generatedEvents);
    }

    private void checkEventProperties (List<? extends IRainbowMessage> generatedEvents) {
        assertTrue (generatedEvents.size () > 0);
        assertTrue (generatedEvents.iterator ().next ().getProperty (IModelChangeBusPort.EVENT_TYPE_PROP).equals (CommandEventT.START_COMMAND.name ()));
        assertTrue (generatedEvents.get (generatedEvents.size () - 1).getProperty (IModelChangeBusPort.EVENT_TYPE_PROP).equals (CommandEventT.FINISH_COMMAND.name ()));
        for (IRainbowMessage msg : generatedEvents) {
            assertTrue (msg.getPropertyNames ().contains (ESEBConstants.MSG_TYPE_KEY));
        }
    }

    private void outputMessages (List<? extends IRainbowMessage> events) {
        for (IRainbowMessage msg : events) {
            System.out.println (msg.toString ());
        }
    }

}
