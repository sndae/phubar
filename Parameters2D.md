For software version 3.5 or earlier, which was suitable for 2D flying only.

Following are PhuBar3 parameter settings that have been shown to result in stable, controllable flight on various helicopters.  Some parameters are not show here because they are either a matter of personal preference, or are handled by the auto-setup features.  Gain settings can vary if the physical specs of your helicopter vary from those shown below.

| **Parameter** | **Description** | **HBFP** | **FireFox Ep200** | **CopterX 250SE** | **Blade CP** |
|:--------------|:----------------|:---------|:------------------|:------------------|:-------------|
|Servo 1 Theta Angle |Location of servo1 on swashplate|0         |-60                |-60                |0             |
|Servo 2 Theta Angle |Location of servo2 on swashplate|-270      |-180               |-180               |-120          |
|Servo 3 Theta Angle |Location of servo3 on swashplate|0         |-300               |-300               |-240          |
|Pitch Rate Gain | Rate gain on pitch axis |14        |21                 |17                 |20            |
|Pitch Angular Gain | Angular Gain on Pitch axis |60        |63                 |85                 |65            |
|Roll Rate Gain |Rate Gain on Roll axis |14        |21                 |17                 |17            |
|Roll Angular Gain |Angular Gain on Roll axis |60        |63                 |85                 |65            |
|Angular Decay  |Decay rate of angular compensation |95        |100                |100                |100           |
|Phase Angle    |Phase offset of swash inputs from forward=0 |-45       |-45                |-45                |0             |
|Yaw Rate Gain  |Rate gain on yaw (tail) axis |N/A       |45                 |17                 | N/A          |
|Yaw Angular Gain |Angular gain on yaw axis |N/A       |45                 |17                 | N/A          |
|               |                 |          |                   |                   |              |
|               | **Physical specs that affect mechanical gain** |
| Head Setup    | Flybarred (FB) or Flybarless (FBL) | FBL      | FBL               | FBL               | FB           |
|Tail Rotor Control Arm Ratio |Leverage ratio of tail bellcrank|N/A       |2.6                |1.25               |
|Tail Servo Horn Length |Distance from horn screw to link ball screw|N/A       |11mm               |7mm                |
|Main Rotor Pitch Arm Length |Distance, link ball to main shaft centerline|17mm      |12mm               |14mm               |
|HeadSpeed      |                 | Var      |3000 rpm           |3700 rpm           |



> HBFP = HoneyBee FP with blades trimmed at trailing edge to increase headspeed
> > The HBFP testing used a PhuBar2


> The Blade CP was flown with a PhuBar2

> For a discussion of Tail Rotor Control Arm Ratio, see:
> > http://www.rcgroups.com/forums/showthread.php?t=1333962#post16476772



> The 14mm Main Rotor Pitch Arm Length on the CopterX 250SE results from having the link ball in the middle hole of the arm on the MicroHeli Flybarless Rotor Head