# What's new in Rainbow Yellow (v3.0)

## Rainbow Simple Example

A new simplified and containerized example of how Rainbow works is provided with this 
release. The example uses the SWIM simulation for a prototype web site called RuBIS. 
The containerization is implemented using Docker, and the image can be built as part 
of this release or downloaded on DockerHub as `cmuable/rainbow-example:3.0`. See [Docker 
instruction](deployments/rainbow-example/docker/INSTRUCTIONS.md) for 
instructions on how to build this.

## Rainbow User Interface

A completely revamped user interface has been engineered, and is currently in prototype 
form. The user interface shows more architectural information about the interaction 
between components in Rainbow (for example, it is easier to see which probes are giving 
information to which gauges). In addition, there is a details pane that shows information 
like how an element is specified, what activities it has performed, etc. More details 
can be found at [UI Documentation](documents/ui.md). The UI is also very customizable.

![Main Window](documents/imgs/Main_Window.PNG)

## Stitch Language Changes

### Path Spreading Operator

By default, paths return sets of values. However, in some cases (e.g., when collecting the values of a property in Acme to average them), sets do not work because they do not allow duplicate values. Therefore, we needed a way to return a sequence of values. In the last term of a path operation, it is now possible to use the spreading operator `...` to tell Stitch to return a sequence rather than a set. For example:

```
/M.components:!T.ServerT[isArchEnabled==true]/...load
```
Will return a sequence containing the value of the `load` property of every component in the Acme model `M` that declares the type `T.ServerT` and has the `isArchEnabled` property set to `true`.

### Tactic condition check as part of Node condition check

By default, tactic conditions in prior versions of Stitch were not checked when evaluating if a branch was applicable. Therefore it was possible for Stitch to select a branch where a tactic was not applicable. The semantics of branch conditions for Stitch has been changed to include an implicit check of tactic conditions. For example, in the following scenario:

```
tactic AddServer() {
  int availableServers = size(/M.components:!T.ServerT[!isArchEnabled])
  condition {availableServers > 0;}
  ...
}

strategy Strategy {
  t0: (someCondition) -> addServer();
}
```
When checking the validity of the branch `t0`, Stitch will actually check the condition `someCondition && availableServers > 0`. 

### Separation of timing for tactic effect and strategy condition check

Over time, with our work on latency aware adaptation, we have come to consider that there are two kinds of “time”  in strategies. First, there is the time it takes for a change to be made on the model, and second is the time that it should take for the quality attributes to change. In the context of using an `AddServer` tactic, it might take 30 seconds to start up a server on the cloud and then another 15 seconds for there to be an affect on the the response time. We’ve separated this into two different times now . The former is the time for the tactic effect to be noticed, and this is now specified in the tactic. The latter is now specified in the strategy, and indicates how long to wait before the checking the conditions in the subnodes of the strategy. So, let’s look at the following code:

<pre>
tactic addReplicas (int count) {
  ...
  effect <b><u>@[30000]</u></b> {M resultD . maxReplics >= M. resultD . desiredReplics;}
}
strategy RandomExample [cHiRespTime || cLowResiliency] {
  t0 : (cHiRespTime) -> addReplicas(1) <b><u>@[15000]</u></b> {
     t0a: (cHiResponseTime) -> addReplicas(1);
     t0b: (default) -> done; 
  }
  t1: (cLowResiliency) -> addReplicas(1) {
     t1a: (success) -> done;
  }
  t2: (cHiRespTime) -> addReplicas(2) <b><u>@[15000]</u></b> {
     t2a: (cLowResiliency) -> addReplicas(1) {
        t2a0: (success) -> done;
     }
     t2b : (success) -> done;
   }
}
</pre>
Consider the case where we choose  `t0`. In this case, Stitch will wait for  _up to_  30 seconds for the tactic effect to be true before flagging  `success`; if it becomes true before the 30 seconds, then it will also just flag  `succcess`. Then, Stitch will wait for 15 seconds before checking the conditions in  `t0a`  and  `t0b`  (that aren’t  `success`  or  `fail`). If after 15 seconds, `cHiResponseTime` is still true, then it will choose  `t0a`. If none of the conditions are true, it will do  `t0b`, the default.

Now, consider the case Stitch chooses  `t1`. In this case Stitch will wait  _up to_  30 seconds for the tactic effect as before, and if the effect is met then will take  `t1a`  and have an outcome of  **success**.

Now consider  `t2`. This probably has an error in it. This is because the definition of  `success`  and  `fail`  in the nodes indicates whether the tactic effect has been met or not. There is no need to wait for the quality condition to be met if the tactic is unsuccessfully executed. Therefore, instead of waiting 15 seconds to check if  `cLowResiliency`  is true and the tactic was successful, Stitch will immediately execute  `t2b`  when  `addReplicas(2)`  succeeds. Therefore, the strategy will be finished after waiting 30 seconds for `addReplicas`’ effect to become true. This was probably not what would be intended, and so it would be better to have  `t2b`  be:

```
t2b: (!cLowResiliency) -> done;
```

instead. Unfortunately, this is not a backwards compatible change; the old version of Stitch would wait for _up to_ 15 seconds for the tactic effect in `AddServers` to be true when evaluating `t0`.

### Tactics can refer to pre-condition values of variables
The effect of a tactic can now refer to the new and old value of a variable that is defined in the tactic. So, in the following tactic:

```
 tactic AddResiliency() {
   int unusedServers = M.availableServers(M); 
   ...
   effect {
     unusedServers' == unusedServers - 1;
   }
 }
```
Means that in calculating the effect we recalculate the value of  `unusedServers`  as  `unusedServers'`  and compare it to the value it had when coming in.

## Rainbow Framework Changes

### Rainbow Target Checking

There is a new Rainbow Target configuration checking that can be called standalone but is also included when Rainbow starts up. Among other things, the configuration checker checks:

1.  **Gauges**: Are referenced gauge types defined? Are instances consistent with the type definition? Are referenced probes defined? Are referenced models defined in the configuration? Is the gauge implementation defined on the classpath? Do commands exist in the referenced models?
2. **Probes**: Are defined probes consumed by gauges? Do implementations exist?
3. **Effectors**: Do effectors have mandatory fields defined? Do implementations exist?
4. **Acme models:** Do the Acme files parse without error?
5. **Stitch scripts**: Do the scripts parse? Do they typecheck?

The configuration checking is extensible by implementing the `org.rainbow.util.IRainbowConfigurationChecker` interface.

Once a Rainbow deployment has been built, the configuration can be checked by executing:

```
./check-config.sh [-p properties-file] target
```

Where `target` is the target directory containing the configuration.

### Prototype Testing Infrastructure

In previous versions, doing standalone unit and integration testing was difficult without requiring a full Rainbow target. We have done some work on this, and the results are described in [Rainbow Testing Framework](testing/README.md). This allows writing of unit tests for gauges, probes, and model commands, as well as doing some integration testing between them. 

### `rainbow-mem-comms` Project for In memory communication
Rainbow was originally designed to manage distributed systems, and therefore the communication infrastructure was implemented to work over a network. However, a number of deployments of Rainbow have all components running on a single machine, and so we developed an in-memory communication infrastructure on top of the Guava event bus. 

To use this, you must specify its use in the `rainbow.properties` file:

```
rainbow.deployment.factory.class = org.sa.rainbow.core.ports.guava.GuavaRainbowPortFactory
```
For this to work, you should also ensure that `rainbow-mem-comms` is built and in the classpath of the target.

