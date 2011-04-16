{{RC_Receiver.spin

     Combines Tim Moore's code for reading PWM pulses on up to
     8 pins (contiguous), and Ryan Beall's code for decoding serial input
     from a Spektrum Satellite receiver.

     On startup, it detects which type of input is active, and
     leaves the appropriate code running in the cog.  The Spektrum
     satellite code uses FullDuplexSerialPlus.spin, which must be
     shutdown by the calling object if serial I/O is going to be
     used by another object.

-----------------------------------------------------------------------------------------------
PWM section

Read servo control pulses from a generic R/C receiver, handling up to 8 pins/channels
Use 4.7K resistors (or 4050 buffers) between each Propeller input and receiver signal output.

                   +5V
   ┌──────────────┐│     4.7K
 ──┤   R/C     [] ┣┼──────────• P[0..7] Propeller input(s) 
 ──┤ Receiver  [] ┣┘    Signal
 ──┤Channel(s) [] ┣┐
   └──────────────┘│
                   GND(VSS)

 Note: +5 and GND on all the receiver channels are usally interconnected,
 so to power the receiver only one channel need to be connected to +5V and GND.


The getrc function was modified to return values centered at zero instead of 1500.

Timmoore
  Modified to support 8 contiguous pins on any pin
  Support failsafe on channel 2 - check if RC pulses and added getstatus
----------------------------------------------------------------------------------------------- 

Spektrum Satellite section

   Read serial data from Spektrum satellite receiver using FullDuplexSerialPlus object
    
                  +3V
   ┌──────────────┐│     4.7K
 ──┤ Satellite [] ┣┼──────────•  Propeller input pin 
 ──┤ Receiver  [] ┣┘    Signal
 ──┤ Output    [] ┣┐
   └──────────────┘│
                   GND(VSS)

  *NOTE the power is 3v, not the 5v normally used for PWM receiver channels.

     On the PhuBar3,this means adding a connector with wires to the 3v regulator, ground,
     and the Aileron signal pin.

     Also, with a satellite receiver, provisions must be made for throttle output,
     which is done on the PhuBar3 by re-purposing the Rudder input channel as a Throttle out.
     On some ESCs, this may require using a smaller resistor (2.2k) on the Rudder signal pin.                  

-----------------------------------------------------------------------------------------------  
}}
Con
  Mhz    = (80+10)        ' System clock frequency in Mhz. + init instructions
  
OBJ
  constants     :  "Constants"
  serio         :  "FullDuplexSerialPlus"
  utilities     :  "Utilities"                  'Misc utilities 
    
VAR
  long  Cog
  long  Pins[8]
  long  Status
  long  PinShift                                          
  long  PinMask
  long  delay

  ' Vars for satellite receiver code
  long  PWMActive, elevatorPulseWidth, aileronPulseWidth, auxPulseWidth, rudderPulseWidth, throttlePulseWidth
  long  FailSafeValues[8],satBuffer[16],rxByte,sync,buffPosition,lastSyncTime,dtSync,debugtoggle,debugindex
  long  satPacketIndex,satPulse[7],satPacketTemp,satChNum
  long  Stack[32]

PUB start(PWMActiveAddress) : sstatus
'------------------------------------------------------------------
' Start the PWM rx cog and check for pulses within 1-2ms range
' If not within range, assume satellite is connected
'     shut down PWM cog
'     start Satellite Rx parsing cog
'------------------------------------------------------------------
    setpins(constants.GetPINMASK)  ' Tell rx object which pins to read
    PWMActive := TRUE 
    sstatus := startPWM
'-------------------------------------------------------------------    
' Code to check pulse widths on aileron channel and restart cog with
'   satellite rx decoding if appropriate
'
'   NOTE: Set PWMActive to FALSE if satellite is active, so accessors
'         will know where to get values from.
    
    repeat sstatus from 0 to 7     'Zero the pulse width buffers
         Pins[sstatus] := 0
         
    utilities.pause(100)           'Give rc cog time to update.  If no pulses are received
                                          ' the buffers will stay at zero
                                    
    if((getAileron < 60000))       'If measured pulses are well below 1-2ms range, we can
        PWMActive := FALSE         ' assume a satellite receiver is being used
        stop
        sstatus := startSatellite

    LONG[PWMActiveAddress] := PWMActive  'Notify main that PWM receiver active so
                                         ' it can pass this along to Servo Manager  
'-------------------------------------------------------------------
PUB startSatellite  

  serio.start(Constants.GetRX_AILERON_PIN, constants#SERIAL_TX_PIN, 0, 115200) 'Start serial I/O
  serio.rxflush
  Cog := cognew(runSatellite, @Stack) + 1   'Launch cog
  RETURN Cog 


PUB runSatellite 
'   Loops and parses packets from satellite rcvr

satelliteInit

 repeat
  if sync == TRUE
     'rxByte := serio.rxcheck    
      rxByte := serio.rxtime(30)
      
    if rxByte == -1
      'serio.dec(rxByte)
      sync := FALSE
      lastSyncTime := cnt
      
    else
      'serio.tx($D)
      'serio.hex(rxByte,2)
      satBuffer[buffPosition] := rxByte
      buffPosition++
      if buffPosition > 15
        buffPosition := 0
        sync := FALSE
        lastSyncTime := cnt

        satelliteParse
 
             
  else
    dtSync := utilities.msPassed(cnt,lastSyncTime) 
    if dtSync > 7
      
      buffPosition := 0
      sync := TRUE

    'serio.tx($D)
    'serio.str(string(" normal out "))
    'debugtoggle := getraw(constants.GetRX_RUDDER_OFFSET)
    'serio.dec(debugtoggle)
      
PUB satelliteParse
         
  satPacketIndex := 2
  repeat while satPacketIndex < 15
    satPacketTemp := (satBuffer[satPacketIndex] <<8) + satBuffer[satPacketIndex + 1] 
    
    satChNum := (satPacketTemp & %0011110000000000)>>10
    
    satPulse[satChNum] := satPacketTemp & %0000001111111111
    satPulse[satChNum] += 1000

    satPulse[satChNum] *= (clkfreq/1000000)  'convert to ticks
    
    satPacketIndex := satPacketIndex + 2

  
  elevatorPulseWidth := satPulse[2]
  aileronPulseWidth := satPulse[1]
  auxPulseWidth := satPulse[5]
  rudderPulseWidth := satPulse[3]
  throttlePulseWidth := satPulse[0]
  
{  
  serio.tx($D)
  serio.str(string("0: "))
  serio.dec(satPulse[0])
  serio.str(string(" 1: "))
  serio.dec(satPulse[1])
  serio.str(string(" 2: "))
  serio.dec(satPulse[2])
  serio.str(string(" 3: "))
  serio.dec(satPulse[3])
  serio.str(string(" 4: "))
  serio.dec(satPulse[4])
  serio.str(string(" 5: "))
  serio.dec(satPulse[5])
  serio.str(string(" 6: "))
  serio.dec(satPulse[6])
  
 }   
          
    
PUB satelliteInit  

FailSafeValues[0] := 1500
FailSafeValues[1] := 1500
FailSafeValues[2] := 1000
FailSafeValues[3] := 1500
FailSafeValues[4] := 1500
FailSafeValues[5] := 1500
FailSafeValues[6] := 1500
FailSafeValues[7] := 1295

satBuffer[0] := 0
satBuffer[1] := 0
satBuffer[2] := 0
satBuffer[3] := 0
satBuffer[4] := 0
satBuffer[5] := 0
satBuffer[6] := 0
satBuffer[7] := 0
satBuffer[8] := 0
satBuffer[9] := 0
satBuffer[10] := 0
satBuffer[11] := 0
satBuffer[12] := 0
satBuffer[13] := 0
satBuffer[14] := 0
satBuffer[15] := 0

sync := FALSE
buffPosition :=0
lastSyncTime := 0
dtSync := 0

rxByte := -1
serio.rxflush
utilities.pause(2)

debugtoggle := TRUE
debugindex := 0

   
PUB startPWM : sstatus
'' Start driver (1 Cog)  
'' - Note: Call setpins() before start
  delay := clkfreq/10
  Status := 0
  if not Cog
    repeat sstatus from 0 to 7
      Pins[sstatus] := (clkfreq/1_000_000) * 1500       ' Center Pins[1..7]
    sstatus := Cog := cognew(@INIT, @Pins) + 1
    
PUB setpins(_pinmask)
'' Set pinmask for active input pins [0..31]
'' Example: setpins(%0010_1001) to read from pin 0, 3 and 5
  Status := 0
  PinMask := _pinmask
  PinShift := 0
  repeat 32
    if _pinmask & 1
      quit
    _pinmask >>= 1
    PinShift++ 

PUB stop
'' Stop driver and release cog
  if Cog
    cogstop(Cog~ - 1)

  if(!PWMActive)    ' Kill serial i/o cog
     serio.Stop

PUB getraw(_pin) : value                                ' Get pulse width in clock tics
    value := Pins[_pin]


'------------------------------------------------------
'  Accessors used by
'    calling program
'
'------------------------------------------------------
PUB getElevator
    if(PWMActive)
      return getraw(constants.GetRX_ELEVATOR_OFFSET)
    else
      return elevatorPulseWidth
    
PUB getAileron
    if(PWMActive)
      return getraw(constants.GetRX_AILERON_OFFSET)
    else
      return aileronPulseWidth
      
PUB getAux
    if(PWMActive == TRUE)
      return getraw(constants.GetRX_AUX_OFFSET)
    else
      return auxPulseWidth
      
PUB getRudder
   if(PWMActive)
      return getraw(constants.GetRX_RUDDER_OFFSET)
   else
      return rudderPulseWidth

PUB getThrottle
    return throttlePulseWidth
      
'-----------------------------------------------------------
    
PUB get(_pin) : value
'' Get receiver servo pulse width in µs. 
  value := Pins[_pin]                                   ' Get puls width from Pins[..]
  value /= (clkfreq / 1_000_000)                        ' Pulse width in usec.

PUB getrc(_pin) : value
'' Get receiver servo pulse width as normal r/c values (±500) 
  value := Pins[_pin]                                  ' Get puls width from Pins[..]
  value /= (clkfreq / 1_000_000)                        ' Pulse width in µsec.
  value -= 1500                                        ' Make 0 center

PUB getstatus
  return Status

DAT
        org   0

INIT    mov   p1, par                           ' Get data pointer
        add   p1, #4*9                          ' Point to PinMask
        rdlong shift, p1                        ' Read PinMask
        add   p1, #4
        rdlong pin_mask, p1                     ' Read PinMask
        andn  dira, pin_mask                    ' Set input pins
        add   p1, #4
        rdlong edelay, p1                       ' Read PinMask
        mov   pe2, cnt
        sub   pe2, edelay

'=================================================================================

:loop   mov   d2, d1                            ' Store previous pin status
        waitpne d1, pin_mask                    ' Wait for change on pins
        mov   d1, ina                           ' Get new pin status 
        mov   c1, cnt                           ' Store change cnt                           
        and   d1, pin_mask                      ' Remove unrelevant pin changes
        shr   d1, shift                         ' Get relevant pins in 8 LSB
{
d2      1100
d1      1010
-------------
!d2     0011
&d1     1010
=       0010 POS edge

d2      1100
&!d1    0101
=       0100 NEG edge     
}
        ' Mask for POS edge changes
        mov   d3, d1
        andn  d3, d2

        ' Mask for NEG edge changes
        andn  d2, d1

'=================================================================================

:POS    tjz  d3, #:NEG                          ' Skip if no POS edge changes
'Pin 0
        test  d3, #%0000_0001   wz              ' Change on pin?
if_nz   mov   pe0, c1                           ' Store POS edge change cnt
'Pin 1
        test  d3, #%0000_0010   wz              ' ...
if_nz   mov   pe1, c1
'Pin 2
        test  d3, #%0000_0100   wz
if_nz   mov   pe2, c1
'Pin 3
        test  d3, #%0000_1000   wz
if_nz   mov   pe3, c1
'Pin 4
        test  d3, #%0001_0000   wz
if_nz   mov   pe4, c1
'Pin 5
        test  d3, #%0010_0000   wz
if_nz   mov   pe5, c1
'Pin 6
        test  d3, #%0100_0000   wz
if_nz   mov   pe6, c1
'Pin 7
        test  d3, #%1000_0000   wz
if_nz   mov   pe7, c1

'=================================================================================

:NEG    tjz   d2, #:loop                        ' Skip if no NEG edge changes
'Pin 0
        mov   p1, par                           ' Get data pointer
        test  d2, #%0000_0001   wz              ' Change on pin 0?
if_nz   mov   d4, c1                            ' Get NEG edge change cnt
if_nz   sub   d4, pe0                           ' Get pulse width
if_nz   wrlong d4, p1                           ' Store pulse width
'Pin 1
        add   p1, #4                            ' Get next data pointer
        test  d2, #%0000_0010   wz              ' ...
if_nz   mov   d4, c1              
if_nz   sub   d4, pe1             
if_nz   wrlong d4, p1             
'Pin 2
        add   p1, #4
        test  d2, #%0000_0100   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe2             
if_nz   wrlong d4, p1             
if_nz   mov   stat, #1                          ' RC transmitter should be on to get a pulse
'Pin 3
        add   p1, #4
        test  d2, #%0000_1000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe3             
if_nz   wrlong d4, p1             
'Pin 4
        add   p1, #4
        test  d2, #%0001_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe4             
if_nz   wrlong d4, p1             
'Pin 5
        add   p1, #4
        test  d2, #%0010_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe5             
if_nz   wrlong d4, p1             
'Pin 6
        add   p1, #4
        test  d2, #%0100_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe6             
if_nz   wrlong d4, p1
'Pin 7
        add   p1, #4
        test  d2, #%1000_0000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe7             
if_nz   wrlong d4, p1

        add   p1, #4
        wrlong stat, p1                         'write current RC transmitter status

        test  d2, #%0000_0100   wz              ' Change on pin 2?

if_nz   jmp   #:loop

        mov   c1, pe2                           ' time of last +ve edge
        add   c1, edelay
        sub   c1, cnt
        cmps  c1, #0 wc
if_c    mov   stat, #0                          ' no pulse for edelay so note no RC transmitter
        jmp   #:loop

fit Mhz                                         ' Check for at least 1µs resolution with current clock speed

'=================================================================================

pin_mask long %0000_0000
shift   long  0
edelay  long  0
stat    long  0

c1      long  0
               
d1      long  0
d2      long  0
d3      long  0
d4      long  0

p1      long  0

pe0     long  0
pe1     long  0
pe2     long  0
pe3     long  0
pe4     long  0
pe5     long  0
pe6     long  0
pe7     long  0

        FIT   496