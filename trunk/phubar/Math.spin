{  Math

   Various math and trig functions
   
   Sine and Cosine only handle angles between -720 and +720
}

PUB Cosine(angle)
 return Sine(90 - angle)

PUB Sine(angle) | sign, lookupangle, posangle 

  IF(angle > 360)
      posangle := angle - 360
  elseif (angle < -360)
      posangle := angle + 360
  else
      posangle := ||angle
  
  IF(posangle > 270)
    sign := -1
    lookupangle := 360 - posangle
    
  ELSEIF(posangle > 180)
      sign := -1
      lookupangle := posangle - 180

  ELSEIF(posangle > 90)
      sign := 1
      lookupangle := 180 - posangle
   
  ELSEIF(posangle =< 90)
      sign := 1
      lookupangle := posangle

  '------------------------------------------------------------- 
  'Get sine value from table in ROM by computing the fraction of
  '  90 degrees that the lookup angle represents
  ' If angle is negative, negate the return value since
  ' sin(-a) = -sin(a)

  if(angle < 0)
    return  -(sign * word[$e000 + ((($f000 - $e000)* lookupangle)/90)])
  else
    return  (sign * word[$e000 + ((($f000 - $e000)* lookupangle)/90)]) 

     