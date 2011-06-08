{{
MonitorPWM.spin

}}

CON
  _xinfreq=5_000_000            
  _clkmode=xtal1+pll16x 
  pwm_pin    = 19
  
VAR
  LONG  cog, stack[30]    'global variables for cog and stack.
  LONG  pwm_cog
  LONG  pwm_value

OBJ
 'serio          :  "FullDuplexSerialPlus"

PUB PWMTest

{
  serio.start(31, 30, 0, 57600)
  start
  
  repeat
     serio.str(string(" value = "))
     serio.dec(getPWM)
     serio.tx(13)
     waitcnt(80000000 + cnt)
}
      
PUB start : okay

  '' Starts the object and launches PWM monitoring process into a new cog.  
  '' All time measurements are in terms of system clock ticks.
 
  ' Launch the new cogs.
   pwm_value  := 0
   pwm_cog    := cognew(PwmMonitor(pwm_pin,   @pwm_value), @stack)

   okay :=  (pwm_cog)
       
PUB stop

  if pwm_cog
    cogstop(pwm_cog~ )

PUB getPWM
   return pwm_value
       
PRI PwmMonitor (pin, addr)
   
  'set up counter modules and I/O pin configurations(from within the new cog!)

  ctra[30..26] := %01000                                ' POS detector
  ctra[5..0] := pin                                     ' I/O pin
  frqa := 1

  ctrb[30..26] := %01100                                ' NEG detector
  ctrb[5..0] := pin                                     ' I/O pin
  frqb := 1

  phsa~                                                 ' Clear counts
  phsb~

  ' Set up I/O pin directions and states.
  
  dira[pin]~                                            ' Make pin an input

  ' PWM monitoring loop.
  
  repeat                                             ' Main loop for pulse 
                                                     ' monitoring cog.
    waitpeq(|<pin, |<pin, 0)                         ' Wait for pin to go high.
    'long[tladdr] := phsb                            ' Save tlow, then clear.
    phsb~
    waitpeq(0, |<pin,0)                              ' Wait for pin to go low.
    long[addr] := phsa                               ' Save width then clear.
    phsa~                                            ' Increment pulse count.