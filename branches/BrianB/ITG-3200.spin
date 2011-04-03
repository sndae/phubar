{  ITG-3200 Gyro Module   -- Jason Dorie --   
'' Note that this code assumes an 80 MHz clock \

''   Changes by Greg Glenn for use on PhuBar3
        SCL, SDA pins are 28,29.  Shared with eeprom lines

    Note that this cog must be stopped whenever the
    eeprom needs to be accessed, since there is no locking
    mechanism to insure safe sharing of the bus.

}
OBJ
 constants : "Constants"
 utilities : "Utilities"
CON 

  ITG_3200_READ  = %11010011  'Assumes AD0 is high
  ITG_3200_WRITE = %11010010
                  
  SCL = 28
  SDA = 29

  
VAR
  long PreviousTime, CurrentTime, ElapsedTime, Seconds, x, y, z, x0, y0, z0, temp
  long cog, Stack[30]
  long xaddr, yaddr, zaddr
  long xZeroAddr,  yZeroAddr, zZeroAddr
  long gyroTempAddr,statusLEDpin, noise

PUB Start(xa, ya, za, gt, xz, yz, zz, lp)
  xaddr := xa
  yaddr := ya
  zaddr := za
  gyroTempAddr := gt
  xZeroAddr := xz
  yZeroAddr := yz
  zZeroAddr := zz
  statusLEDPin := lp
  noise := constants.GetNoise


  cog := cognew(GyroLoop, @stack)
  RETURN cog

PUB Stop

  if(cog)
    cogstop(cog~)

  
PUB TestGyro : ack | value, lastTime
 
  '----------------------------------------------------------------------
  ' initialize code borrowed from i2c driver object
 
   outa[SCL] := 1                       ' reinitialized.  Drive SCL high.
   dira[SCL] := 1
   dira[SDA] := 0                       ' Set SDA as input
          
  '-----------------------------------------------------------------------
  'Give the chip some startup time to stabilize 
  waitcnt( constant(80_000_000 / 100) + cnt )
  
  StartSend
  'waitcnt(clkfreq/100 +cnt) 
  ack := WriteByte( ITG_3200_READ )    ' itg3200 address  
  'ack := WriteByte( %10100001 )    ' eeprom address   
  'ack := WriteByte( %11010010 )   ' high AD0
  'ack := WriteByte( %11010000 )   ' low AD0
  'ack := WriteByte( %11110010 )   'bad address
  'ack := WriteByte( $A0 )  ' eeprom address
  StopSend
  
  return ack

  
PUB GyroLoop | value, ack, lastTime, firstx0, secondx0

  outa[SCL] := 1                       ' reinitialized.  Drive SCL high.
  dira[SCL] := 1
  dira[SDA] := 0                       ' Set SDA as input

  repeat 9
      outa[SCL] := 0                    ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                      ' Repeat if SDA not driven high
         quit
         
  'Give the chip some startup time to stabilize
  waitcnt( constant(80_000_000 / 100) + cnt )

  'DLPF_CFG values set the low-pass filter:  0=256hz, 1=188hz, 2=98hz,3=42hz,4=20hz,5=10hz,6=5hz

  WriteRegisterByte( 22, $18 + $6 )     ' DLPF_FS (DLPF_CFG = 3, FS_SEL = 6) = 1Khz sample, 5Hz lowpass
  WriteRegisterByte( 21, 1 )            ' SMPLRT_DIV = 1(+1) 1=> 1khz/2 = 500hz sample rate 
  WriteRegisterByte( 62, 1 )            ' CLK_SEL = 1 (PLL + X Osc)

 'Find the zero points of the 3 axis by reading for ~1 sec and averaging the results
  x0 := 0
  y0 := 0
  z0 := 0
  
  dira[statusLEDPin]~~  'Status LED set pin set for output

  repeat 2                   'Flash once per second twice
    outa[statusLEDpin]~~
    waitcnt(clkfreq/2 + cnt)             
    outa[statusLEDpin]~
    waitcnt(clkfreq/2 + cnt)
     
  outa[statusLEDpin]~~       'Final flash on

  ' Calibrate twice and check for difference indicating movement
   
  Calibrate
  firstx0 := x0

  Calibrate
  secondx0 := x0
  
  if(||(secondx0 - firstx0) > (constants.GetNoise * 3))
      outa[statusLEDpin]~ 
      utilities.SignalNFlashes(5)
      RETURN
     
  LONG[xZeroAddr] := x0       'Update gyro zero values   
  LONG[yZeroAddr] := y0      
  LONG[zZeroAddr] := z0    

   outa[statusLEDpin]~    'Done Calibrating - final flash off
       
  'Run the main gyro reading loop
 
  lastTime := cnt
      
  repeat
    StartRead( 29 )
    temp := ContinueRead << 8
    temp += ContinueRead
    ~~temp
    x := temp - x0
    temp := ContinueRead << 8
    temp += ContinueRead
    ~~temp
    y := temp - y0
    temp := ContinueRead << 8
    temp += FinishRead
    ~~temp 
    z := temp - z0

    if(||x > noise)    
       LONG[xaddr] := (x * 116)/140       '  Update shared variables
    else                                  '  Scale them to be same as Phubar2 
       LONG[xaddr] := 0                   '  with IDG-500 and 12-bit ADC
                                          '  Ignore values < noise
    if(||y > noise)
       LONG[yaddr] := (y * 116)/140         
    else
       LONG[yaddr] := 0
       
    if(||z > noise)        
       LONG[zaddr] := (z * 116)/140         
    else
       LONG[zaddr] := 0
  
    ' 200 Hz loop
    waitcnt( constant(80_000_000 / 200) + lastTime )
    lastTime += constant(80_000_000 / 200) 


PRI Calibrate
   
  repeat 32
    StartRead( 29 )
    temp := ContinueRead << 8
    temp := temp | ContinueRead
    ~~temp
    x0 += temp 
    temp := ContinueRead << 8
    temp := temp | ContinueRead
    ~~temp
    y0 += temp
    temp := ContinueRead << 8
    temp := temp | FinishRead
    ~~temp
    z0 += temp
    waitcnt( constant(80_000_000/64) + cnt )
  
  x0 := x0 ~> 5   'shift 5 to divide by 32
  y0 := y0 ~> 5
  z0 := z0 ~> 5

  
PUB ReadRegisterByte( addr ) : result
    StartSend
    WriteByte( ITG_3200_WRITE ) 
    WriteByte( addr )
    StartSend
    WriteByte( ITG_3200_READ ) 
    result := ReadByte( 1 )
    StopSend


PUB ReadRegisterWord( addr ) : result
    StartSend
    WriteByte( ITG_3200_WRITE ) 
    WriteByte( addr )
    StartSend
    WriteByte( ITG_3200_READ ) 
    result := ReadByte( 0 ) << 8
    result |= ReadByte( 1 )
    StopSend


PUB StartRead( addr ) : result
    StartSend 
    WriteByte( ITG_3200_WRITE ) 
    WriteByte( addr )
    StartSend 
    WriteByte( ITG_3200_READ ) 


PUB ContinueRead : result
   result := 0
   dira[SDA]~                        ' Make SDA an input
  repeat 8                           ' Receive data from SDA
    outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      result := (result << 1) | ina[SDA]
      outa[SCL]~
  outa[SDA] := 0                     ' Output ACK to SDA
  dira[SDA]~~
  outa[SCL]~~                        ' Toggle SCL from LOW to HIGH to LOW
  outa[SCL]~
  outa[SDA]~                         ' Leave SDA driven LOW


PUB FinishRead : result
   result := 0
   dira[SDA]~                        ' Make SDA an input
  repeat 8                           ' Receive data from SDA
    outa[SCL]~~                      ' Sample SDA when SCL is HIGH
      result := (result << 1) | ina[SDA]
      outa[SCL]~
  outa[SDA] := 1                     ' Output NAK to SDA
  dira[SDA]~~
  outa[SCL]~~                        ' Toggle SCL from LOW to HIGH to LOW
  outa[SCL]~
  outa[SDA]~                         ' Leave SDA driven LOW
 


PUB WriteRegisterByte( addr , value )
    StartSend
    WriteByte(  ITG_3200_WRITE ) 
    WriteByte( addr )
    WriteByte( value )
    StopSend
  

PUB StartSend
   outa[SCL]~~                         ' Initially drive SCL HIGH
   dira[SCL]~~
   outa[SDA]~~                         ' Initially drive SDA HIGH
   dira[SDA]~~
   outa[SDA]~                          ' Now drive SDA LOW
   outa[SCL]~                          ' Leave SCL LOW


PUB StopSend                           ' SDA goes LOW to HIGH with SCL High
   outa[SCL]~~                         ' Drive SCL HIGH
   outa[SDA]~~                         '  then SDA HIGH
   dira[SCL]~                          ' Now let them float
   dira[SDA]~                          ' If pullups present, they'll stay HIGH


                                 
PUB WriteByte( data ) : ackbit
  ackbit := 0
  data <<= 24                         ' Write 8 bits
  repeat 8
    outa[SDA] := (data <-= 1) & 1
    outa[SCL]~~                       ' Toggle SCL from LOW to HIGH to LOW
    outa[SCL]~
  dira[SDA]~                          ' Set SDA to input for ACK/NAK
  outa[SCL]~~
  ackbit := ina[SDA]                  ' Sample SDA when SCL is HIGH
  outa[SCL]~
  outa[SDA]~                          ' Leave SDA driven LOW
  dira[SDA]~~


PUB ReadByte( ackbit ) : data
'' Read in i2c data, Data byte is output MSB first, SDA data line is
'' valid only while the SCL line is HIGH.  SCL and SDA left in LOW state.
   data := 0
   dira[SDA]~                         ' Make SDA an input
  repeat 8                            ' Receive data from SDA
    outa[SCL]~~                       ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
  outa[SDA] := ackbit                 ' Output ACK/NAK to SDA
  dira[SDA]~~
  outa[SCL]~~                         ' Toggle SCL from LOW to HIGH to LOW
  outa[SCL]~
  outa[SDA]~                          ' Leave SDA driven LOW
        