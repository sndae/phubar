### Safety Warning ###
Because this device intercepts and modifies the receiver signals, there is always the possibility that a hardware or software failure could cause loss of control of the model, similar to loss of radio signal or receiver failure.  Always be aware of this and exercise appropriate safety precautions, including keeping the aircraft a safe distance from yourself and any spectators.

### Design ###
The example code uses five of the eight available cogs of the Propeller chip. A sixth is used only in setup mode when a PropPlug is connected, or when running ViewPort for debugging.

  * Main update loop
  * Receiver input processing
  * Servo output processing
  * Gyro input processing
  * Spin Interpreter
  * Serial I/O to terminal (during setup/debug only)

The same source code works for both the 2-axis PhuBar2 and the 3-axis PhuBar3.  The file Constants.spin has a version switch that can be set to either 2 or 3 to select which code is invoked.

Most of the components are surface-mount devices.  The ITG-3200 is a QFN chip 4mmx4mm square, requiring fine soldering tools and skills that may be beyond the average hobbyist.

While the Propeller chip normally uses a 32kb eeprom for storing of software, the PhuBar3 uses a 64kb eeprom so that user-set parameters can reside in the upper 32kb.  This way, the parameters for multiple helicopters can be retained even when software updates are loaded into eeprom, since the Propeller tool only loads the lower 32kb.

Before version 3.3.2 of the code, it was assumed that pulses from the 4 receiver channels arrived sequentially and did not overlap, as with Spektrum receivers.  Some receivers have high-speed modes that cause pulses on one channel to overlap pulses on other channels.  In version 3.3.2, the PWM input object was changed to read the channels using PASM assembler code so it could handle overlapping pulses.

Servo output and receiver inputs are all assumed to be R/C standard PWM pulse trains with pulse width range of 1-2ms.  Servo pulse interval can be adjusted from 5ms to 20ms, and reciever pulse interval on each channel can be any value greater than 1 microsecond.  Resolution on receiver input is about 1 microsecond which works out to 1000 steps over the 1ms pulse width range.
<br><br>
Main Processing Loop Block Diagram:<br>
<img src='http://static.rcgroups.net/forums/attachments/1/8/7/5/1/8/a3654293-92-Block%20Diagram.jpg' />
<br><br>

<h3>Other Resources</h3>
Discussion of the development of PhuBar2 and subsequent PhuBar3, with flight test videos, can be found in an RCGroups thread here:<br>
<br>
<a href='http://www.rcgroups.com/forums/showthread.php?t=1233263'>http://www.rcgroups.com/forums/showthread.php?t=1233263</a>

More detail about PhuBar2 (2-axis) can be found here:<br>
<br>
<a href='http://www.rcgroups.com/forums/member.php?u=187518'>http://www.rcgroups.com/forums/member.php?u=187518</a>    (Scroll to the very bottom to see the earliest blog entries)<br>
<br><br>