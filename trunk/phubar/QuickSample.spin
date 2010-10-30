{*****************************************
* ViewPort QuickSample       v4.2.1 9/09 *
* Adjustable 80 Mhz Sampling of INA      *
* (C) 2009 myDanceBot.com, Inc.          *
******************************************}{{
Use this Object to take measurements of INA at very high speeds.
Users can use ViewPort to analyze those measurements alongside other variables
from their program.

Features:
-Measure 1440 samples at 32bit up to 80Mhz using 4 cogs.
-Measure 360 samples at 32bit up to 20Mhz using 1 cog.
-Flexible timescale from seconds to nanoseconds
-Edge and Pattern Triggers- can be reset by ViewPort if not Trigger found
-Samples are continuously taken by 1 or 4 interleaved cogs running self modifying assembly code.

Use:
-Include this object in your program:
        Obj qs:"QuickSample"
-Allocate memory for the INAFrame:
        LONG INAFrame[400]
        *Allocate 400 longs for the INAFrame if using 1 cog, or 1600 if using 4.
-Register with ViewPort        
        vp.register(qs.sampleINA(@INAFrame,NumberOfCogs))
        *Use 1 cog to sample up to 20Mhz, or 4 to sample up to 80Mhz }}
CON
 _clkmode        = xtal1 + pll16x
 _xinfreq        = 5_000_000
  SamplesPCog      = 360
pub sampleINA(FrameAddr,nCogs):config 
 {{frameAddr should point to long array of framesamples+16 elements:
 tmask,tstate,tstate1,freq (0=20mhz, 16=5mhz, 32=2.5mhz...),syncA,framsamples of data
 syncA will be incremented when data is burst to memory 
 trigger active when mask<>0. does: waitpeq tstate, waitpeq tstate1- sample
 cog may be restarted remotely from viewport}} 
  long[FrameAddr+20]:=cnt             
  ncog:=nCogs-1
  long[FrameAddr+12]:=ncog          
  long[FrameAddr]:=(@MeasureNoI << 2) | (frameAddr<<16)| cognew(@MeasureNoI,FrameAddr)
  if nCogs==4
    cognew(@MeasureNoI,FrameAddr)
    cognew(@MeasureNoI,FrameAddr)
    cognew(@MeasureNoI,FrameAddr)
  return FrameAddr | 2
pub init  
dat
              org 0
MeasureNoI    





              mov       fptr,par 
              rdlong    tmask,fptr
              add       fptr,#4
              rdlong    tstate,fptr
              mov       tptr,fptr              
              add       fptr,#4
              rdlong    tstate1,fptr              
              add       fptr,#12
              rdlong    cps,fptr
              add       fptr,#4
              cmp       sptr,#0 wz
    if_z      rdlong    sptr,fptr 
              rdlong    lctr,sptr
              add       fptr,#4    
    if_z      rdlong    start,fptr
              add       fptr,#4
              mov       syncA,fptr      



              rdlong    lstart,syncA
    if_nz     mov       start,lstart
              
              mov       lstart,start
              add       start,initTime   
              mov       finc,#4         
              mov       writeloop,wrC2F
              mov       i,#SamplesPCog
              cmp       ncog,#2 wc 





    if_c      mov       cWait,cps       
    if_c      add       fptr,#4         
    if_c      tjz       cps,#mFull1     
    if_c      jmp       #mkTrigger






              cmp       cps,#2    wc,wz  
    if_z      jmp       #do40

              mov       finc,#16
              mov       cWait,#4
              cogid     j
    calcWait  add       cWait,cps'
     if_c     add       cWait,#1
              add       fptr,#4 
              djnz      j,#calcWait
 
              tjz       cps,#mFull
 
              shl       cps,#2
  mkTrigger   sub       cps,#18                 wc,nr
              mov       measure,storeF
              waitcnt   start,0 
              mov       start,cWait
              tjz       tmask,#sslow
              waitpeq   tstate, tmask
              waitpeq   tstate1, tmask
              
sslow  
              add       start,cnt



  measure     nop
store  if_nc  waitcnt   start, cps
              add       measure,d_inc
              djnz      i, #measure
              

writeFrame    cogid     j
              cmp       j,#1 wz              
       if_nz  jmp       #not1
'cog1  waits for change in sptr (conduit ready to send data)              
 wtconduit    rdlong    start,sptr
              cmp       start,lctr wz
    if_z      jmp       #wtconduit
   
              mov       start,cnt
              wrlong    start,syncA              
              jmp       #burst
'other cogs wait for syncA to transition
       not1   rdlong    start,syncA
              cmp       start,lstart wz 
        if_z  jmp       #not1
 burst        mov       i, #SamplesPCog
 writeloop    nop
              add       fptr, finc
              add       writeloop,d_inc
              djnz      i, #writeloop
 lk40         jmp       #MeasureNoI
              long      4      
              long      8
              long      SamplesPCog*8+12
              long      SamplesPCog*8+16
sAdd1         long      SamplesPCog*4+4
sAdd4         long      SamplesPCog*16+4

 do40         mov       finc,#8
              cogid     doL 
              add       doL,doLook
              mov       cWait,#1
     doL      nop
              add       cWait,s1
              add       fptr,s1
              jmp       #mFull
 doLook       mov       s1,lk40 
lctr          long      0
lstart        long      0
ncog          long      0
tptr          long      0
inittime      long      100_000
syncA         long      0 
sptr          Long      0
start         long      0
fPtr          Long      0
i             LONG      0
j             long      0
d_inc         LONG      $0000_0200
ds_inc        LONG      $0000_0201
cps           LONG      0
cWait         Long      0
finc          Long      0
cogn          long      0

jmpWF         jmp       #writeFrame
storeF        mov       fbufstart, ina               
wrc2f         wrlong    fbufstart, fptr
wrc2f1        wrlong    f1, fptr
dupRead       mov       s1,fbufstart          
modDup        add       s1,d_inc              
movJmp        mov       s1,jmpWF
f1w           mov       f1,ina
f2w           mov       f2,ina
tmask         nop 
tstate1       nop
tstate        nop

mFull1        mov       writeloop,wrC2F1
              mov       f1,f1w
              mov       f2,f2w
mFull         mov       :mk0,dupRead
              mov       :mk1,modDup
              mov       :mkjmp,movJmp
              mov       fbufstart,storeF
:mk0          nop
:mk1          nop
              add       :mk0,ds_inc           
              add       :mk1,d_inc            
              add       :mkjmp,d_inc          
              djnz      i,#:mk0
:mkjmp        nop
              waitcnt   start,0    
              mov       start,cWait
              tjz       tmask,#f1
              waitpeq   tstate, tmask
              waitpeq   tstate1, tmask   
f1            add       start,cnt
f2            waitcnt   start,#20
              
              fit       $1F0 - SamplesPCog         
fbufstart     nop 
s1            nop
