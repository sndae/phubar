{{
MonitorRCReceiver.spin

    Monitors multiple output PWM channels from an R/C receiver and saves the
    pulse widths in long vars provided to the "start" routine.
    
    Tested with a Spektrum AR6100 receiver, although this should work with other
    r/c receivers.

    The AR6100 sends the aileron channel pulse first, followed by the pitch 
    channel pulse, followed by the elevator channel pulse.   There is about .08ms
    in between, which gives us time to reassign the timer module to each
    successive pin, measuring the time the pulse is high with timer A.

    It is not required that the pulses be in this order, but a latency of one
    pulse interval might be seen if they are not. 

    Tested with 4 channels from ar6100 receiver, where power and ground pins are
    provided +5v and GND, respectively, and the signal pin from each channel
    goes through a 4.7k resistor to an input pin on the Propeller.

    Pulldown resistors of 33k on the Aux and Rudder channels allow this code to check
    to see if a signal is present on those channels.  If not, those channels are
    ignored so as to not block the process from monitoring the other channels. The
    Aileron and Elevator channels are assumed to always be active, as they are the minimum
    necessary to control a fixed-pitch helicopter.
    
    Pins are assigned in the CON section of this object.

    Resulting pulse width values are in clock cycles. With clock speed set to 80mHz,
    pulse width values will generally range from 80,000 to 160,000  with center around
    120,000.
    
    Use this object in your code as follows:
    --------------------------------------------------------------
    OBJ
      rm    : "MonitorRCReceiver"

    VAR
      long elevator, aileron, aux, rudder, auxActive, rudderActive, rudderCenter     

    PUB Demo  
      rm.start(@elevator, @aileron, @aux, @rudder, @auxActive, @rudderActive, @rudderCenter)

      repeat
        ' Code that uses the pulse widths to do something useful
        
     --------------------------------------------------------------
      
}}

CON


OBJ
 servoman       :  "ServoManager"               'PWM output manager for servos
 constants      :  "Constants"
 utilities      :  "Utilities"
  
VAR
  LONG  monStack1[16]   
  LONG  monitorCog1,monitorCog2
  LONG  rx_elevator_addr, rx_aileron_addr, rx_aux_addr, rx_rudder_addr
  LONG  rx_aux_active_addr, rx_rudder_active_addr
  LONG  elevatorStartCount, aileronStartCount, auxStartCount
  LONG  elevatorEndCount, aileronEndCount, auxEndCount
  LONG  elevatorPinState, aileronPinState, auxPinState
  LONG  ailpin, elepin, auxpin, rudpin, rx_rudder_center_addr
    
PUB start(eAddr, aAddr, auxAddr, rudderAddr, auxActiveAddr, rActiveAddr, rCA) : okay

  rx_elevator_addr := eAddr     ' Save addresses
  rx_aileron_addr  := aAddr
  rx_aux_addr      := auxAddr
  rx_rudder_addr   := rudderAddr
  rx_aux_active_addr  := auxActiveAddr
  rx_rudder_active_addr := rActiveAddr
  rx_rudder_center_addr := rCA
  
  ailpin := constants.Getrx_aileron_pin
  elepin := constants.Getrx_elevator_pin
  auxpin := constants.Getrx_aux_pin
  rudpin := constants.Getrx_rudder_pin
   
   ' Aux and Rudder need their own cog in case they are not connected
   '  because waitpeq will wait forever if no pulses come in and no
   '  other RX data will get through

   CheckForSignals    
   monitorCog1 := cognew(MonitorAileronElevatorChannels, @monStack1)   ' Launch cog

   okay :=  monitorCog1
       
PUB stop

  if monitorCog1
    cogstop(monitorCog1~ )  
  if monitorCog2
    cogstop(monitorCog2~ )
 
PRI CheckForSignals  | synCnt

  

  ' Set up I/O pin directions and states.

  dira[auxpin]~
  dira[rudpin]~

  '---------------------------------------------------------------------------------
  ' The user may or may not have aux (collective) or rudder (tail) connected to the RX
  ' This checks to see if a pin is active before trying to read
  '  pulses from it. Requires pulldown resistors to make sure signal pin is
  '  low during the test.  Sets the flag to let the main program know if these
  '  channels are active.

  long[rx_aux_active_addr] := FALSE
  
  synCnt := clkfreq/4 + cnt
  repeat until synCnt =< cnt     ' wait 1/4 second to check if pins are hooked up to a signal
    if ina[auxpin] == 1
      long[rx_aux_active_addr] := TRUE

  long[rx_rudder_active_addr] := FALSE
  
  synCnt := clkfreq/4 + cnt
  repeat until synCnt =< cnt     ' wait 1/4 second to check if pins are hooked up to a signal
    if ina[rudpin] == 1
      long[rx_rudder_active_addr] := TRUE     


 'Get rudder center from rx

  long[rx_rudder_center_addr] :=  servoman#SERVO_CENTER
   
  if(long[rx_rudder_active_addr]) 
     ctra[30..26] := %01000  ' POS detector 
     frqa := 1
     phsa~
       ctra[5..0] := rudpin                       
       waitpeq(|<rudpin, |<rudpin, 0)                                           
       waitpeq(0, |<rudpin,0)                     
       if(phsa > servoman#SERVO_MIN)
         long[rx_rudder_center_addr] := phsa                         
      phsa~ 
  
PRI MonitorAileronElevatorChannels   
  'set up counter modules and I/O pin configurations from within the new cog 

  ctra[30..26] := %01000                                ' POS detector 
  frqa := 1
  phsa~                                                 ' Clear counts

  ' Set up I/O pin directions and states.
  
  dira[ailpin]~                            
  dira[elepin]~   ' Make pins input 
  dira[auxpin]~
  dira[rudpin]~
  
       
  repeat
     
    ctra[5..0] := ailpin 
    waitpeq(|<ailpin, |<ailpin, 0)           ' Wait for pin to go high. 
    waitpeq(0, |<ailpin,0)                   ' Wait for pin to go low.
    if(phsa > servoman#SERVO_MIN)            ' If valid pulse width,
      long[rx_aileron_addr] := phsa          ' Save width then clear.
    phsa~
    
     if(long[rx_aux_active_addr])            'Same for aux channel if active
       ctra[5..0] := auxpin                       
       waitpeq(|<auxpin, |<auxpin, 0)                                           
       waitpeq(0, |<auxpin,0)                     
       if(phsa > servoman#SERVO_MIN)
         long[rx_aux_addr] := phsa                         
      phsa~
         
    ctra[5..0] := elepin                     ' Same for elevator channel
    waitpeq(|<elepin, |<elepin, 0)                                               
    waitpeq(0, |<elepin,0)                     
    if(phsa > servoman#SERVO_MIN)
        long[rx_elevator_addr] := phsa                      
    phsa~

        
    if(long[rx_rudder_active_addr])  
       ctra[5..0] := rudpin                       
       waitpeq(|<rudpin, |<rudpin, 0)                                           
       waitpeq(0, |<rudpin,0)                     
       if(phsa > servoman#SERVO_MIN)
         long[rx_rudder_addr] := phsa                         
      phsa~



                                             
    