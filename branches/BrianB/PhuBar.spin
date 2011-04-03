{ PhUBar - Phase-Universal FlyBar    Copyright (c) 2010 Greg Glenn
 
  Virtual flybar for R/C helicopter stabilization

   Main Object
     Allow user to edit config parameters via serial terminal or
       TextStar LCD terminal.  Update parameters to eeprom.
     Launch servo manager
     Launch PWM monitor for Elevator, Aileron, Rudder, and Aux RX channels
     Launch Gyro Monitor
     If no errors, status LED is off.
     On errors, blink the status LED rapidly.
     Begin 100Hz loop to compute servo outputs from Proportional/Derivative
      feedback loop.
      If user connects PropPlug, go into parameter edit mode
        When user disconnects PropPlug, reinitialize I/O cogs
        and go back into flight mode update loop.
       
Notes:
      IDG500 Gyro sensitivity = 9.1mV/degree/second
      Full scale at  3.2v is 4096 from MCP3208 ADC
      = 1163 counts per degree at 100Hz sample rate
      or 11.63xLSB/deg/sec.

      IDG-500 data is sampled at 500Hz for filtering
      Filtering is done with a first-order low-pass digital
      filter in software to reduce noise.

      ITG3200 is rated at 14.0xLSB/deg/sec using internal
      16-bit ADC at 2000 deg/sec full scale range. It
      is set to 5Hz low-pass filter and 500 samples/sec
      internal sample rate.
        
}
CON
  _xinfreq=5_000_000            
  _clkmode=xtal1+pll16x                                  'The system clock is set at 80MHz
  _FREE   = (32768 - constants#PB2_EEPROM_PARMS_START)   ' Reserve memory for parameter storage for PhuBar2

                                                                                                                            
OBJ
 constants      :  "Constants"                  'Global Constants and switches
 utilities      :  "Utilities"                  'Misc utilities
 servoman       :  "ServoManager"               'PWM output manager for servos
 rxman          :  "RC_Receiver"
 gyrofilter     :  "GyroFilter"                 '2-axis Invensense Gyro read using MCP3208 ADC
 itg3200        :  "ITG-3200"                   '3-axis Invensense Gyro read using i2c
 math           :  "Math"                       'Math utilities
 parms          :  "MultiParms"
 serio          :  "FullDuplexSerialPlus"
 'vp             :  "Conduit"                   'Viewport data transfer mechanism (debugging)
 'qs             :  "QuickSample"               'Viewport samples INA continuously in 1 cog to 20mhz

VAR

  long  sm_cog, rxman_cog, gyrofilter_cog
  long  dt, T, ratePrescale, angularPrescale
  byte  doSerial, gotcnt
  long  gyrotemp,  clkcnt

  long  pitchFilterBias, rollFilterBias
  long  pitch, roll, filteredPitchRate,filteredRollRate 
  long  servo1command, servo2command, servo3command
  long  decayValue  

  long  rollCorrection, pitchCorrection, collectiveCorrection  
  long  phasedPitchCorrection, phasedRollCorrection
  long  phasedS1Correction, phasedS2Correction,  phasedS3Correction 
 
  long  rx_aileron_pulsewidth, rx_aux_pulsewidth, rx_elevator_pulsewidth   
  long  pitchGyroZero, rollGyroZero
  long  servo1pos, servo2pos, servo3pos
  long  servo1sign, servo2sign, servo3sign

  long  pitchSign, rollSign  
  long  cosTerm1A, cosTerm1B, cosTerm2A, cosTerm2B, cosTerm3A, cosTerm3B
  long  minCorrection, maxCorrection, minServoPos, maxServoPos
  long  minCollectiveCorrection, maxCollectiveCorrection
  long  minYawCorrection, maxYawCorrection 

  'For PhuBar3
  long yaw, yawFilterBias, yawSign
  long tailServoSign, yawGyroZero, swashYaw
  long rx_rudder_pulsewidth, rx_rudder_center
  long tailServoPos, swashRotSineTerm, swashRotCosTerm  

  long filteredYawRate, yawIncrement
  long yawCorrection, cyclecount
  long servo1Center, servo2Center, servo3Center, tailServoCenter

  
PUB PhUBar | i      ' This is the main entry point

  doSerial := TRUE  'OK to do serial IO to terminal unless a ViewPort routine says otherwise
                    'Viewport IO and terminal IO will conflict if both are started.
                    
  'ViewPortView10    'Call setup routine to graph some data for debugging on Viewport oscilloscope
                     ' This is left here as a convenient place to switch on debugging
                     
  parms.start(@filteredRollRate, @filteredPitchRate, @filteredYawRate) 'Initialize object used for storing data in eeprom 

  InitializeParameters  'Get configurable parms from eeprom and give the
                        ' user a chance to change them via serial terminal
   
  '-------------------------------------------------------------------
  ' Main Update Loop
  '    at 80mHz clock, the code in this loop requires about 5 percent of
  '   the cycles available in a 100hz loop
  '--------------------------------------------------------------------
  
  dt := clkfreq/constants.GetSAMPLE_RATE_HZ
  T  := cnt
  i := 0
  clkcnt := cnt
  gotcnt := FALSE
   
  repeat
    T += dt  ' Start loop clock
    
    if(doSerial and (ina[constants#SERIAL_RX_PIN] == 1))    ' If user connects PropPlug, then reinit to allow  
        InitializeParameters                                ' user to go into parameter edit mode
        T := cnt                                            ' and go back into flight mode update loop
        NEXT
        
    IntegrateWithAngularDecay   ' Compute integrated pitch and roll with Angular decay
                                '  to simulate effect of weighted flybar
                                        
   '-------------------------------------------------------------
    'PD control loop
    '  Proportional term is integrated angle x angular gain
    '   no Integral term
    '  Derivative term is rate x rate gain
   '-------------------------------------------------------------

    pitchCorrection := ((parms.getPitchRateGain * (filteredPitchRate - pitchFilterBias))/ratePrescale ) + (parms.getPitchAngularGain * pitch)/angularPrescale
    rollCorrection  := ((parms.getRollRateGain * (filteredRollRate  - rollFilterBias ))/ratePrescale ) + (parms.getRollAngularGain * roll)/angularPrescale

    ' Get RX channel values

    'rx_elevator_pulsewidth := rxman.getraw(constants.GetRX_ELEVATOR_OFFSET)
    'rx_aileron_pulsewidth  := rxman.getraw(constants.GetRX_AILERON_OFFSET)
    'rx_aux_pulsewidth      := rxman.getraw(constants.GetRX_AUX_OFFSET)
    'rx_rudder_pulsewidth   := rxman.getraw(constants.GetRX_RUDDER_OFFSET)

    rx_elevator_pulsewidth := rxman.getElevator
    rx_aileron_pulsewidth  := rxman.getAileron
    rx_aux_pulsewidth      := rxman.getAux
    rx_rudder_pulsewidth   := rxman.getRudder  
  
    
    ' Allow for gyro reversal and add RX cyclic inputs

    pitchCorrection := (pitchSign * pitchcorrection) + (rx_elevator_pulsewidth - servoman#SERVO_CENTER)
    rollCorrection  := (rollSign * rollcorrection)   + (rx_aileron_pulsewidth  - servoman#SERVO_CENTER)

    collectiveCorrection := (rx_aux_pulsewidth - servoman#SERVO_CENTER) 
       
    ' Limit correction to within swash ring 

    pitchCorrection := (pitchCorrection <# maxCorrection) #> minCorrection
    rollCorrection  := (rollCorrection  <# maxCorrection) #> minCorrection

    ' Limit collective to within collective limit

    collectiveCorrection := (collectiveCorrection <# maxCollectiveCorrection) #> minCollectiveCorrection
       
   '-------------------------------------------------------------------------------------------------
  ' Phase-Adjust the servo commands 
   '  With clockwise rotor rotation, a positive phase adjustment implies
   '  a swash input occurs sooner. On diagram looking down on the swash,
   '  the command vector is being rotated counterclockwise.  Negative
   '  phase adjustment rotates the vector clockwise. 
   
   ' Generalized equations for CCPM mixing of 3 servos
  '
   ' 1 = cc * ( elevator * cos (alpha + theta1)  + aileron * cos (alpha + theta1 + 90) ) + pc * pitch
   ' 2 = cc * ( elevator * cos (alpha + theta2)  + aileron * cos (alpha + theta2 + 90) ) + pc * pitch
   ' 3 = cc * ( elevator * cos (alpha + theta3)  + aileron * cos (alpha + theta3 + 90) ) + pc * pitch
   '
   ' Note that we use shifts to divide using integer math, where shifting right
   '  by 16 bits is equivalent to dividing by 65535, which gets us the
   '  true fraction represented by sine or cosine, since the sine lookup tables return
   '  integer values between 1 and 65535.  Shifting by 1 keeps each term from getting
   '  larger than a long can hold, then shifting by 15 completes the division.
   '
   '--------------------------------------------------------------------------------------------------
    phasedS1Correction := ((((pitchCorrection ~> 1) * cosTerm1A) +  ((rollCorrection ~> 1) * cosTerm1B)) ~> 15) + collectiveCorrection
    phasedS2Correction := ((((pitchCorrection ~> 1) * cosTerm2A) +  ((rollCorrection ~> 1) * cosTerm2B)) ~> 15) + collectiveCorrection
    phasedS3Correction := ((((pitchCorrection ~> 1) * cosTerm3A) +  ((rollCorrection ~> 1) * cosTerm3B)) ~> 15) + collectiveCorrection


    servo1Command := servo1Center + (phasedS1Correction * servo1sign)
    servo2Command := servo2Center + (phasedS2Correction * servo2sign)
    servo3Command := servo3Center + (phasedS3Correction * servo3sign)
    
    '-------------------------------------------------------------
    ' Set PWM values to drive servos 
    '-------------------------------------------------------------     
     servo1pos := (servo1Command <# maxServoPos) #> minServoPos 
     servo2pos := (servo2Command <# maxServoPos) #> minServoPos
     servo3pos := (servo3Command <# maxServoPos) #> minServoPos
     
    if(constants#HARDWARE_VERSION == 3) 'Phubar3 has 3-axis, so include yaw
       ProcessYaw
          
    if(gotcnt == FALSE) 
      clkcnt := cnt - clkcnt       ' Track how long this update loop takes the first time through
      gotcnt := TRUE
      
    waitcnt(T)

PRI UpdateRudderCenter

 '---------------------------------------------------------------
 ' If no motion for 2 seconds, reset rudder center
 '  and set yaw to zero.  This keeps the deadband centered on the
 '  rudder center if the pilot lands and shuts the heli down to
 '  adjust rudder trim
 '---------------------------------------------------------------
 
    if((||filteredPitchRate < 10) and (||filteredRollRate < 10) and (||filteredYawRate < 10))
       cyclecount += 1
    
    if(cyclecount == constants.GetSAMPLE_RATE_HZ*2)
       cyclecount := 0
       rx_rudder_center := rx_rudder_pulsewidth
       yaw := 0 

  
PRI  ProcessYaw   | absYaw , yawRate
 '---------------------------------------------------------------
 ' Here we do all the processing of yaw information for
 '   controlling the rudder output to the tail rotor,
 '   either rate-based or heading-hold depending on
 '   whether heading-hold is turned on.
 '---------------------------------------------------------------

 if(parms.getHeadingHoldActive)
      UpdateRudderCenter
 
 '--------------------------------------------------------------- 
 ' Integrate Yaw angle from Yaw rate
 '---------------------------------------------------------------  
 yawRate := filteredYawRate - yawFilterBias
  absYaw := ||yaw
  
 if((||yawRate  > constants.GetNOISE) and (absYaw < constants#YAW_LIMIT))  'Limit travel 
      yaw +=  yawRate

  '--------------------------------------------------------------- 
  ' When inside rudder command deadband, we use integrated yaw value for proportional term
  '  to give a heading-hold quality, depending on yaw HH gain.
  ' When outside of deadband, keep yaw at zero to effectively go to to rate-only mode until we
  '  reenter the deadband and go back to using true yaw for HH
  '--------------------------------------------------------------- 
  
 if(||(rx_rudder_pulsewidth  - rx_rudder_center) > parms.GetHeadingHoldDeadband)
         yaw := 0

  '--------------------------------------------------------------- 
  ' Compute yaw correction using rate term and angle term
  '  Only add integrated yaw term if HH switch is On 
  '---------------------------------------------------------------          
 yawCorrection  := yawSign * ((parms.getYawRateGain * (filteredYawRate - yawFilterBias ))/ratePrescale )
 
 if(parms.getHeadingHoldActive)
     yawCorrection += yawSign * ((parms.getYawAngularGain * yaw)/angularPrescale)

  '--------------------------------------------------------------- 
  ' Add commanded input from rx if that channel is receiving a signal
  '---------------------------------------------------------------  
  
 yawCorrection  +=  (rx_rudder_pulsewidth  - rx_rudder_center)

  '--------------------------------------------------------------- 
  ' Keep within servo endpoint limits
  '---------------------------------------------------------------  
 yawCorrection  := (yawCorrection  <# maxYawCorrection) #> minYawCorrection

  '--------------------------------------------------------------- 
  ' Add to trimmed center and allow for reversal
  '---------------------------------------------------------------
  tailServoPos := tailServoCenter + (yawCorrection * tailServoSign)

  
PRI  IntegrateWithAngularDecay | rollRate, pitchRate, absRoll, absPitch 
   '-------------------------------------------------------------
    ' Here we accumulate integrated rotational angles.
    '  A decay value is computed and subtracted
    '  from the integrated rates so they will always decay to zero.
    ' 
    '  This simulates the behavior of a flybar that has
    '  enough angular momentum to act like a gyroscope.  A
    '  disturbance will result in some angle offset which will
    '  decay to zero over some timeframe, while providing corrective
    '  control inputs in the meantime.  
    '-------------------------------------------------------------
     decayValue := 0
     rollRate   := filteredRollRate - rollFilterBias
     pitchRate  := filteredPitchRate - pitchFilterBias
     absRoll    := ||roll
     absPitch   := ||pitch
    
    if((||rollRate  > constants.GetNOISE) and (||roll < constants.GetANGULAR_LIMIT))  'Limit travel of virtual flybar 
      roll +=  rollRate

    '----------------------------------------------------------------------------------------
    ' We want total angle to decay by X percent per second, where X is a settable parameter
    '  with some minimum decay amount so it will reach zero. Determined experimentally that
    '  dividing the percentage by 40 then by the sample rate gets us pretty close to zero
    '  in one second.  We have a minimum of 50 because drift can get almost that high, and
    '  we have to make sure we at least cancel the drift.
    '----------------------------------------------------------------------------------------

    decayValue := absRoll <# ( 50 #> ((parms.getAngularDecay * absRoll / 40) / constants.GetSAMPLE_RATE_HZ))
           
    if(roll > constants.GetNOISE)
      roll -=  decayValue   
    elseif(roll < -constants.GetNOISE)
      roll +=  decayValue

    '------------------------------------
    ' Same with pitch
    '------------------------------------
            
    if((||pitchRate > constants.GetNOISE) and (||pitch < constants.GetANGULAR_LIMIT) )   
      pitch += pitchRate

    decayValue := absPitch <# ( 50 #> ((parms.getAngularDecay * absPitch / 40) / constants.GetSAMPLE_RATE_HZ))
           
    if(pitch > constants.GetNOISE)
      pitch -=  decayValue   
    elseif(pitch < -constants.GetNOISE)
      pitch +=  decayValue       

        
PRI StopIO
  '--------------------------------------------------------
  ' Shutdown all cogs that are talking to external devices
  '--------------------------------------------------------
  servoman.Stop
  rxman.Stop
  
  if(constants#HARDWARE_VERSION == 2)
      gyrofilter.Stop

  if(constants#HARDWARE_VERSION == 3)
      itg3200.Stop

        
PRI StartupIO
  '--------------------------------------------------------
  ' Startup all cogs that talk to external devices
  '-------------------------------------------------------- 
  '---------------------------------------
  ' Launch cog to monitor Receiver inputs
  '--------------------------------------- 
  rxman.stop
  
  rxman_cog := rxman.start
  
  if(not rxman_cog)
    utilities.SignalNFlashes(2)

  utilities.pause(50) '  Give receiver manager some time to settle
  rx_rudder_center := rxman.getRudder 
   
  '-----------------------------------------
  ' Startup a cog to get gyro data
  '-----------------------------------------
  if(constants#HARDWARE_VERSION == 2)
      gyrofilter.Stop
      gyrofilter_cog := gyrofilter.start(parms.getGyroYAxisAddress, parms.getGyroXAxisAddress, @pitchGyroZero, @rollGyroZero, @gyroTemp, constants#STATUS_LED_PIN, @pitchFilterBias, @rollFilterBias)

  if(constants#HARDWARE_VERSION == 3)
      itg3200.Stop
      gyrofilter_cog := itg3200.start(parms.getGyroXAxisAddress, parms.getGyroYAxisAddress, parms.getGyroZAxisAddress, @pitchGyroZero, @rollGyroZero, @yawGyroZero, @gyroTemp, constants#STATUS_LED_PIN)

  if(not gyrofilter_cog)
      utilities.SignalNFlashes(3) 

  '----------------------------------------------
  ' Launch cog to manage PWM outputs to servos
  '----------------------------------------------
  servoman.Stop
  sm_cog := servoman.Start(@servo1pos, @servo2pos, @servo3pos, @tailServoPos, parms.getPulseInterval)
  
  if(not sm_cog)
    utilities.SignalNFlashes(4)


      
PRI InitializeParameters  |i, swashRingMargin, servoRange, collectiveMargin
  '--------------------------------------------
  ' Initialize variables and go into edit mode
  '  if user has attached PropPlug or TextStar
  '--------------------------------------------

  pitchsign        := 1
  rollsign         := 1
  servo1sign       := 1
  servo2sign       := 1
  servo3sign       := 1
  servoRange       := (servoMan#SERVO_MAX - servoMan#SERVO_MIN)
  swashRingMargin  := (servoRange - ((parms.getSwashRing * servoRange)/100))/2
  collectiveMargin := (servoRange - ((parms.getCollectiveLimit * servoRange)/100))/2
  minCorrection := servoMan#SERVO_MIN - servoMan#SERVO_CENTER +swashRingMargin 
  maxCorrection := servoMan#SERVO_MAX - servoMan#SERVO_CENTER -swashRingMargin 
  minCollectiveCorrection := servoMan#SERVO_MIN - servoMan#SERVO_CENTER +collectiveMargin
  maxCollectiveCorrection := servoMan#SERVO_MAX - servoMan#SERVO_CENTER -collectiveMargin
  minYawCorrection := servoMan#SERVO_MIN - servoMan#SERVO_CENTER +10000 ' Rudder hardcoded limits
  maxYawCorrection := servoMan#SERVO_MAX - servoMan#SERVO_CENTER -10000
  minServoPos   := servoMan#SERVO_MIN 
  maxServoPos   := servoMan#SERVO_MAX    
  angularPrescale := constants.GetSAMPLE_RATE_HZ
  ratePrescale := 4
  collectiveCorrection := 0
  pitchFilterBias := 0
  rollFilterBias  := 0
  roll := 0
  pitch := 0
  cyclecount := 0
  
  '----------------------
  ' For PhuBar3 only
  
  yawFilterBias := 0
  yawCorrection := 0
  yawSign       := 1
  tailServoSign := 1
  yaw := 0
  '-----------------------
  StopIO                                  ' Stop polling gyro to avoid interfering with eeprom I/O on I2C bus 
  
  dira[constants#SERIAL_RX_PIN]~          ' Set serial receive pin for input
    
  if(ina[constants#SERIAL_RX_PIN] == 1)   ' If PropPlug is connected, then allow user to edit parms,
     if(doSerial)                         ' Unless ViewPort is using the serial I/O                          
         parms.AllowUserToEdit            ' Allow editing of parameters

  StartupIO                               

 '------------------------------------------------------------------------
 'Pre-compute some terms needed in mixing equations so the
 ' update loop can run faster
   
  cosTerm1A := Math.Cosine(parms.getPhaseAngle - parms.getServo1theta)
  cosTerm1B := Math.Cosine(parms.getPhaseAngle - parms.getServo1theta +90)
  cosTerm2A := Math.Cosine(parms.getPhaseAngle - parms.getServo2theta)
  cosTerm2B := Math.Cosine(parms.getPhaseAngle - parms.getServo2theta +90)
  cosTerm3A := Math.Cosine(parms.getPhaseAngle - parms.getServo3theta)
  cosTerm3B := Math.Cosine(parms.getPhaseAngle - parms.getServo3theta +90)


  if(parms.getReversePitchGyro)    
     pitchSign := -1  

  if(parms.getReverseRollGyro)
     rollSign := -1
  
  if(parms.getServo1reverse)
     servo1sign := -1
     
  if(parms.getServo2reverse)
     servo2sign := -1
        
  if(parms.getServo3reverse)
     servo3sign := -1


  '--------------------
  ' For PhuBar3 only
  
  if(parms.getTailServoReverse)
     tailServoSign := -1
  if(parms.getReverseYawGyro)
     yawSign := -1

  '--------------------

  ' Adjust centers based on trim values and reversal settings
  
  servo1Center    := servoMan#SERVO_CENTER + (parms.getServo1Trim    * servoMan#ONE_PERCENT_SERVO_THROW) * servo1Sign 
  servo2Center    := servoMan#SERVO_CENTER + (parms.getServo2Trim    * servoMan#ONE_PERCENT_SERVO_THROW) * servo2Sign
  servo3Center    := servoMan#SERVO_CENTER + (parms.getServo3Trim    * servoMan#ONE_PERCENT_SERVO_THROW) * servo3Sign
  tailServoCenter := servoMan#SERVO_CENTER + (parms.getTailServoTrim * servoMan#ONE_PERCENT_SERVO_THROW) * tailServoSign
    
'-------------------------------------------------------------------------
     
'------------------------------------------------------------
' Various useful config blocks for debugging using Viewport
'------------------------------------------------------------

{
PRI ViewportView5
  doSerial := FALSE
  vp.config(string("var:phasedPitchCorrection,phasedRollCorrection,phasedS1Correction,phasedS2Correction,sineterm,costerm,cosTerm2A,cosTerm2B"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[phasedPitchCorrection(offset=2000,scale=20000),phasedRollCorrection(offset=10000,scale=20000),phasedS1Correction(offset=20000,scale=20000),phasedS2Correction(offset=30000,scale=20000)],timescale=2s,ymode=manual"))
  vp.share(@phasedPitchCorrection,@cosTerm2B)
 }
 
{ 
PRI ViewportView6
  doSerial := FALSE
  vp.config(string("var:filteredPitchRate,filteredRollRate,filteredYawRate,clkcnt"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[filteredPitchRate(offset=0,scale=1000),filteredRollRate(offset=1500,scale=1000),filteredYawRate(offset=2000,scale=1000)],timescale=1s,ymode=manual"))
  vp.share(@filteredPitchRate,@clkcnt)
  
}
{
PRI ViewportView7  
  doSerial := FALSE
  vp.config(string("var:filteredRollRate,filteredPitchRate,filteredYawRate"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[filteredRollRate(offset=0,scale=20),filteredPitchRate(offset=10,scale=20),filteredYawRate(offset=10,scale=20)],timescale=1s,ymode=manual"))
  vp.share(@filteredRollRate,@filteredYawRate)
}
{
PRI ViewportView8  
  doSerial := FALSE
  vp.config(string("var:rx_rudder_pulsewidth,rx_rudder_center,yaw,cyclecount,filteredRollRate,filteredPitchRate,filteredYawRate"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[rx_rudder_pulsewidth(offset=0,scale=80000),rx_rudder_center(offset=1000,scale=80000),yaw(offset=1500,scale=20000)],timescale=1s,ymode=manual"))

  vp.share(@rx_rudder_pulsewidth,@filteredYawRate)
  }
{
PRI ViewportView9  ' DCM debugging
  doSerial := FALSE
  vp.config(string("var:pitch,roll,filteredPitchRate,filteredRollRate,filteredYawRate,rMat0,rMat1,rMat2,rMat3,rMat4,rMat5,rMat6,rMat7,rMat8,clkcnt"))
  'vp.config(string("var:rMat[0]"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[pitch(offset=0,scale=20000),roll(offset=0,scale=20000),rmat6(offset=0,scale=20000),rmat7(offset=0,scale=20000)],timescale=1s,ymode=manual"))

  vp.share(@pitch,@clkcnt)
}
{
PRI ViewportView10    ' rotate pitch and roll 
 doSerial := FALSE
  vp.config(string("var:pitch,roll,yaw,filteredPitchRate,filteredRollRate,filteredYawRate,T1,T2,T3,T4,yawIncrement,clkcnt"))
  'vp.config(string("var:rMat[0]"))
  vp.config(string("start:dso"))
  vp.config(string("dso:view=[pitch(offset=0,scale=40000),roll(offset=0,scale=40000),T1(offset=0,scale=100000000),yawIncrement(offset=0,scale=1)],timescale=1s,ymode=manual"))

  vp.share(@pitch,@clkcnt)
  }     
CON
{{
Copyright (c) 2010 Greg Glenn
May be copied for personal use only.  Commercial use is prohibited.
If you want to license this technology for commercial purposes, contact me at mechg@sbcglobal.net

}}  