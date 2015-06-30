August 19, 2011

Finally received an MPU-6050 from CDI.

May 28, 2011

Renamed the wiki page "Parameters" to "Parameters2D" and added a new page "Parameters3D", created by mrbubbs on RCGroups.  The new page reflects a complete parameter list for the code in the satelliteReceiver branch in SVN. Eventually the 2D version will be less relevant as we fill in useable parameter values for the 3D version.

May 27, 2011

After much flight testing and tweaking by Ryan, his new cyclic and HH equations are looking solid.  I added code to allow for adjusting servo trim using the transmitter, either individually or mixed for swash leveling.  Ryan added collective trim using the tx throttle.

May 15, 2011

Currently working with Ryan to parameterize his control equations so the user will be able to tune the flight behavior.

May 11, 2011

> First 3D flight for PhuBar3 ! ! ... See RCGroups thread

April 15, 2011

Added version 3.5 tag in SVN. Includes Ryan Beall's code supporting Spektrum Satellite receivers. New code auto-detects whether a regular PWM receiver is connected to the Aileron input, or a satellite rcvr.  Requires routing 3.3v to power pin on aileron input instead of 5v.  Rudder port is used for throttle out.

March 21, 2011

Added a servo trim feature, accessed from the setup menu.  This allows a +/- 10% adjustment of the center of any servo.  Positive trim moves a swash servo horn in the down direction, negative is up.  This change is on the SVN trunk only, for now.

March 9, 2011

Added version 3.4 tag.  This release contains the 3.3.3 changes described below, plus a fix to a bug that was causing cyclic to be severly limited at upper and lower ends of collective range due to some hard stops on servo throw. Version 3.3.3 was skipped.

Feb 1, 2011

Changes to code on the main SVN trunk, version 3.3.3 (in progress):

Added code that allows you to change Setup parameters using the TextStar terminal.  Previously only tuning parameters (gains, phase) could be changed with the TextStar, while setup (servo reversals, gyro axes, etc) had to be done with the PropPlug connected to a PC.  Now, the model name is the only thing that cannot be changed with the TextStar, since it requires a keyboard to enter the name.

Also, fixed the bug that caused parameters to be lost when loading an updated version of software into eeprom.