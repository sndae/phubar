The Phubar3 can be used with a Spektrum Satellite receiver if you make the following modifications:

> A separate 3-pin connector is needed to connect to the satellite receiver.  The power pin must be wired to the +3v output of the voltage regulator.  The signal and ground pins must be wired to the signal and ground pins of the aileron input port on the PhuBar3.

> The rudder input on the PhuBar3 is used as the throttle output to an ESC.  If your PhuBar3 has a 10k current limiting resistor on the signal pin, this may be too large a value for some ESCs to see the signal.  You will likely need to replace the resistor on the rudder signal pin with a 2.2kohm resistor.  Don't use less than 2.2k ohms, if there is a possibility that you might still use that port for rudder input some day, since 5v input through a 2.2k resistor causes the maximum rated current of 500uA to flow into the Propeller chip input pin, and you wouldn't want to exceed that.

> As of version 3.5 of the code,  the presence of a satellite rx signal will be automatically detected, so there are no parameters to be changed.