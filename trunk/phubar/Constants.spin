{{
  Global Constants used in multiple objects

  Accessors allow switching between PhuBar2 hardware and PhuBar3 hardware
  by changing the value of HARDWARE_VERSION
   
}}


PUB SoftwareVersion
   return string("3.3.3")   'Current version 

{    Versions
        3.3.3  In progress
               Added all setup parms to TextStar code, except model name (need keyboard to enter)
               Removed redundant StopIO in InitializeParameters
               Multiparms.Initialize - removed check for pulseInterval[0] to see if parms have been stored
                   - fixed bug where parms were being erased sometimes upon software update
                   Now it is necessary to do (r)estore defaults on first load of a new PhuBar unit.
               Added call to UpdateParmsFromEeprom whenever user disconnects PropPlug, same as Quitting
                   - fixed bug where disconnecting PropPlug 3 times in a row would cause lock-up
                     on both PropPlug and TextStar               
         3.3.2 RC_Receiver.spin now replaces MonitorRCReceiver.spin.
               Expected to cover a wider range of receivers.  Handles overlapping pulses
               across channels with 1us resolution
         3.3.1 Fix motion detect on gyro calibrate
         3.3   Swash Ring feature added  
         3.2   Model Copy function added
         3.1   Added ProcessYaw to give rate mode and HH mode to tail
               Added ability to store parameters for 10 helicopters in
               eeprom, provided a 64kbyte eeprom is on the board
         3.0   Upgrade to ITG-3200 3-axis gyro (Still supports IDG-500 for PhuBar2 also)
               Added support for parameter changes via TextStar LCD terminal
         2.0   Version using IDG-500 2-axis gyro, cyclic stabilization only,
               no tail control
}
  
CON
  HARDWARE_VERSION     = 3        ' 2 is PhuBar2 2-axis.   3 is PhuBar3 3-axis
                                  ' This is the main switch to change when going
                                  ' back and forth maintaining the two versions
 
  STATUS_LED_PIN       = 3        ' LED to signal status of PhuBar
  SERIAL_TX_PIN        = 30
  SERIAL_RX_PIN        = 31

  YAW_LIMIT            = 244_000  ' Equates to about 180 degrees of yaw travel
                                  ' that we track before we stop integrating it
  SWASH_YAW_INCREMENT  = 2        ' Degrees we must yaw before we bother with
                                  ' using yaw to rotate pitch and roll values                            

  PB2_EEPROMOffset     = $0000    ' $0000 for 32kb eeprom 
  PB3_EEPROMOffset     = $8000    ' $8000 for 64kb eeprom

  PB2_EEPROMPageSize   = 64

  PB3_EEPROMPageSize   = 128
                                
  PB2_RX_AILERON_PIN   = 18     'PhuBar2 pin assignments   
  PB2_RX_ELEVATOR_PIN  = 17     'PINMASK must match these pin assignments
  PB2_RX_AUX_PIN       = 16
  PB2_RX_RUDDER_PIN    = 15
  PB2_SERVO_1_PIN      = 14
  PB2_SERVO_2_PIN      = 13
  PB2_SERVO_3_PIN      = 12
  PB2_SERVO_4_PIN      = 11
  PB2_PINMASK          = %0000_0111_1000_0000_0000_0000  ' Mask for RC_receiver.spin
  PB2_RX_RUDDER_OFFSET = 0
  PB2_RX_AUX_OFFSET      = PB2_RX_AUX_PIN       - PB2_RX_RUDDER_PIN  ' Offsets into Pins[8] of RC_Receiver.spin
  PB2_RX_ELEVATOR_OFFSET = PB2_RX_ELEVATOR_PIN  - PB2_RX_RUDDER_PIN 
  PB2_RX_AILERON_OFFSET  = PB2_RX_AILERON_PIN   - PB2_RX_RUDDER_PIN 


                                
  PB3_RX_AILERON_PIN   = 21    ' Pin assignments changed from PhuBar2 to PhuBar3
  PB3_RX_ELEVATOR_PIN  = 20    ' in order to make the pcb smaller
  PB3_RX_AUX_PIN       = 19    ' PINMASK must match these pin assignments 
  PB3_RX_RUDDER_PIN    = 16
  PB3_SERVO_1_PIN      = 15
  PB3_SERVO_2_PIN      = 11
  PB3_SERVO_3_PIN      = 10
  PB3_SERVO_4_PIN      = 9
  PB3_PINMASK          = %0011_1001_0000_0000_0000_0000
  PB3_RX_RUDDER_OFFSET = 0
  PB3_RX_AUX_OFFSET      = PB3_RX_AUX_PIN       - PB3_RX_RUDDER_PIN  ' Offsets into Pins[8] of RC_Receiver.spin
  PB3_RX_ELEVATOR_OFFSET = PB3_RX_ELEVATOR_PIN  - PB3_RX_RUDDER_PIN 
  PB3_RX_AILERON_OFFSET  = PB3_RX_AILERON_PIN   - PB3_RX_RUDDER_PIN 
    
  PB2_NOISE            = 2
  PB2_SAMPLE_RATE_HZ   = 100
  PB2_ANGULAR_LIMIT    = 52_000  '52000 equates to roughly 45 degrees, the limit
                               'of travel we want for our virtual flybar.

  PB3_NOISE            = 4
  PB3_SAMPLE_RATE_HZ   = 100
  PB3_ANGULAR_LIMIT    = 61_000  '61000 equates to roughly 45 degrees, the limit
                               'of travel we want for our virtual flybar.

  PB2_EEPROM_PARMS_START   = 31768  'A little below top of 32Kbyte eeprom
                                    '  This may need to be decreased if vars are added
                                    '  to MultiParms.spin
  PB3_EEPROM_PARMS_START   = 32769  'start of top half of 64kbyte eeprom
    
PUB GetPINMASK
  if(HARDWARE_VERSION  == 2)
    return  PB2_PINMASK
  else
    return  PB3_PINMASK

PUB GetRX_RUDDER_OFFSET
  if(HARDWARE_VERSION  == 2)
    return  PB2_RX_RUDDER_OFFSET
  else
    return  PB3_RX_RUDDER_OFFSET
    
PUB GetRX_AUX_OFFSET
  if(HARDWARE_VERSION  == 2)
    return  PB2_RX_AUX_OFFSET
  else
    return  PB3_RX_AUX_OFFSET
 
PUB GetRX_ELEVATOR_OFFSET
  if(HARDWARE_VERSION  == 2)
    return  PB2_RX_ELEVATOR_OFFSET
  else
    return  PB3_RX_ELEVATOR_OFFSET
 
PUB GetRX_AILERON_OFFSET
  if(HARDWARE_VERSION  == 2)
    return  PB2_RX_AILERON_OFFSET
  else
    return  PB3_RX_AILERON_OFFSET
 

PUB GetNOISE
  if(HARDWARE_VERSION  == 2)
    return  PB2_NOISE
  else
    return  PB3_NOISE

PUB GetSAMPLE_RATE_HZ
  if(HARDWARE_VERSION  == 2)
    return  PB2_SAMPLE_RATE_HZ
  else
    return  PB3_SAMPLE_RATE_HZ

PUB GetANGULAR_LIMIT
  if(HARDWARE_VERSION  == 2)
    return  PB2_ANGULAR_LIMIT
  else
    return  PB3_ANGULAR_LIMIT
                                                                      
PUB GetEEPROMOffset
  if(HARDWARE_VERSION  == 2)
    return  PB2_EEPROMOffset
  else
    return  PB3_EEPROMOffset

PUB GetEEPROMPageSize
  if(HARDWARE_VERSION  == 2)
    return  PB2_EEPROMPageSize
  else
    return  PB3_EEPROMPageSize

PUB GetRX_AILERON_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_RX_AILERON_PIN
 else
    return PB3_RX_AILERON_PIN

PUB GetRX_ELEVATOR_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_RX_ELEVATOR_PIN
 else
    return PB3_RX_ELEVATOR_PIN

PUB GetRX_AUX_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_RX_AUX_PIN
 else
    return PB3_RX_AUX_PIN

PUB GetRX_RUDDER_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_RX_RUDDER_PIN
 else
    return PB3_RX_RUDDER_PIN

PUB GetSERVO_1_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_SERVO_1_PIN
 else
    return PB3_SERVO_1_PIN    

PUB GetSERVO_2_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_SERVO_2_PIN
 else
    return PB3_SERVO_2_PIN

PUB GetSERVO_3_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_SERVO_3_PIN
 else
    return PB3_SERVO_3_PIN

PUB GetSERVO_4_PIN
 if(HARDWARE_VERSION     == 2)
    return PB2_SERVO_4_PIN
 else
    return PB3_SERVO_4_PIN


PUB  getEEPROM_PARMS_START
 if(HARDWARE_VERSION  == 2)
    return PB2_EEPROM_PARMS_START
 else
    return PB3_EEPROM_PARMS_START
           