# **PhuBar** #
Phase-Universal Virtual Flybar

PhuBar is a stabilizer device for micro-sized R/C helicopters. It is based on the Parallax Propeller processor and MEMS gyro chips. It provides stabilization similar to that of a physical weighted flybar, making small helicopters easier to fly, and making the physical flybar unnecessary.

The latest version, the PhuBar3, has an InvenSense ITG-3200 3-axis gyro chip which provides yaw control in addition to roll and pitch. It also has extra eeprom storage which allows parameter settings to be retained for multiple helicopters.

**Disclaimer:**  The PhuBar3 is a purely experimental development platform.  Use it at your own risk.  The developer accepts no liability for damage or injury sustained while using this device.

http://static.rcgroups.net/forums/attachments/1/8/7/5/1/8/a3559599-57-PhuBar3ShrinkWrap.jpg?

## **Hardware Features** ##
  * Small - 28mm x 45mm
  * Lightweight – about 8 grams excluding cables.
  * Fast - 32bit 8-core Propeller processor running at 80mHz allows 100Hz update rate
  * Programmable via serial-to-usb adapter and free tools from Parallax
  * Powered by receiver output 4-6 volts
  * Consumes 26mA current in setup mode,  33mA in flight mode.

## **Software Features** ##
Example software is available that does the following:
  * Handles up to 3 swashplate servos plus tail servo
  * 4 RX channels, Aileron, Elevator, Pitch(Aux), and Rudder.
  * Supports standard receivers with PWM output channels, or an optional Spektrum Satellite receiver.
  * Swash servos can be at any position on the swash, in 1 degree increments
  * Built-in CCPM mixing with adjustable phase angle.
  * Rate mode and Heading Hold mode for tail, with gains settings for each
  * A status LED flashes when gyro is calibrating, and goes out when ready for flight.  If motion is detected when gyro is calibrating, the LED will flash rapidly and the unit will not go into flight mode.
  * Parameters can be set using the Parallax Serial Terminal software that talks to the PhuBar via a USB cable and PropPlug.
  * Optional TextStar LCD micro-terminal can be used for field tuning of parameters when you are away from your PC.  The TextStar is powered by the PhuBar – no batteries needed. http://cats-whisker.com/web/node/7
  * Up to 10 different sets of parameters can be stored/retrieved, so you can move the unit among several helicopters, or you can keep settings for different flight regimes.
  * Software detects when the programming cable is connected, and immediately goes into setup mode, with the status LED steady on.  When the cable is disconnected, the unit recalibrates the gyro and returns to flight mode. This makes it unnecessary to disconnect/reconnect the battery to change parameters.
  * An auto-setup feature assists you in assigning gyro axes and servo direction when you install the unit for the first time.
  * Superior vibration rejection through hardware and software filtering, although it still benefits from use of foam tape for mounting.
  * Plenty fast enough for small helis in the 200 size category.


User-changeable parameters include:
  * Swash Phase Angle from -90 to +90 degrees in 1 degree increments.  Allows emulation of offset head or flybar, and phase adjustments for 3,4, or 5-blade heads
  * Angular gain (sometimes called Hiller gain – how strongly the gyro tries to bring heli back to level)
  * Rate Gain (sometimes called damping gain – how strongly the gyro resists quick motions)
  * Angular Decay (simulates the inertia of a weighted physical flybar; the decay value determines how fast the flybar would re-align with the rotor after a change in attitude)
  * Tail Rate gain
  * Tail HH angular gain
  * HH mode on or off
  * HH deadband – How far you have to move the rudder stick to “unlock” the heading hold and move the tail
  * Servo direction reversal
  * Servo placement on swash – locations from -360 to 360 degrees in 1-degree increments.
  * Gyro axis assignment – allows for 24 different ways for the unit to be mounted on the airframe
  * Gyro axis reversal.
  * Servo pulse interval, from 5 to 20ms in 1ms increments.   This accommodates a wide range of servo update rates.
  * Swash Ring 25% - 100% - Limits swash movement to prevent binding against the main rotor shaft
  * Servo center trim +/-10%



Send questions to mechg@sbcglobal.net
