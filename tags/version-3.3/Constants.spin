{
  Global Constants used in multiple objects
}


CON
  STATUS_LED_PIN       = 3   'LED to signal status of PhUBar
  SERIAL_TX_PIN        = 30
  SERIAL_RX_PIN        = 31

  YAW_LIMIT            = 244_000  'Equates to about 180 degrees of yaw travel
                                  'that we track before we stop integrating it
  SWASH_YAW_INCREMENT  = 2      ' Degrees we must yaw before we bother with
                                ' using yaw to rotate pitch and roll values                            

  HARDWARE_VERSION     = 3      ' 2 is PhuBar2 2-axis.   3 is PhuBar3 3-axis
                                ' This is the main switch to change when going
                                ' back and forth maintaining the two versions
  
  PB2_EEPROMOffset     = $0000  ' $0000 for 32kb eeprom,  $8000 for 64kb eeprom.
                                ' If 64kb eeprom is present, changing this offset
                                ' to $8000 allows PhuBar setup parameters to persist
                                ' between firmware updates.
  PB3_EEPROMOffset     = $8000

  PB2_EEPROMPageSize   = 64

  PB3_EEPROMPageSize   = 128
                                
  PB2_RX_AILERON_PIN   = 18     'PhuBar2 pin assignments   
  PB2_RX_ELEVATOR_PIN  = 17     
  PB2_RX_AUX_PIN       = 16
  PB2_RX_RUDDER_PIN    = 15
  PB2_SERVO_1_PIN      = 14
  PB2_SERVO_2_PIN      = 13
  PB2_SERVO_3_PIN      = 12
  PB2_SERVO_4_PIN      = 11
  
                                
  PB3_RX_AILERON_PIN   = 21    ' Pin assignments changed from PhuBar2 to PhuBar3
  PB3_RX_ELEVATOR_PIN  = 20    ' in order to make the pcb smaller
  PB3_RX_AUX_PIN       = 19
  PB3_RX_RUDDER_PIN    = 16
  PB3_SERVO_1_PIN      = 15
  PB3_SERVO_2_PIN      = 11
  PB3_SERVO_3_PIN      = 10
  PB3_SERVO_4_PIN      = 9
  
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
 if(HARDWARE_VERSION     == 2)
    return PB2_EEPROM_PARMS_START
 else
    return PB3_EEPROM_PARMS_START
           