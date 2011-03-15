{   Utilities


}

CON
  _xinfreq=5_000_000            
  _clkmode=xtal1+pll16x    'The system clock is set at 80MHz
  CLK_FREQ = ((_clkmode-xtal1)>>6)*_xinfreq
  MS_001 = CLK_FREQ / 1_000

OBJ
 constants      :  "Constants"

PUB FlashLED

      dira[constants#SERIAL_TX_PIN]~  'Set for input
      dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output

      outa[constants#STATUS_LED_PIN]~~
      pause(5)
      outa[constants#STATUS_LED_PIN]~
             
PUB SignalError  'Rapid blink of LED signals error

      dira[constants#SERIAL_TX_PIN]~  'Set for input
      dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output
       
      repeat until(ina[constants#SERIAL_RX_PIN] == 1)    ' If user connects PropPlug, then exit
        ! outa[constants#STATUS_LED_PIN]
        pause(125)


PUB SignalErrorRapid  'Rapid blink of LED signals error
      dira[constants#SERIAL_TX_PIN]~  'Set for input 
      dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output
       
      repeat until(ina[constants#SERIAL_RX_PIN] == 1)    ' If user connects PropPlug, then exit 
        ! outa[constants#STATUS_LED_PIN]
        pause(50)


PUB pause(ms) | t    'Pause for ms milliseconds
  t := cnt - 1088    'Compensate for latency of the call at 80mHz
  repeat ms
    waitcnt(t += MS_001)

PUB msPassed(now,then) | ms
  'now and then are clk counts 
  ms := ((now-then)*1000)/clkfreq
  
  return ms

PUB BadError  'Rapid blink of LED signals error

      dira[constants#SERIAL_TX_PIN]~  'Set for input
      dira[constants#STATUS_LED_PIN]~~  'Status LED set pin set for output
       
      repeat     
        ! outa[constants#STATUS_LED_PIN]
        pause(125)       
        