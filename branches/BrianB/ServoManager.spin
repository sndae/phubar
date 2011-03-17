'' Servo Manager
''
''  Based on Gavin Garner's Three-Servo-Assembly object from the Propeller Object Exchange
''
''   Modified to get servo pin assignments from constants.spin, overriding the defaults set
''     in the DAT block
''
''   Also modified to handle 4 servos
'' 
''   Note that as written this code assumes a clock speed of 80mHz
''
''   Note that LowTime is calculated from the pulseInterval parameter in milliseconds
''
''
OBJ
  constants  : "Constants"
  utilities  : "Utilities"
CON
  SERVO_MAX    = 160_000
  SERVO_CENTER = 120_000 
  SERVO_MIN    =  80_000
                                          
VAR
  long servocog
                                                                                                                              
PUB Start(pos1address, pos2address, pos3address, pos4address, pulseInterval)  :okay
                                                                                     
  p1:=pos1address     'Stores the address of the "position1" variable in the main Hub RAM as "p1"
  p2:=pos2address     'Stores the address of the "position2" variable in the main Hub RAM as "p2"
  p3:=pos3address     'Stores the address of the "position3" variable in the main Hub RAM as "p3"
  p4:=pos4address     'Stores the address of the "position4" variable in the main Hub RAM as "p4" 
  
  ServoPin1 := |< constants.GetSERVO_1_PIN     ' Set pins based on common constants file
  ServoPin2 := |< constants.GetSERVO_2_PIN     ' Overrides defaults in DAT section
  ServoPin3 := |< constants.GetSERVO_3_PIN
  ServoPin4 := |< constants.GetSERVO_4_PIN
    
  LowTime := pulseInterval * 80_000            ' Overrides defaults in DAT section  
  Stop
  CenterServos                             'Servos need to start at center to begin working right
  okay:= servocog:=cognew(@FourServos,0)   'Start a new cog and run the assembly code starting at the "FourServos" cell
      
PUB Stop
  if servocog
    cogstop(servocog)


PUB CenterServos
  LONG[p1] := LONG[p2] := LONG[p3] := LONG[p4] := SERVO_CENTER

'---------------------------------------------
' Various test routines
'---------------------------------------------
PUB TestServo1Positive
   LONG[p1] := SERVO_CENTER + 20_000

PUB TestServo2Positive
   LONG[p2] := SERVO_CENTER + 20_000

PUB TestServo3Positive
   LONG[p3] := SERVO_CENTER + 20_000

PUB TestServo4Positive
   LONG[p4] := SERVO_CENTER + 20_000

PUB TestServos                                                                                            
    LONG[p1] := LONG[p2] := LONG[p3] := LONG[p4] := SERVO_MAX                    
    waitcnt(clkfreq+cnt)
    LONG[p1] := LONG[p2] := LONG[p3] := LONG[p4] := SERVO_CENTER                 
    waitcnt(clkfreq+cnt)
    LONG[p1] := LONG[p2] := LONG[p3] := LONG[p4] := SERVO_MIN                    
    waitcnt(clkfreq+cnt)
    LONG[p1] := LONG[p2] := LONG[p3] := LONG[p4] := SERVO_CENTER

PUB TestServo4                                                                                            
    LONG[p4] := SERVO_CENTER + 15000                    
    waitcnt(clkfreq+cnt)
    LONG[p4] := SERVO_CENTER                 
    waitcnt(clkfreq+cnt)
    LONG[p4] := SERVO_CENTER - 15000                    
    waitcnt(clkfreq+cnt)
    LONG[p4] := SERVO_CENTER
        
'----------------------------------------------------------------------------------------------------------------------------  
'The assembly program below runs on a parallel cog and checks the value of the servo position
' variables in the main Hub RAM (which other cogs can change at any time). It then outputs three servo high pulses (back to
' back) each corresponding to the three position variables (which represent the number of system clock ticks during which
' each pulse is outputed) and sends a 10ms low part of the pulse. It repeats this signal continuously and changes the width
' of the high pulses as the variables are changed by other cogs.
'----------------------------------------------------------------------------------------------------------------------------
DAT
FourServos   org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM                                                                                                                     
Loop          mov       dira,ServoPin1    'Set the direction of the "ServoPin1" to be an output (and all others to be inputs)  
              rdlong    HighTime,p1       'Read the "position1" variable from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address 
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin1 high b/c rest are inputs)               
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin1 low b/c rest are inputs)

              mov       dira,ServoPin2    'Set the direction of the "ServoPin2" to be an output (and all others to be inputs)  
              rdlong    HighTime,p2       'Read the "position2" variable from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address 
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin2 high b/c rest are inputs)               
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin2 low b/c rest are inputs)
              
              mov       dira,ServoPin3    'Set the direction of the "ServoPin3" to be an output (and all others to be inputs)  
              rdlong    HighTime,p3       'Read the "position3" variable from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address 
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin3 high b/c rest are inputs)               
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin3 low b/c rest are inputs)

              mov       dira,ServoPin4    'Set the direction of the "ServoPin4" to be an output (and all others to be inputs)  
              rdlong    HighTime,p4       'Read the "position4" variable from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address    
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin4 high b/c rest are inputs)            
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,LowTime   'Wait until "cnt" matches "counter" then add a 20ms delay to "counter" value 
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin4 low b/c rest are inputs)
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              jmp       #Loop             'Jump back up to the cell labled "Loop"                                      
                                                                                                                    
'Constants and Variables:
ServoPin1     long      |<     14 '<------- This sets the pin that outputs the first servo signal (which is sent to the white
                                          ' wire on most servomotors). Here, this "6" indicates Pin 6. Simply change the "6" 
                                          ' to another number to specify another pin (0-31).
ServoPin2     long      |<     13 '<------- This sets the pin that outputs the second servo signal (could be 0-31). 
ServoPin3     long      |<     12 '<------- This sets the pin that outputs the third servo signal (could be 0-31).
ServoPin4     long      |<     11 '<------- This sets the pin that outputs the third servo signal (could be 0-31).
p1            long      0                 'Used to store the address of the "position1" variable in the main RAM
p2            long      0                 'Used to store the address of the "position2" variable in the main RAM  
p3            long      0                 'Used to store the address of the "position3" variable in the main RAM
p4            long      0                 'Used to store the address of the "position4" variable in the main RAM
AllOn         long      $FFFFFFFF         'This will be used to set all of the pins high (this number is 32 ones in binary)
LowTime       long      800_000           'This works out to be a 10ms pause time with an 80MHz system clock. If the
                                          ' servo behaves erratically, this value can be changed to 1_600_000 (20ms pause)                                  
counter       res                         'Reserve one long of cog RAM for this "counter" variable                     
HighTime      res                         'Reserve one long of cog RAM for this "HighTime" variable
              fit                         'Makes sure the preceding code fits within cells 0-495 of the cog's RAM

{Copyright (c) 2008 Gavin Garner, University of Virginia

MIT License: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and
this permission notice shall be included in all copies or substantial portions of the Software. The software is provided
as is, without warranty of any kind, express or implied, including but not limited to the warrenties of noninfringement.
In no event shall the author or copyright holder be liable for any claim, damages or other liablility, out of or in
connection with the software or the use or other dealings in the software.}
                
