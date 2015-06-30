### Tuning the tail when using the 3D version of the software, currently in the SatelliteReceiver branch in SVN. ###

The tuning process below is cascaded in nature.  If you want to use collective compensation, you must complete rate mode setup. If you want to fly HH you must complete rate mode setup (and collective compensation setup , if you want to use that feature)


Rate mode with no collective compensation (collective feed-forward = 0)
  1. Fly and trim rudder trim on tx until it hovers in trim
  1. Land and mark where the trim position is with a magic marker
  1. Recenter tx yaw trim

Rate mode with collective compensation
  1. Set collective compensation at 50%
  1. Recheck yaw center position is on the mark at hover collective position.  It will move slightly
  1. Readjust yaw center value until the mark lines up
  1. Test fly and do collective manuvers to see witch way the tail kicks.
  1. Adjust collective compensation until you get pretty much zero heading change with full collective (very headspeed dependent so setup for your average throttle curve)

Heading Hold mode
  1. Turn on HH mode and test fly. Adjust HH gain as needed. You shouldn't see any weird behavior - it should lock the tail in nicely.