{ Multi Parms  - Greg Glenn
   Store/retrieve multiple sets of parameters
   Built on Propeller Eeprom object

   Includes auto-setup functions to help user
   with setup of helicopter.
}
 

CON
  _xinfreq=5_000_000            
  _clkmode=xtal1+pll16x    'The system clock is set at 80MHz
  
  MODEL_NAME_LENGTH    = 15
  MAX_MODELS           = 10     'Number of models that can be stored in eeprom
  MAX_SWASH_RING       = 100    'Max percent of swash servo throw allowed
  MIN_SWASH_RING       = 25     'Min swash servo throw allowed
  
  FLAGS_REVERSE_PITCH_GYRO_BIT  = 0   'Bits in flags var that hold switch values
  FLAGS_REVERSE_ROLL_GYRO_BIT   = 1
  FLAGS_REVERSE_YAW_GYRO_BIT    = 2
  FLAGS_SERVO1_REVERSE_BIT      = 3
  FLAGS_SERVO2_REVERSE_BIT      = 4
  FLAGS_SERVO3_REVERSE_BIT      = 5
  FLAGS_TAIL_SERVO_REVERSE_BIT  = 6
  FLAGS_HEADING_HOLD_ACTIVE_BIT = 7
  
          
OBJ
 constants      :  "Constants"
 utilities      :  "Utilities"
 serio          :  "FullDuplexSerialPlus"
 gyrofilter     :  "GyroFilter"          '2-axis IDG-500 gyro with software low-pass filter
 itg3200        :  "ITG-3200"            '3-axis Invensense Gyro read using i2c, built-in low-pass filter
 sm             :  "ServoManager"
 eeprom         :  "Propeller Eeprom"
 
VAR
    ' Variables not stored in eeprom

  long  gyroXAxisAddress, gyroYAxisAddress, gyroZAxisAddress   
  long  rxAuxActive , lastModelIndex, gyroFilterCog
  long  filteredRollRateAddress, filteredPitchRateAddress,filteredYawRateAddress 
  long  pitchGyroZero, rollGyroZero,rxRudderActive
  long  gyroTemp, pitchFilterBias, rollFilterBias
  long  gyroYvalue, gyroXvalue, gyroYrate, gyroXrate
  long  gyroZvalue, gyroZrate 
  long  yawGyroZero, yawFilterBias
  
  ' Variables that are saved in upper 32kb of the eeprom
  
  long  activeModelIndex, modelName[10*4]
  long  pitchangularGain[10], pitchrateGain[10]
  long  rollAngularGain[10], rollRateGain[10]
  long  angularDecay[10], phaseAngle[10], pulseInterval[10] 
  long  flags[10]                                            'flags holds 32 switches for reversals, etc
  long  servo1theta[10], servo2theta[10], servo3theta[10]   
  long  yawAngularGain[10], yawRateGain[10] 
  long  gyroXAxisAssignment[10], gyroYAxisAssignment[10], gyroZAxisAssignment[10]
  long  headingHoldDeadband[10]
  long  swashRing[10]
  long  collectiveLimit[10]
  long  servo1Trim[10], servo2Trim[10], servo3Trim[10], tailServoTrim[10]
  ' Add new parms here
  '  and don't forget to change eeprom copy endpoints 
  '  Make sure constants#PB2_EEPROM_PARMS_START is far enough below
  '  top of 32kb eeprom to hold all of these longs
               
PUB go | a,b,c     ' For testing

   Start(@a,@b,@c)

 repeat
   Initialize
   AllowUserToEdit

PUB Start(fRA, fPA, fYA)

  filteredRollRateAddress := fRA   
  filteredPitchRateAddress := fPA
  filteredYawRateAddress := fYA

  Initialize
 
PUB Stop

      serio.stop

'--------------------
' Accessors
'--------------------
PUB getCollectiveLimit
  return collectiveLimit[activeModelIndex]

PUB getSwashRing
  return swashRing[activeModelIndex]
  
PUB getPitchAngularGain
  return pitchAngularGain[activeModelIndex]
  
PUB getPitchRateGain
  return pitchRateGain[activeModelIndex]

PUB getRollAngularGain
  return rollAngularGain[activeModelIndex]
  
PUB getRollRateGain
  return rollRateGain[activeModelIndex]
  
PUB getAngularDecay
  return angularDecay[activeModelIndex]

PUB getRxAuxActive
  return rxAuxActive

PUB getPhaseAngle
  return phaseAngle[activeModelIndex]

PUB getPulseInterval
  return pulseInterval[activeModelIndex]

PUB getServo1Trim
  return servo1Trim[activeModelIndex]

PUB getServo2Trim
  return servo2Trim[activeModelIndex]

PUB getServo3Trim
  return servo3Trim[activeModelIndex]

PUB getTailServoTrim
  return tailServoTrim[activeModelIndex]
  
PUB getServo1Theta
  return servo1Theta[activeModelIndex]

PUB getServo2Theta
  return servo2Theta[activeModelIndex]

PUB getServo3Theta
  return servo3Theta[activeModelIndex]
  
PUB getYawAngularGain
  return yawAngularGain[activeModelIndex]
  
PUB getYawRateGain
  return yawRateGain[activeModelIndex]

PUB getHeadingHoldDeadband
  return headingHoldDeadband[activeModelIndex]

' Accessors of bits in flag[i]

PUB getReversePitchGyro
  return ((flags[activeModelIndex] & (|< FLAGS_REVERSE_PITCH_GYRO_BIT)) <> 0)
  
PUB setReversePitchGyro(bool)
  if(bool)
       flags[activeModelIndex] |= (|< FLAGS_REVERSE_PITCH_GYRO_BIT)
  else
       flags[activeModelIndex] &= !(|< FLAGS_REVERSE_PITCH_GYRO_BIT)
              
PUB getReverseRollGyro
  return ((flags[activeModelIndex] & (|< FLAGS_REVERSE_ROLL_GYRO_BIT)) <> 0) 

PUB setReverseRollGyro(bool)
  if(bool)
       flags[activeModelIndex] |= (|< FLAGS_REVERSE_ROLL_GYRO_BIT)
  else
       flags[activeModelIndex] &= !(|< FLAGS_REVERSE_ROLL_GYRO_BIT) 
           
PUB getReverseYawGyro
  return ((flags[activeModelIndex] & (|< FLAGS_REVERSE_YAW_GYRO_BIT)) <> 0) 

PUB setReverseYawGyro(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_REVERSE_YAW_GYRO_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_REVERSE_YAW_GYRO_BIT)    
           
PUB getServo1Reverse
  return ((flags[activeModelIndex] & (|< FLAGS_SERVO1_REVERSE_BIT)) <> 0)

PUB setServo1Reverse(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_SERVO1_REVERSE_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_SERVO1_REVERSE_BIT)
       
PUB getServo2Reverse 
  return ((flags[activeModelIndex] & (|< FLAGS_SERVO2_REVERSE_BIT)) <> 0)

PUB setServo2Reverse(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_SERVO2_REVERSE_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_SERVO2_REVERSE_BIT)
       
PUB getServo3Reverse 
  return ((flags[activeModelIndex] & (|< FLAGS_SERVO3_REVERSE_BIT)) <> 0)

PUB setServo3Reverse(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_SERVO3_REVERSE_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_SERVO3_REVERSE_BIT)
 
PUB getTailServoReverse
  return ((flags[activeModelIndex] & (|< FLAGS_TAIL_SERVO_REVERSE_BIT)) <> 0)

PUB setTailServoReverse(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_TAIL_SERVO_REVERSE_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_TAIL_SERVO_REVERSE_BIT)
       
PUB getHeadingHoldActive
  return ((flags[activeModelIndex] & (|< FLAGS_HEADING_HOLD_ACTIVE_BIT)) <> 0)

PUB setHeadingHoldActive(bool)
 if(bool)
       flags[activeModelIndex] |= (|< FLAGS_HEADING_HOLD_ACTIVE_BIT)
 else
       flags[activeModelIndex] &= !(|< FLAGS_HEADING_HOLD_ACTIVE_BIT)
       
PUB getGyroXAxisAddress
   if(gyroXAxisAssignment[activeModelIndex] == "R")
       return filteredRollRateAddress
   if(gyroXAxisAssignment[activeModelIndex] == "P")
       return filteredPitchRateAddress
   if(gyroXAxisAssignment[activeModelIndex] == "Y")
       return filteredYawRateAddress 

PUB getGyroYAxisAddress
   if(gyroYAxisAssignment[activeModelIndex] == "R")
       return filteredRollRateAddress
   if(gyroYAxisAssignment[activeModelIndex] == "P")
       return filteredPitchRateAddress
   if(gyroYAxisAssignment[activeModelIndex] == "Y")
       return filteredYawRateAddress 
  return 
  
PUB getGyroZAxisAddress
   if(gyroZAxisAssignment[activeModelIndex] == "R")
       return filteredRollRateAddress
   if(gyroZAxisAssignment[activeModelIndex] == "P")
       return filteredPitchRateAddress
   if(gyroZAxisAssignment[activeModelIndex] == "Y")
       return filteredYawRateAddress 


PUB Initialize

  UpdateParmsFromEeprom

      
PUB StoreModelName(name, model) | index
 index := 0
 repeat until ((byte[@modelName[model*4]][index] := byte[name][index]) == 0)
     index++
     if(index == 15)
        QUIT
 byte[@modelName[model*4]][index]~

PUB CopyModelName(fm, tm) | index
 index := 0
 repeat until ((byte[@modelName[tm*4]][index] := byte[@modelName[fm*4]][index]) == 0)
     index++
     if(index == 15)
        QUIT
 byte[@modelName[tm*4]][index]~
            
PUB SetDefaults   | index
            
  'Set parameters to defaults
  '----------------------------------------------------
  '  Settings for various helis, assumes PhuBar2 is mounted
  '  top-up and 4-pin connector facing to the right.  Otherwise,
  '  the auto-setup features can be used to set servo and gyro
  '  directions for Phubar2 or PhuBar3
  '
  '                 Honeybee    FireFox  FireFox
  '                --------------------------------------
  'pitchangularGain := 63       63        70
  'pitchRateGain    := 21       21        25                  
  'rollAngularGain  := 63       63        63
  'rollRateGain     := 21       21        21                  
  'angularDecay     := 75       65       100
  'phaseAngle       := 0        0        -45
  'pulseInterval    := 10       10       10
  'reversePitchGyro := FALSE    FALSE   FALSE
  'reverseRollGyro  := TRUE     TRUE    TRUE
  'servo1reverse    := TRUE     TRUE    TRUE
  'servo2reverse    := FALSE    FALSE   FALSE
  'servo3reverse    := FALSE    FALSE   FALSE
  'servo1theta      := 0        -60      -60
  'servo2theta      := -270     -180     -180
  'servo3theta      := 0        -300     -300
  'yawAngularGain   :=                    45       
  'yawRateGain      :=                    45       
  'reverseYawGyro   :=                  FALSE
  'headingHoldDeadband :=               1800
  'headingHoldActive   :=               FALSE
  'swashRing         :=         50        50  
  'collectiveLimit   :=         ???       ???
  '----------------------------------------------------
         
  activeModelIndex   := 0                         'Can have 0-9 models, but default to 0

  repeat index from 0 to MAX_MODELS-1
     StoreModelName(string("unknown"),index)
     pitchAngularGain[index] := 60        ' 0 to 100 
     pitchRateGain[index]    := 20        ' 0 to 100 
     rollAngularGain[index]  := 60        ' 0 to 100 
     rollRateGain[index]     := 20        ' 0 to 100   
     angularDecay[index]     := 100       ' limit 1 to 300 percent 
     phaseAngle[index]       := 0         ' limit from -90 to +90
     pulseInterval[index]    := 20        ' servo pulse interval
     gyroXAxisAssignment[index] := "R"    ' assign axes based on how the unit is
     gyroYAxisAssignment[index] := "P"    ' oriented in the aircraft     
     servo1theta[index]      := 0         ' Negative angles are clockwise from nose=0 when looking
     servo2theta[index]      := 0         ' down on rotor mast
     servo3theta[index]      := 0
     yawAngularGain[index]   := 45        ' 0 to 100 
     yawRateGain[index]      := 45        ' 0 to 100
     swashRing[index]        := 50        ' 50% range limit on swash servos to prevent binding
     collectiveLimit[index]  := 50        ' 50% range limit on collective pitch to prevent binding
     servo1Trim[index]       := 0         ' 0 to +/- 10% trim on servo center
     servo2Trim[index]       := 0
     servo3Trim[index]       := 0
     tailServoTrim[index]    := 0
     
     gyroZAxisAssignment[index] := "Y"    ' Z axis is Yaw
     headingHoldDeadband[index] := 1600   ' 2% deadband
     flags[index] := %00000000
       
  '----------------------------------------------------
   ' Put FireFox EP200 settings in model 10
   
  StoreModelName(string("FireFox200"),9)
  pitchAngularGain[9]    := 65        ' 0 to 100 
  pitchRateGain[9]       := 21        ' 0 to 100 
  rollAngularGain[9]     := 63        ' 0 to 100 
  rollRateGain[9]        := 15        ' 0 to 100   
  angularDecay[9]        := 100       ' limit 1 to 300 percent 
  phaseAngle[9]          := -45       ' limit from -90 to +90
  pulseInterval[9]       := 10        ' servo pulse interval
  gyroXAxisAssignment[9] := "Y"       ' assign axes based on how the unit is
  gyroYAxisAssignment[9] := "R"       ' oriented in the aircraft     
  servo1theta[9]         := -60       ' Negative angles are clockwise from nose=0 when looking
  servo2theta[9]         := -180      ' down on rotor mast
  servo3theta[9]         := -300
  yawAngularGain[9]      := 45        ' 0 to 100 
  yawRateGain[9]         := 45        ' 0 to 100
  swashRing[9]           := 50        ' 50% range limit on swash servos to prevent binding
  collectiveLimit[9]     := 50        ' 50% range limit on collective pitch to prevent binding
     
  gyroZAxisAssignment[9] := "P"
  headingHoldDeadband[9] := 1600

  flags[9] := %00001000   
  
  
PUB UpdateParmsFromEeprom

  eeprom.ToRam(@activeModelIndex, @tailServoTrim[9] + 3, constants.getEEPROM_PARMS_START)

PUB SaveParmsToEeprom

  eeprom.FromRam(@activeModelIndex, @tailServoTrim[9] + 3, constants.getEEPROM_PARMS_START)
  
PUB  AllowUserToEdit
  '-----------------------------------------------------------------------------
  'If using PropStick USB, insert a check to see if USB/FTDI is connected and powered
  ' Pins 30 and 31 should be High if they are
  ' Can't start serial io if cable disconnected because processor
  '  will hang or do weird things
  ' For a standalone Propeller chip being programmed
  ' via a PropPlug, when the PropPlug is disconnected, the tx/rx pins
  ' float and starting the serial io cog does not seem to hang the
  ' processor.  in that case, this check may or may not see rx/tx as high,

  '  if((ina[SERIAL_RX_PIN] == 1) and (ina[SERIAL_TX_PIN] == 1)) 
  '-------------------------------------------------------------------------------

  dira[constants#SERIAL_RX_PIN]~  'Set for input
  dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output 
 
    if(ina[constants#SERIAL_RX_PIN] == 1)
      serio.start(constants#SERIAL_RX_PIN, constants#SERIAL_TX_PIN, 0, 57600) 'Start cog to allow IO with serial terminal

      outa[constants#STATUS_LED_PIN]~~          'Turn on LED to let user know we are ready for his input

      serio.rxflush
      utilities.pause(2)
                             
      EditParameters            
      UpdateParmsFromEeprom                     'Refresh parms from eeprom in case we just updated firmware
                                                ' to make sure we get a valid model's parms instead of
                                                ' default stuff that may not fly
          
      outa[constants#STATUS_LED_PIN]~           'Turn off LED to let user know we no longer accept input
      utilities.pause(20)
      serio.stop

PRI RXorDisconnect : rxbyte

  ' Waits for receive line to go low, either from user disconnecting the cable, or
  '  from user sending a character from the serial terminal
  '  Waits 20ms to give time for a character to finish coming in
  '  Returns -1 (from rxcheck) if no character was received
   
  repeat until (ina[constants#SERIAL_RX_PIN] == 0)
  utilities.pause(20)
  rxbyte := serio.rxcheck
  

PRI DumpTuningParameters

    serio.tx($D)
    serio.tx($D)
    serio.str(string("Parameters:"))       'Dump all parameters    
    serio.tx($D)
    serio.str(string("Model: "))
    serio.dec(activeModelIndex+1)
    serio.str(string(": "))
    serio.str(@modelName[activeModelIndex*4])
    serio.tx($D)
    DumpInteger(string("Pitch Rate Gain"),     getPitchRateGain)
    DumpInteger(string("Pitch Angular Gain"),  getPitchAngularGain)
    DumpInteger(string("Roll Rate Gain"),      getRollRateGain)
    DumpInteger(string("Roll Angular Gain"),   getRollAngularGain)
    DumpInteger(string("Angular Decay"),       getAngularDecay)
    DumpInteger(string("Phase Angle"),         getPhaseAngle)
    DumpInteger(string("Swash Ring"),          getSwashRing)
    DumpInteger(string("Collective Limit"),    getCollectiveLimit)
    '----------------
    ' For PhuBar3
    if(constants#HARDWARE_VERSION == 3)
       DumpInteger(string("Yaw Rate Gain"),                getYawRateGain)
       DumpInteger(string("Heading Hold Gain"),            getYawAngularGain)
       DumpInteger(string("Heading Hold Deadband"),        getHeadingHoldDeadband)
       DumpSwitch (string("Heading Hold On"),              getHeadingHoldActive) 

    '----------------


PRI DumpSetupParameters

    serio.tx($D)
    serio.tx($D)
    serio.str(string("Parameters:"))       'Dump all parameters    
    serio.tx($D)
    serio.str(string("Model: "))
    serio.dec(activeModelIndex+1)
    serio.str(string(": "))
    serio.str(@modelName[activeModelIndex*4])
    serio.tx($D)
    DumpInteger(string("Servo Pulse Interval"),         getPulseInterval)
    DumpAxis(string("Gyro X Axis"),                     GyroXAxisAssignment[activeModelIndex])
    DumpAxis(string("Gyro Y Axis"),                     GyroYAxisAssignment[activeModelIndex])
    
    if(constants#HARDWARE_VERSION == 3)
       DumpAxis(string("Gyro Z Axis"),                  gyroZAxisAssignment[activeModelIndex])
       
    DumpSwitch(string("Reverse Pitch Gyro"),            getReversePitchGyro)        
    DumpSwitch(string("Reverse Roll Gyro"),             getReverseRollGyro)
    
    if(constants#HARDWARE_VERSION == 3)
        DumpSwitch(string("Reverse Yaw Gyro"),          getreverseYawGyro)
        
    DumpInteger(string("Servo 1 Theta"),                getServo1theta)
    DumpInteger(string("Servo 2 Theta"),                getServo2theta)
    DumpInteger(string("Servo 3 Theta"),                getServo3theta)
    
    DumpInteger(string("Servo 1 Trim"),                 getServo1Trim)
    DumpInteger(string("Servo 2 Trim"),                 getServo2Trim)
    DumpInteger(string("Servo 3 Trim"),                 getServo3Trim)
    if(constants#HARDWARE_VERSION == 3)
       DumpInteger(string("Tail Servo Trim"),           getTailServoTrim)        
        
    DumpSwitch(string("Reverse Servo 1 "),              getServo1reverse)
    DumpSwitch(string("Reverse Servo 2 "),              getServo2reverse)
    DumpSwitch(string("Reverse Servo 3 "),              getServo3reverse)
    
    if(constants#HARDWARE_VERSION == 3)
       DumpSwitch(string("Reverse Tail Servo "),        getTailServoReverse)
       
      
      

    '----------------
    

               
PRI EditParameters | response
  '---------------------------------------------------------------------------------
  ' Use Robert Quattlebaum's Settings object to store/retrieve parameters in eeprom
  '  allowing user to edit them via serial/USB to serial terminal tool
  '---------------------------------------------------------------------------------

  lastModelIndex := activeModelIndex

  serio.tx($D)
  serio.str(string("PhuBar v"))
  serio.str(constants.SoftwareVersion)
  serio.tx($D)
  serio.str(string("return or button"))
  serio.tx($D)
  response := RXorDisconnect
    
  if(response == -1) 'No char came in, user must have disconnected, so we are done
       return
       
  if(((response) == "A") or ((response) == "B") or ((response) == "C") or ((response) == "D"))          
       TextStarMenu          'User hits a button on TextStar go into TextStar edit mode 
       return      

  repeat
    serio.tx($D)    
    serio.str(string("PhuBar Main Menu:"))   
    serio.tx($D)       
    serio.str(string("(t)une, (s)etup (e)xit+save, (q)uit, (m)odels, (r)estore defaults"))
    serio.tx($D)
    response := RXorDisconnect

    if(response == -1)        ' Considered the same as a quit
       UpdateParmsFromEeprom  ' Needed to prevent lockup ???
       QUIT
    
    if((response) == "q")
       serio.tx($D)
       serio.str(string("Quitting...reverting to last saved model and its parameters "))
       serio.str(string("..."))
       serio.tx($D)
       UpdateParmsFromEeprom                'Revert parms from eeprom
       serio.str(string("Active Model is now: "))
       serio.str(@activeModelIndex)
       serio.str(string(": "))
       serio.str(@modelName[ActiveModelIndex])        
       serio.tx($D)
       serio.str(string("Done."))
       serio.tx($D)
       QUIT
       
    if((response) == "s")               'Go to setup menu
       Setup
       NEXT
       
    if((response) == "r")
       serio.str(string("Are you sure you want to erase existing models 1-10 ?"))
       serio.tx($D)
       response := RXorDisconnect
       if(response == -1) 
          QUIT
       if(response == "y")      
          serio.str(string("Restoring factory defaults"))
          serio.str(string("..."))
          serio.tx($D)
          SetDefaults
          serio.str(string("Done. You still must (e)xit+save to make this permanent."))
          serio.tx($D)
       NEXT
              
    if((response) == "m")
       serio.tx($D)
       Models
       NEXT
       
    if((response) == "e")
      serio.str(string("Saving parameters to eeprom..."))      
       if(SaveParmsToEeprom == -1)
          serio.str(string("Commit Aborted"))   
       else
          serio.str(string("Done."))
       serio.tx($D)
       QUIT
      
    if((response) == "t")
        Tune
  return

PRI Tune  | response
  
  repeat
    serio.tx($D)
    serio.str(string("Tuning Menu:"))
    serio.tx($D)   
    serio.str(string("(l)ist, (c)hange, (m)ain menu  "))

    response := RXorDisconnect

    if(response == -1) 
       QUIT
    
    if((response) == "m")
       serio.tx($D)
       serio.str(string("Back to main menu... "))
       QUIT
             
    if((response) == "l")               'Go back to start of loop
       DumpTuningParameters
       NEXT
      
    if((response) == "c")
       EditInteger(string("Pitch Rate Gain"),      @pitchRateGain[activeModelIndex],        0,100    )
       EditInteger(string("Pitch Angular Gain"),   @pitchAngularGain[activeModelIndex],     0,100    )
       EditInteger(string("Roll Rate Gain"),       @rollRateGain[activeModelIndex],         0,100    )
       EditInteger(string("Roll Angular Gain"),    @rollAngularGain[activeModelIndex],      0,100    )
       EditInteger(string("Angular Decay"),        @angularDecay[activeModelIndex],         0,300    )
       EditInteger(string("Phase Angle"),          @phaseAngle[activeModelIndex],           -90,90   )         
       EditInteger(string("Swash Ring"),           @swashRing[activeModelIndex],            25,100   )         
       EditInteger(string("Collective Limit"),     @collectiveLimit[activeModelIndex],      25,100    )

       '----------------------
       ' For PhuBar3
      if(constants#HARDWARE_VERSION == 3)

          EditInteger(string("Yaw Rate Gain"),     @yawRateGain[activeModelIndex],0,100             )
          EditInteger(string("Yaw Angular Gain"),  @yawAngularGain[activeModelIndex],0,100          )
          EditInteger(string("HH Deadband"),       @headingHoldDeadband[activeModelIndex],0,2000    )
          setHeadingHoldActive(EditSwitch (string("HH On"),  getheadingHoldActive ))
      '----------------------
      serio.tx($D)
      
  RETURN
    
PRI Setup | response
  
  repeat
    serio.tx($D)
    serio.str(string("Setup Menu:"))
    serio.tx($D)   
    serio.str(string("(l)ist, (c)hange, (m)ain menu "))
    
    'if(constants#HARDWARE_VERSION == 3)
      serio.str(string(", (g)yro-auto-setup"))
        'serio.tx($D)

    serio.str(string(", (s)ervo-auto-setup"))
      'serio.tx($D)

    serio.str(string(", (h)old servos"))
    serio.tx($D)

        
    response := RXorDisconnect

    if(response == -1) 'No char came in, user must have disconnected, so we are done
       QUIT
    
    if((response) == "m")
       serio.tx($D)
       serio.str(string("Back to main menu... "))
       QUIT
       
    'if(constants#HARDWARE_VERSION == 3)
    if((response) == "g")               'Go to auto-setup wizard
         GyroAutoSetup
         NEXT

    if((response) == "s")               'Go to auto-setup wizard
        ServoAutoSetup
        NEXT
                    
    if((response) == "l")               'Go back to start of loop
       DumpSetupParameters
       NEXT
      
    if((response) == "c")
      EditString (string("Model Name"),           @modelName[activeModelIndex*4]             )
      EditInteger(string("Servo Pulse Interval"), @pulseInterval[activeModelIndex],5,20      )
      EditAxis   (string("Gyro X Axis"),          @gyroXAxisAssignment[activeModelIndex]     )
      EditAxis   (string("Gyro Y Axis"),          @gyroYAxisAssignment[activeModelIndex]     )

      if(constants#HARDWARE_VERSION == 3)
          EditAxis   (string("Gyro Z Axis"),      @gyroZAxisAssignment[activeModelIndex]     )

      setReversePitchGyro(EditSwitch (string("Reverse Pitch Gyro"),   getreversePitchGyro    ))
      setReverseRollGyro(EditSwitch (string("Reverse Roll Gyro"),     getreverseRollGyro     ))

      if(constants#HARDWARE_VERSION == 3)
         setReverseYawGyro( EditSwitch (string("Reverse Yaw Gyro"),     getReverseYawGyro    ))

      EditInteger(string("Servo 1 Theta"),        @servo1theta[activeModelIndex],-360,360    )
      EditInteger(string("Servo 2 Theta"),        @servo2theta[activeModelIndex],-360,360    )
      EditInteger(string("Servo 3 Theta"),        @servo3theta[activeModelIndex],-360,360    )

      setServo1reverse( EditSwitch (string("Reverse Servo 1 "),     getServo1reverse         ))
      setServo2Reverse( EditSwitch (string("Reverse Servo 2 "),     getServo2reverse         ))
      setServo3Reverse( EditSwitch (string("Reverse Servo 3 "),     getServo3reverse         ))
      
      if(constants#HARDWARE_VERSION == 3)      
          setTailServoReverse( EditSwitch (string("Reverse Tail Servo"), getTailServoReverse ))
           
      EditInteger(string("Servo 1 Trim"),         @servo1Trim[activeModelIndex],-10,10       )
      EditInteger(string("Servo 2 Trim"),         @servo2Trim[activeModelIndex],-10,10       )
      EditInteger(string("Servo 3 Trim"),         @servo3Trim[activeModelIndex],-10,10       )

      if(constants#HARDWARE_VERSION == 3)
          EditInteger(string("Tail Servo Trim"),  @tailServoTrim[activeModelIndex],-10,10    )

    if((response) == "h")               'Go to hold servos functionality
       HoldServos
       NEXT
     
 

          
      '----------------------

      serio.tx($D)
  return


PRI DumpInteger(label, parm)
  serio.str(label)
  serio.str(string(": ["))
  serio.dec(parm)
  serio.str(string("]"))
  serio.tx($D)

PRI DumpSwitch(label, parm)  ' "Y" = reverse = TRUE,  "N" = don't reverse = FALSE
  serio.str(label)
  serio.str(string(": ["))
  
  if(parm == TRUE)
     serio.str(string("Y"))
  else
     serio.str(string("N"))
       
  serio.str(string("]"))
  serio.tx($D)

PRI DumpAxis(label, parm)  ' "P" = pitch,  "R" = roll,  "Y" = yaw
  serio.str(label)
  serio.str(string(": ["))
  serio.tx(parm)          
  serio.str(string("]"))
  serio.tx($D)   
   
PRI EditInteger(label, parmAddr,lowVal, highVal) | response, tempstr[11]

  serio.tx($D)
  serio.str(label)
  serio.str(string("("))
  serio.dec(lowVal)
  serio.str(string(" to "))
  serio.dec(highVal)
  serio.str(string(")")) 
  serio.str(string(": ["))
  serio.dec(long[parmAddr])
  serio.str(string("] -> "))

  serio.getStr(@tempstr)
  if(byte[@tempstr][0] <> 0)               'If user hit return without entering a value, don't
     response := serio.StrToDec(@tempstr)  ' count it as a zero value
     if((response) => lowVal AND (response =< highVal))
        long[parmAddr] := response
        serio.dec(response)

PRI EditString(label, parmAddr)| index, tempstr[15]
  serio.tx($D)
  serio.str(label)
  serio.str(string(": ["))
  serio.str(parmAddr)
  serio.str(string("] -> "))
  serio.getStr(@tempstr)

  if(byte[@tempstr][0] <> 0)               'If user hit return without entering a value, don't count it
       StoreModelName(@tempstr, activeModelIndex)
       serio.str(@tempstr)
  
  'index~
  'if(byte[@tempstr][0] <> 0)               'If user hit return without entering a value, don't count it
  '     repeat until ((byte[parmAddr][index] := byte[@tempstr][index]) == 0)
  '        index++
  '        if(index == 15)
  '           QUIT
  '     byte[parmAddr][index]~
  '     serio.str(parmAddr) 

PRI EditAxis(label, parmAddr) | response, tempstr[11]

  serio.tx($D)
  serio.str(label)
  serio.str(string("((P)itch, (R)oll), (Y)aw"))
  serio.str(string(": ["))
  serio.str(parmAddr)          
  serio.str(string("] -> "))
  serio.GetStr(@tempstr)
  serio.str(@tempstr)
 
  if(strcomp(@tempstr,String("P")) or strcomp(@tempstr,String("p")))
    long[parmAddr] := "P"
    
  elseif(strcomp(@tempstr,String("R")) or strcomp(@tempstr,String("r"))) 
    long[parmAddr] := "R"
   
  elseif(strcomp(@tempstr,String("Y")) or strcomp(@tempstr,String("y"))) 
    long[parmAddr] := "Y"
    
 
  
PRI EditSwitch(label, parm) | tempstr[11]

  serio.tx($D)
  serio.str(label)
  serio.str(string("("))
  serio.str(string("Y or N"))
  serio.str(string(")")) 
  serio.str(string(": ["))
  
  if(parm == TRUE)
     serio.str(string("Y"))
     RESULT := TRUE
  else
     serio.str(string("N"))
     RESULT := FALSE
     
  serio.str(string("] -> "))
  serio.GetStr(@tempstr)
  serio.str(@tempstr)
  
  if(strcomp(@tempstr,String("Y")) or strcomp(@tempstr,String("y")))
    RESULT := TRUE 
  elseif(strcomp(@tempstr,String("N")) or strcomp(@tempstr,String("n"))) 
    RESULT := FALSE


PRI Models  | response
  
  repeat
    serio.tx($D)
    serio.str(string("Models Menu:"))
    serio.tx($D)   
    serio.str(string("(l)ist, (s)elect, (c)opy, (m)ain menu  "))

    response := RXorDisconnect

    if(response == -1) 
       QUIT
    
    if((response) == "l")
       ListModels
       NEXT
    
    if((response) == "s")
       SelectModel
       NEXT
     
    if((response) == "c")
       CopyModel
       NEXT
       
    if((response) == "m")
       serio.tx($D)
       serio.str(string("Back to main menu... "))
       QUIT

  RETURN
  
PRI StrToDec(stringptr) : value | char, index, multiply

    '' Converts a zero terminated string representation of a decimal number to a value

    value := index := 0
    repeat until ((char := byte[stringptr][index++]) == 0)
       if char => "0" and char =< "9"
          value := value * 10 + (char - "0")
    if byte[stringptr] == "-"
       value := - value
             
PRI CopyModel   | fm, tm , tempstr

  serio.tx($D)
  serio.str(string("From Model ? "))
  serio.getStr(@tempstr)
  serio.str(@tempstr)
  serio.tx($D)

  if(byte[@tempstr][0] == 0)    'If user hit return without entering a value, exit
      RETURN
      
  fm := StrToDec(@tempstr) - 1  
  serio.str(string("To Model ? "))
  serio.getStr(@tempstr)
  serio.str(@tempstr) 
  serio.tx($D)


  if(byte[@tempstr][0] == 0)              
      RETURN
      
  tm := StrToDec(@tempstr) - 1

  CopyModelName(fm, tm)
  pitchAngularGain[tm]     := pitchAngularGain[fm]
  pitchRateGain[tm]        := pitchRateGain[fm]
  rollAngularGain[tm]      := rollAngularGain[fm]
  rollRateGain[tm]         := rollRateGain[fm] 
  angularDecay[tm]         := angularDecay[fm]
  phaseAngle[tm]           := phaseAngle[fm] 
  pulseInterval[tm]        := pulseInterval[fm]
  gyroXAxisAssignment[tm]  := gyroXAxisAssignment[fm]
  gyroYAxisAssignment[tm]  := gyroYAxisAssignment[fm] 
  servo1theta[tm]          := servo1theta[fm]
  servo2theta[tm]          := servo2theta[fm]  
  servo3theta[tm]          := servo3theta[fm]
  servo1Trim[tm]           := servo1Trim[fm] 
  servo2Trim[tm]           := servo2Trim[fm] 
  servo3Trim[tm]           := servo3Trim[fm] 
  tailServoTrim[tm]        := tailServoTrim[fm] 
  yawAngularGain[tm]       := yawAngularGain[fm] 
  yawRateGain[tm]          := yawRateGain[fm] 
  gyroZAxisAssignment[tm]  := gyroZAxisAssignment[fm]
  headingHoldDeadband[tm]  := headingHoldDeadband[fm] 
  swashRing[tm]            := swashRing[fm] 
  collectiveLimit[tm]      := collectiveLimit[fm]
  flags[tm]                := flags[fm] 
  
  serio.tx($D)
  serio.str(string("Model "))
  serio.dec(fm + 1)
  serio.str(string("copied to model "))
  serio.dec(tm + 1)
  serio.tx($D)
 
  RETURN
    
PRI ListModels | index
   serio.tx($D)
   repeat index from 0 to 9
      serio.dec(index+1)
      serio.str(string(": "))
      serio.str(@modelName[index*4])
      if(activeModelIndex == index)
         serio.str(String(" < current"))
      serio.tx($D)

        
PRI SelectModel  | response, index, tempstr[3]
  serio.tx($D)
  serio.str(string("Choose Model (1 thru 10)-> "))
  response := serio.getStr(@tempstr)

  IF( strsize(@tempstr) > 0)  
    IF(strsize(@tempstr) == 2) ' take anything > 9 as 10
       response := 10
    else
       response := LONG[@tempstr] -48   'convert single char to dec
       serio.dec(response)
       serio.tx($D)
      if((response < 1) or (response > 9))
          response := 1
    
    
    serio.str(string("Switching to model "))
    serio.dec(response)
    serio.tx($D)
    lastModelIndex := activeModelIndex
    activeModelIndex := response -1  'Convert ascii char to equiv numeral 0 thru 9

PRI ServoAutoSetup | response, sm_cog, s1, s2, s3, s4

  sm.Stop
  sm_cog := sm.Start(@s1, @s2, @s3, @s4, GetPulseInterval)  
  if(not sm_cog)
    utilities.SignalError
    
  serio.str(string("Swashplate Servo Auto-Setup"))
  serio.tx($D)
  serio.tx($D)
  serio.str(string("Servos will now be centered, Hit enter to continue..."))
  serio.tx($D)
  serio.rx
  sm.CenterServos
  serio.str(string("Servo 1 will now be moved. Hit enter to continue..."))
  serio.tx($D)
  serio.rx
  sm.TestServo1Positive
  serio.str(string("Did Servo1 move the swashplate (u)p or (d)own ?..."))
  serio.tx($D)
  response := serio.rx     
  if(response => "u")
      setservo1Reverse(TRUE)
  else
      setservo1Reverse(FALSE)
    
  sm.CenterServos
  serio.str(string("Servo 2 will now be moved. Hit enter to continue..."))
  serio.tx($D)
  serio.rx
  sm.TestServo2Positive
  serio.str(string("Did Servo 2 move the swashplate (u)p or (d)own ?..."))
  serio.tx($D)
  response := serio.rx
  if(response => "u")
      setservo2Reverse(TRUE)
  else
      setservo2Reverse(FALSE)

  sm.CenterServos
  serio.str(string("Servo 3 will now be moved. Hit enter to continue..."))
  serio.tx($D)
  serio.rx
  sm.TestServo3Positive
  serio.str(string("Did Servo 3 move the swashplate (u)p or (d)own ?..."))
  serio.tx($D)
  response := serio.rx     
  if(response => "u")
      setservo3Reverse(TRUE)
  else
      setservo3Reverse(FALSE)

  sm.CenterServos
  serio.str(string("Finished servo setup, returning to setup menu..."))
  serio.tx($D)
  sm.Stop
 
          
PRI GyroAutoSetup  | revsense
  '-----------------------------------------------------------------
  ' Help the user set the gyro axis assignments and servo reversals
  '-----------------------------------------------------------------
 
  outa[constants#STATUS_LED_PIN]~  'Turn off LED
  
  serio.str(string("Gyro Auto-Setup"))
  serio.tx($D)
  serio.str(string("It is assumed the unit is installed squared to the airframe."))
  serio.tx($D)
  serio.str(string("If not, power down now and re-attach it."))
  serio.tx($D)
  serio.str(string("Set Helicopter on level surface, then hit enter..."))
  serio.tx($D)
  serio.rx
  serio.str(string("Please wait while gyro is reinitialized..."))
  serio.tx($D)
  
  pitchFilterBias := 0
  rollFilterBias  := 0
  yawFilterBias   := 0
  
  if(constants#HARDWARE_VERSION == 2)
      gyrofiltercog := gyrofilter.start(@gyroYrate, @gyroXrate, @pitchGyroZero, @rollGyroZero, @gyroTemp, constants#STATUS_LED_PIN, @pitchFilterBias, @rollFilterBias)
     
  if(constants#HARDWARE_VERSION == 3)
      itg3200.Stop
      'eeprom.Stop
      gyroFilterCog := itg3200.start(@gyroXrate, @gyroYrate, @gyroZrate, @pitchGyroZero, @rollGyroZero, @yawGyroZero, @gyroTemp, constants#STATUS_LED_PIN)

  utilities.pause(3000)
  serio.str(string("Done."))
  serio.tx($D)  
  outa[constants#STATUS_LED_PIN]~~  'Turn on LED

  
  '------------------------------------------------------------
  ' Determine pitch axis and sense

  gyroXvalue := 0
  gyroYvalue := 0
  gyroZvalue := 0
    
  serio.str(string("Now, tilt nose of helicopter down and hold it, then hit enter..."))
  serio.tx($D) 
 
  repeat
    if(||gyroXrate > 5)
       gyroXvalue += gyroXrate - rollfilterbias
    if(||gyroYrate > 5)
       gyroYvalue += gyroYrate - pitchfilterbias
    if(||gyroZrate > 5)
       gyroZvalue += gyroZrate
    utilities.pause(10)
    if(serio.rxcheck <> -1)
       QUIT
       
  serio.dec(gyroXvalue)
  serio.tx($D)
  serio.dec(gyroYvalue)
  serio.tx($D)
  serio.dec(gyroZvalue)
  serio.tx($D)
  

  if((||gyroYvalue => ||gyroXValue) and (||gyroYvalue => ||gyroZValue))   'Pitch axis is Y axis
       gyroYAxisAssignment[activeModelIndex] := "P"
         if(gyroYvalue > 0)  'if positive, reverse the gyro
              setReversePitchGyro(TRUE)
         else
              setReversePitchGyro(FALSE)

  elseif((||gyroXvalue => ||gyroYValue) and (||gyroXvalue => ||gyroZValue))
       gyroXAxisAssignment[activeModelIndex] := "P"
         if(gyroXvalue > 0)  'if positive, reverse the gyro
              setReversePitchGyro(TRUE)
         else
              setReversePitchGyro(FALSE)
  else
       gyroZAxisAssignment[activeModelIndex] := "P"
         if(gyroZvalue > 0)  'if positive, reverse the gyro
              setReversePitchGyro(TRUE)
         else
              setReversePitchGyro(FALSE)

  '-----------------------------------------------------------
  ' Determine roll axis and sense
  
  gyroXvalue := 0
  gyroYvalue := 0
  gyroZvalue := 0
    
  serio.str(string("Set Helicopter on level surface, then hit enter."))
  serio.tx($D)
  serio.rx   '
  serio.str(string("Now, roll helicopter to the right and hold it, then hit enter..."))
  serio.tx($D) 

  
  repeat
    if(||gyroXrate > 5)
       gyroXvalue += gyroXrate
    if(||gyroYrate > 5)
       gyroYvalue += gyroYrate
    if(||gyroZrate > 5)
       gyroZvalue += gyroZrate
    utilities.pause(10)
    if(serio.rxcheck <> -1)
       QUIT
       
  serio.dec(gyroXvalue)
  serio.tx($D)
  serio.dec(gyroYvalue)
  serio.tx($D)
  serio.dec(gyroZvalue)
  serio.tx($D)

  ' ITG3200 has opposite x axis sense than IDG500 did, so we reverse the
  ' gyro axes differently between the two versions of hardware
  '
  'revsense := FALSE    
  'if(constants#HARDWARE_VERSION == 2)
  '   revsense := FALSE
  
  
  if((||gyroYvalue => ||gyroXValue) and (||gyroYvalue => ||gyroZValue))   'Roll axis is Y axis
       gyroYAxisAssignment[activeModelIndex] := "R"
         if(gyroYvalue > 0)  'if positive, reverse the gyro
              setReverseRollGyro(FALSE)
         else
              setReverseRollGyro(TRUE)

  elseif((||gyroXvalue => ||gyroYValue) and (||gyroXvalue => ||gyroZValue))
       gyroXAxisAssignment[activeModelIndex] := "R"
         if(gyroXvalue > 0)  'if positive, reverse the gyro
              setReverseRollGyro(FALSE)
         else
              setReverseRollGyro(TRUE)
  else
       gyroZAxisAssignment[activeModelIndex] := "R"
         if(gyroZvalue > 0)  'if positive, reverse the gyro
              setReverseRollGyro(FALSE)
         else
              setReverseRollGyro(TRUE)

  '--------------------------------------
  ' For PhuBar3 determine Yaw axis and sense
  
  if(constants#HARDWARE_VERSION == 3)
     serio.str(string("Set Helicopter on level surface, then hit enter."))
     serio.tx($D)
     serio.rx   '
     serio.str(string("Now, yaw the helicopter to the right (clockwise) and hold it, then hit enter..."))
     serio.tx($D) 
     gyroXvalue := 0
     gyroYvalue := 0
     gyroZvalue := 0
  
     repeat
       if(||gyroXrate > 5)
          gyroXvalue += gyroXrate
       if(||gyroYrate > 5)
          gyroYvalue += gyroYrate
       if(||gyroZrate > 5)
          gyroZvalue += gyroZrate       
       utilities.pause(10)
       if(serio.rxcheck <> -1)
          QUIT
       
     serio.dec(gyroXvalue)
     serio.tx($D)
     serio.dec(gyroYvalue)
     serio.tx($D)
     serio.dec(gyroZvalue)
     serio.tx($D)
    
     if((||gyroYvalue => ||gyroXValue) and (||gyroYvalue => ||gyroZValue))   'Yaw axis is Y axis
       gyroYAxisAssignment[activeModelIndex] := "Y"
         if(gyroYvalue > 0)  'if positive, reverse the gyro
              setReverseYawGyro(FALSE)
         else
              setReverseYawGyro(TRUE)

     elseif((||gyroXvalue => ||gyroYValue) and (||gyroXvalue => ||gyroZValue))
       gyroXAxisAssignment[activeModelIndex] := "Y"
         if(gyroXvalue > 0)  'if positive, reverse the gyro
               setReverseYawGyro(FALSE)
         else
              setReverseYawGyro(TRUE)
     else
       gyroZAxisAssignment[activeModelIndex] := "Y"
         if(gyroZvalue > 0)  'if positive, reverse the gyro
              setReverseYawGyro(FALSE)
         else
              setReverseYawGyro(TRUE)

  '---------------------------------------
  
  serio.str(string("Done. Gyro Axes have been assigned. Hit return for menu."))
  serio.tx($D)
  serio.rx
  outa[constants#STATUS_LED_PIN]~  'Turn off LED
   
  if(constants#HARDWARE_VERSION == 2)     
      gyrofilter.stop
  if(constants#HARDWARE_VERSION == 3)  'Need to stop gyro so it won't clash with eeprom writes
      itg3200.stop


PRI HoldServos | sm_cog, s1, s2, s3, s4
  '----------------------------------------------------------
  ' Hold all servos centered to allow mechanical adjustments
  '----------------------------------------------------------

  serio.str(string("To hold servos centered for mechanical adjustment, hit enter..."))
  serio.tx($D)
  serio.rx

  sm.Stop

  sm_cog := sm.Start(@s1, @s2, @s3, @s4, GetPulseInterval)
  if(not sm_cog)
    utilities.SignalError
    serio.str(string("Servo manager could not be started, returning to setup menu..."))
    RETURN

  sm.CenterServos

  serio.str(string("Servos have been centered. To stop and return to main menu, hit enter..."))
  serio.tx($D)
  serio.rx

  serio.str(string("Servos no longer being held centered, returning to setup menu..."))
  serio.tx($D)

  sm.Stop


PRI TextStarMenu | response

  response := RXOrDisconnect   'Eat second char from TextStar command
  if(response == -1) 'No char came in, user must have disconnected, so we are done
      Return

  repeat             
    serio.tx($D)    
    serio.str(string("<Save     Model>"))   
    serio.tx($D)       
    serio.str(string("<Cancel  Adjust>"))
    response := TextStarCommandOrDisconnect

    if(response == -1)
       UpdateParmsFromEeprom 'Treat disconnect like a Cancel
       QUIT
               
    if(response == "A") ' Save 
        serio.tx(12)
        serio.str(string("Saving...     "))
        serio.tx(13)   
        SaveParmsToEeprom
        NEXT
        
    if(response == "B")  ' Cancel
        serio.tx(12)
        serio.str(string("Reverting..."))
        activeModelIndex := lastModelIndex 
        UpdateParmsFromEeprom                'Revert parms from eeprom
        NEXT
        
    if(response == "C")  'Select Model
       TextStarSelectModel
       NEXT
       
    if(response == "D")
       TextStarAdjust 
       NEXT
        
PRI TextStarAdjust | response

  repeat             
    serio.tx($D)    
    serio.str(string("          Setup>"))   
    serio.tx($D)       
    serio.str(string("<Exit      Tune>"))
    response := TextStarCommandOrDisconnect

    if(response == -1)
       UpdateParmsFromEeprom 'Treat disconnect like a Cancel
       QUIT
     
    if(response == "B")  ' Done
        QUIT
      
    if(response == "C")  'Setup
       TextStarSetup
       
    if(response == "D")
       TextStarTune 
       
PRI TextStarSelectModel | response, index, tempstr[MODEL_NAME_LENGTH] 

  ' Display current model
  ' Key A displays previous model letter+name(or "empty")
  ' Key B displays next model
  ' Key C selects and loads model or copies to new empty model
  '   If new model, copy current name and append letter to name
  ' Key D (done) returns
  
  index := activeModelIndex   
  serio.tx($D)  
  'serio.str(string("Mdl=")) 
  'serio.tx(activeModelIndex+1)
  serio.dec(index+1)
  serio.str(string(":"))
  serio.str(@modelName[index*4])
  serio.tx($D)
  serio.str(string("<next  "))

  
    repeat
       response := TextStarCommandOrDisconnect
       if(response == -1) 
         Quit

       if(response == "A")  'Back up one 
          if(index > 0)
             index--

       if(response == "B")  'Go forward one 
          if(index < 9)
             index++

       if(response == "C")  'Select this model
          if(activeModelIndex == index)
             Quit
          lastModelIndex := activeModelIndex
          activeModelIndex := index
          serio.tx(12)
          serio.str(string("Switching to model "))
          serio.tx(index)
          Quit
        
       if(response == "D")  'Done, quit
           Quit
         
      serio.tx(12)
      serio.dec(index+1)
      serio.str(string(":"))
      serio.str(@modelName[index*4])
      serio.tx(254)  'position cursor 4 char from end of 1st line
      serio.tx("P")
      serio.tx(1)
      serio.tx(13)
      serio.str(string("sel>"))
      serio.tx($D)
      serio.str(string("<next      quit>"))           


PRI TextStarTune | response, tempbit


    'response := RXOrDisconnect   'Eat second char from TextStar command
        
    'if(response == -1) 'No char came in, user must have disconnected, so we are done
    '    Return

    repeat
      response := TextStarEditInteger(string("Pitch Rate Gain"),   @pitchRateGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Pitch Angle Gain"),  @pitchAngularGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Roll Rate Gain"),    @rollRateGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Roll Angle Gain"),   @rollAngularGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Angular Decay"),     @angularDecay[activeModelIndex],0,300,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Phase Angle"),       @phaseAngle[activeModelIndex],-90,90,1)         
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Swash Ring"),        @swashRing[activeModelIndex],25,100,1)         
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Collective Limit"),  @collectiveLimit[activeModelIndex],25,100,1)
      if((response == "B") or (response == -1))
         QUIT

     '----------------------------------    
     ' For PhuBar3

      if(constants#HARDWARE_VERSION == 2)
        NEXT
        
      response := TextStarEditInteger(string("Yaw Rate Gain"),   @yawRateGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
        QUIT
      response := TextStarEditInteger(string("Yaw HH Gain"),     @yawAngularGain[activeModelIndex],0,100,1)
      if((response == "B") or (response == -1))
        QUIT
      response := TextStarEditInteger(string("Yaw HH Deadband"), @headingHoldDeadband[activeModelIndex],0,2000,100)
      if((response == "B") or (response == -1))
        QUIT
      response := TextStarEditSwitch (string("HH Mode On"),      getHeadingHoldActive, @tempbit) '%10000000, %01111111)   'Masks for heading hold flag
      setHeadingHoldActive(tempbit)
      if((response == "B") or (response == -1))
        QUIT
      

             
    'return response

PRI TextStarSetup | response, tempbit

      
    repeat
      response := TextStarEditInteger(string("Srvo Pulse Int"),   @pulseInterval[activeModelIndex],5,20,1)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditAxis(string("Gyro X Axis"),         @gyroXAxisAssignment[activeModelIndex] )
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditAxis(string("Gyro Y Axis"),         @gyroYAxisAssignment[activeModelIndex] )
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditSwitch(string("Rvrse Ptch Gyro"),  getreversePitchGyro, @tempbit   )
      setReversePitchGyro(tempbit)
      if((response == "B") or (response == -1))
         QUIT      
      response := TextStarEditSwitch(string("Revrse Rol Gyro"),   getreverseRollGyro, @tempbit    )
      setReverseRollGyro(tempbit)
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditInteger(string("Servo 1 Theta"),    @servo1theta[activeModelIndex],-360,360,1  )
      if((response == "B") or (response == -1))
         QUIT      
      response := TextStarEditInteger(string("Servo 2 Theta"),    @servo2theta[activeModelIndex],-360,360,1  )
      if((response == "B") or (response == -1))
         QUIT      
      response := TextStarEditInteger(string("Servo 3 Theta"),    @servo3theta[activeModelIndex],-360,360,1  )
      if((response == "B") or (response == -1))
         QUIT
      response := TextStarEditSwitch(string("Revrse Servo 1"),    getServo1Reverse, @tempbit   )
      setServo1Reverse(tempbit)
      if((response == "B") or (response == -1))
         QUIT      
      response := TextStarEditSwitch(string("Revrse Servo 2"),    getServo2Reverse, @tempbit   )
      setServo2Reverse(tempbit)
      if((response == "B") or (response == -1))
         QUIT      
      response := TextStarEditSwitch(string("Revrse Servo 3"),    getServo3Reverse, @tempbit   )
      setServo3Reverse(tempbit)
      if((response == "B") or (response == -1))
         QUIT      
    
         
           
      if(constants#HARDWARE_VERSION == 2)
        NEXT
        
      response := TextStarEditAxis(string("Gyro Z Axis"), @gyroZAxisAssignment[activeModelIndex] )
      if((response == "B") or (response == -1))
        QUIT
      response := TextStarEditSwitch(string("Revrse Yaw Gyro"),   getreverseYawGyro, @tempbit    )
      setReverseYawGyro(response)
      if((response == "B") or (response == -1))
         QUIT
      
      response := TextStarEditSwitch(string("Revrse Tail Svo"),   getTailServoReverse, @tempbit    )
      setTailServoReverse(response)
      if((response == "B") or (response == -1))
         QUIT
      
       

                       
PRI TextStarEditAxis(label, parmaddr) | response

  repeat
     serio.tx(12)
     serio.str(label)
     serio.tx(13)
     serio.str(string("<exit     "))
     serio.str(parmAddr)
     response := TextStarCommandOrDisconnect
     
     if(response == -1) 'No char came in, user must have disconnected, so we are done
        QUIT     
     if((response == "C") or (response == "D")) ' Increment value 
         if(long[parmAddr] == "R")  
            long[parmAddr] := "P"     
         elseif(long[parmAddr] == "P")
                long[parmAddr] := "Y"                   
         elseif(long[parmAddr] == "Y")
                long[parmAddr] := "R"   
     if((response == "A") or (response == "B")) ' Done with this parameter
        QUIT

  return response
 
PRI TextStarEditSwitch(label, value, parmAddr) | response

  long[parmAddr] := value  
  repeat
     serio.tx(12)
     serio.str(label)
     serio.tx(13)
     serio.str(string("<exit     "))
     if(long[parmAddr] <> 0)
        serio.str(string("Y"))
     else
        serio.str(string("N"))
     serio.tx(13)
     response := TextStarCommandOrDisconnect
     
     if((response == "A") or (response == "B")) ' Done with this parameter
        QUIT
     if(response == -1) 'No char came in, user must have disconnected, so we are done
        QUIT
             
     if((response == "C") or (response == "D")) ' Change Value to opposite
         if(long[parmAddr] == 1)   'If flag set
            long[parmAddr] := 0     'Then unset it
         else
            long[parmAddr] := 1     'Otherwise, set it              

  return response
      
PRI TextStarEditInteger(label, parmAddr,lowVal, highVal, increment) | response

  repeat
     serio.tx(12)
     serio.str(label)
     serio.tx(13)
     serio.str(string("<exit     "))
     serio.dec(long[parmAddr])
     serio.tx(13)
     response := TextStarCommandOrDisconnect
     if(response == -1) 'No char came in, user must have disconnected, so we are done
        QUIT     
     if(response == "C") ' Increase Value
        long[parmAddr] := highVal <# (long[parmAddr] + increment)
       
     if(response == "D") ' Decrease Value
        long[parmAddr] := lowVal #> (long[parmAddr] - increment)
        
     if((response == "A") or (response == "B")) ' Done with this parameter
        QUIT

  return response

PRI TextStarCommandOrDisconnect : rxbyte 

  ' Waits for receive line to go low, either from user disconnecting the cable, or
  '  from user sending a command from the serial terminal
  '  Waits 20ms to give time for a character to finish coming in
  '  Returns -1 (from rxcheck) if no character was received
  
  repeat until (ina[constants#SERIAL_RX_PIN] == 0)
  utilities.pause(20)       ' Give time for both characters to come in from button press/release
  rxbyte := serio.rxcheck   ' get the first char from button pres
  serio.rx                  ' eat the second char from button release, we don't need it

                    
