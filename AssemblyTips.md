Following are tips on building a board using the printed circuit board referenced on the parts page:

### Soldering ###
Use a temperature-controlled soldering iron,  or at least use a small 12-watt iron with fine point tip.

A 10x magnifier, held with a third-hand device, is a must when soldering the gyro chip.  Keeping the chip aligned with the pads is important, so the gyro axes will be aligned with the board.  I put a very tiny drop of epoxy on the bottom of the chip and set it in place, and use the magnifier and a toothpick to nudge the chip into alignment with the pads.   After an hour or so has passed to allow the glue to set, the chip can be fluxed and soldered.

Use no-clean flux, and clean the finished board with alcohol and a small brush.  When clean, use a heat gun, hair dryer, or space heater to gently heat the board for about 10 minutes to drive out any moisture trapped under the components.

There are lots of guides and videos available online for soldering SMD components, such as those at curiousinventor.com.

### Assembly Order ###

Start with the gyro chip since it requires the soldering iron to have free access from many angles, and your 10x magnifier loupe needs to see the chip from many angles without other parts being in the way.

Solder the Propeller, regulator, and eeprom chips next.

Solder the LED, resistors and caps next.

Solder the connector headers last, because they restrict access to other components the most.  You will want to minimize the amount that the header pins protrude through the board, so that the board will lay as flat as possible when you put foam tape on it and attach it to your helicopter.

### Rework;  Protecting the Crystal ###
If you use hot air to rework any part of the board near the crystal more than a couple of times,  you run the risk of killing the crystal, since it is a big metal can and it soaks up the heat.  This happened to me once when I reworked the gyro chip several times.

I decided that anytime I need to rework the gyro or eeprom, I will remove the crystal first.  I just use my iron on one lead at a time on the back of the board, prying the crystal up slightly each time and going back and forth on each lead until they are free.

You know the crystal is dead when programs that specify _xinfreq and_clkmode will not run, but programs that run on the internal clock WILL run.   The simple LED test program can be run both ways to check this.


### Diagnosing Problems After Assembly ###
You can check the board by loading the PhuBar3 code into it.   The LED should light and stay on until you remove the PropPlug.  But if it does not light, it is time to drop back to simpler tests.

You can check the basic functioning of the Propeller by loading the following program into RAM, which blinks the LED.  If the LED does not blink with the code shown, but will blink when you remove the xinfreq and clkmode lines, then your crystal is bad or not soldered well.

```
CON
  _xinfreq = 5_000_000            
  _clkmode = xtal1+pll16x      
  statusLEDpin = 3
  
PUB start

  dira[statusLEDpin]~~    
  repeat
        outa[statusLEDpin]~~                           
        waitcnt(clkfreq/100+cnt)
        outa[statusLEDpin]~    
        waitcnt(clkfreq/2+cnt)

```

If you cannot get the LED to blink at all, check to make sure the flat side of the LED (anode) is toward the 5-pin header.  Also, check that all pins of the Propeller are soldered well. If even one of the 4 ground pins is not soldered, code will load and run, but the I/O pins may not function, including the pin driving the LED.

Since the whole board draws less than 35mA, the regulator should not get warm if everything is assembled correctly and there are no shorts. When the TC1262 regulator is used, the supply voltage should not exceed 6v.  With the substitute regulator, supply voltage can be higher, although attention should be paid to the total power dissipation and heating at the regulator if anything higher than 6v is used.
