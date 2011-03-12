{  GyroFilter

    Reads pitch and roll gyro data from ADC
    at high sample rate and does low-pass
    filtering on it.

    On startup, we sample the data for 5 seconds
    to determine zero (stationary) values for
    both axes

}

CON
 FILTERSAMPLEHZ     = 500           'Filter sample rate

 Vclk_p             = 23             'ADC CLock pin
 Vn_p               = 22             'ADC rcv pin
 Vo_p               = 21             'ADC tx pin
 Vcs_p              = 20             'ADC Chip Select pin
 
 ADCPITCHCHANNEL    = 2            'Swap these two to rotate unit by
 ADCROLLCHANNEL     = 3            ' 90 degrees
 ADCVREFCHANNEL     = 1
 ADCPTATSCHANNEL    = 0
 
 GYRO_AUTO_ZERO_PIN = 26            'IDG500 auto zero pin
  
OBJ
  constants      :  "Constants"
  gyroman        :  "ADC_INPUT_DRIVER"           'Gyro Monitor via ADC
  utilities      :  "Utilities"
  
VAR
   long filterStack[32], T
   long pitchRateAddr, rollrateAddr
   long pitchGyroZeroAddr, rollGyroZeroAddr,gyroTempAddr
   byte filterCog, ADCcog, statusLEDpin
   long pitchBiasAddr, rollBiasAddr
   
PUB Start(pAddr, rAddr, pZAddr, rZAddr, gTAddr, ledpin, pBiasAddr, rBiasAddr ) : okay 

   pitchRateAddr := pAddr
   rollRateAddr  := rAddr
   pitchGyroZeroAddr := pZAddr
   rollGyroZeroAddr := rZAddr
   gyroTempAddr     := gTAddr
   statusLEDpin := ledpin
   pitchBiasAddr := pBiasAddr
   rollBiasAddr := rBiasAddr
  '-------------------------------------------------------------------------
  'First,startup the ADC driver to monitor gyros, 8 channels,
  ' scan 4 channels, 12-bit ADC, and mode 1 (single-ended)
  ' ch3 = X4.5OUT  (pitch rate)
  ' ch2 = Y4.5OUT  (roll rate)
  ' ch1 = VREF     (zero-point voltage)
  ' ch0 = PTATS    (gyro temperature)
  '
  'If ADC driver starts OK, then find zero values of gyros
  '
  'Then launch a cog to do filtering
  ' 
  '-------------------------------------------------------------------------
    
  ADCcog := gyroman.start(Vo_p, Vn_p, Vclk_p, Vcs_p, 8, 4, 12, 1)

  if(NOT CalibrateGyros)
     okay := FALSE
     return
     
  if(ADCcog )
    okay := filterCog := cognew(FilterLoop, @filterStack)   ' Launch filter cog
  else 
    okay := FALSE


PUB Stop

  if filterCog
    cogstop(filterCog~ )
    
  if ADCCog
    cogstop(ADCCog~)
    
PUB ClearAutoZero

  dira[GYRO_AUTO_ZERO_PIN]~~
  outa[GYRO_AUTO_ZERO_PIN]~   'clear
  waitcnt(clkfreq/50+cnt)
  
PRI PulseAutoZero
  outa[GYRO_AUTO_ZERO_PIN]~~  'set
  waitcnt(clkfreq/1200+cnt) 
  outa[GYRO_AUTO_ZERO_PIN]~   'clear
  waitcnt(clkfreq/50+cnt)
    
PRI CalibrateGyros | i

  '------------------------------------------------
  'Send <1ms autozero pulse to IDG500 auto-zero pin
  ' then wait 20ms for settling
  '------------------------------------------------
  dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output   
  ClearAutoZero
  PulseAutoZero
  
  '--------------------------------------------------
  'Loop and average gyro output to get values when
  ' stationary. Blink LED to show we are calibrating
  '--------------------------------------------------
  long[pitchGyroZeroAddr] := 0
  long[rollGyroZeroAddr]  := 0

  i :=0

  repeat 1500
    long[pitchGyroZeroAddr] += gyroman.getval(ADCPitchChannel) 
    long[rollGyroZeroAddr] += gyroman.getval(ADCRollChannel) 
    waitcnt(clkfreq/FILTERSAMPLEHZ + cnt)
    if(i++ > 250)  'blink about once per second
       i := 0
       !outa[constants#STATUS_LED_PIN]
       
  outa[statusLEDpin]~      'Turn off LED so user knows we are done calibrating
  
  long[rollGyroZeroAddr] /= 1500  
  long[pitchGyroZeroAddr] /= 1500

  if(long[rollGyroZeroAddr] < 250)
    return FALSE                       'something is wrong with gyro or we are not
  if(long[pitchGyroZeroAddr] < 250)    ' stationary.  Return false so calling code
    return FALSE                       ' can signal an error

 '---------------------------------------------------
  ' Initialize the filters with unmodified gyro inputs
  '---------------------------------------------------
  long[pitchRateAddr] :=   gyroman.getval(ADCPITCHCHANNEL)- long[pitchGyroZeroAddr]
  long[rollRateAddr]  :=   gyroman.getval(ADCROLLCHANNEL) - long[rollGyroZeroAddr]

  '---------------------------------------------------
  'Find filter bias values for pitch and roll
  '  Digital filter tends to lose bits due to shifting, which
  '  biases the rate values when gyro is stationary.  Here
  '  we measure the bias so we can subtract it in the main
  '  update loop
  '
  'Filtering is based on sample code line from MatrixPilot analog2digital.c 
  '   xrate.value = xrate.value + (( (xrate.input>>1) - (xrate.value>>1) )>> 3 )
  ' Instead of >> we use ~> which does arithmetic shift preserving the sign 
  '---------------------------------------------------
  
  repeat 100
    T := cnt
    long[pitchRateAddr] +=  ((((gyroman.getval(ADCPitchChannel)- long[pitchGyroZeroAddr]) ~> 1)  - (long[pitchRateAddr] ~> 1)) ~> 3)
    long[rollRateAddr]  +=  ((((gyroman.getval(ADCRollChannel) - long[rollGyroZeroAddr])  ~> 1)  - (long[rollRateAddr]  ~> 1)) ~> 3)
    waitcnt(clkfreq/FILTERSAMPLEHZ + cnt)

  long[pitchBiasAddr] := long[pitchRateAddr]
  long[rollBiasAddr]  := long[rollRateAddr]
   
  if((||long[rollBiasAddr] => 25) or (||long[pitchBiasAddr] => 25))    ' We are not stationary
     utilities.SignalErrorRapid               

 return TRUE
 
PRI FilterLoop  | pval, rval

 '---------------------------------------------------
  ' Initialize the filters with unmodified gyro inputs
  '---------------------------------------------------
  long[pitchRateAddr] :=   gyroman.getval(ADCPITCHCHANNEL)- long[pitchGyroZeroAddr]
  long[rollRateAddr]  :=   gyroman.getval(ADCROLLCHANNEL) - long[rollGyroZeroAddr] 
           
  '---------------------------------------------------------
  'Loop forever at specified rate and apply low-pass filter
  '---------------------------------------------------------
  repeat
    T := cnt
    long[pitchRateAddr] +=  ((((gyroman.getval(ADCPitchChannel)- long[pitchGyroZeroAddr]) ~> 1)  - (long[pitchRateAddr] ~> 1)) ~> 3)
    long[rollRateAddr]  +=  ((((gyroman.getval(ADCRollChannel) - long[rollGyroZeroAddr])  ~> 1)  - (long[rollRateAddr]  ~> 1)) ~> 3)
    long[gyroTempAddr]  := gyroman.getval(ADCPTATSCHANNEL)
    waitcnt(clkfreq/FILTERSAMPLEHZ + cnt)

    