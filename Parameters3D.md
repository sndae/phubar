Following are all available PhuBar parameter settings that can be adjusted by the user.   This list is valid for code on the SatelliteReciever branch, likely destined to be renamed version 4.

| **Parameter** | **Description** | **Minimum Value** | **Maximum Value** |
|:--------------|:----------------|:------------------|:------------------|
| Model Name    | Name of PhuBar model profile. Max 15 characters. | N/A               | 15 characters     |
| Pitch Rate Gain | Rate gain on pitch axis | 0                 | 100               |
| Pitch Angular Gain | Angular Gain on Pitch axis | 0                 | 100               |
| Roll Rate Gain | Rate Gain on Roll axis | 0                 | 100               |
| Roll Angular Gain | Angular Gain on Roll axis | 0                 | 100               |
| Flybar Weight | Weight or mass of virtual flybar. | 0                 | 100               |
| Phase Angle   | Phase offset in degrees of swash inputs from forward=0. Clockwise = negative angle | -90               | 90                |
| Swash Ring    | Limit on swash cyclic servo travel, in percent | 25                | 100               |
| Collective Limit | Limit swash collective servo travel, in percent | 25                | 100               |
| Pulse Interval | PWM pulse cycle, in milliseconds | 5                 | 20                |
| Gyro X Axis   | Set gyro X-axis as heli axis (p)itch, (r)oll, or (y)aw | N/A               | N/A               |
| Gyro Y Axis   | Set gyro Y-axis as heli axis (p)itch, (r)oll, or (y)aw | N/A               | N/A               |
| Gyro Z Axis| Set gyro Z-axis as heli axis (p)itch, (r)oll, or (y)aw | N/A               | N/A               |
| Reverse Pitch Gyro | Indicate if gyro should have pitch reversed, (y)es or (n)o | N/A               | N/A               |
| Reverse Roll Gyro | Indicate if gyro should have roll reversed, (y)es or (n)o | N/A               | N/A               |
| Reverse Yaw Gyro| Indicate if gyro should have yaw reversed, (y)es or (n)o | N/A               | N/A               |
| Servo 1 Theta | Location of servo1 on swashplate | -360              | 360               |
| Servo 2 Theta | Location of servo2 on swashplate | -360              | 360               |
| Servo 3 Theta | Location of servo3 on swashplate | -360              | 360               |
| Yaw Angular Gain**(aka HH Gain)**| Angular gain on yaw axis | 0                 | 1000              |
| Yaw Rate Gain| Rate gain on yaw (tail) axis | 0                 | 1000              |
| Heading Hold On| Turn heading hold mode on? (y)es or (n)o | N/A               | N/A               |
| Servo 1 Trim  | Sub-trim adjustment for servo1 | -20               | 20                |
| Servo 2 Trim  | Sub-trim adjustment for servo2 | -20               | 20                |
| Servo 3 Trim  | Sub-trim adjustment for servo3 | -20               | 20                |
| Tail Servo Trim| Sub-trim adjustment for tail servo | -20               | 20                |
| Reverse Servo 1 | Indicate if servo1 rotation direction should be reversed, (y)es or (n)o | N/A               | N/A               |
| Reverse Servo 2 | Indicate if servo2 rotation direction should be reversed, (y)es or (n)o | N/A               | N/A               |
| Reverse Servo 3 | Indicate if servo3 rotation direction should be reversed, (y)es or (n)o | N/A               | N/A               |
| Reverse Tail Servo | Indicate if tail servo rotation direction should be reversed, (y)es or (n)o | N/A               | N/A               |
| Pitch Hiller| Tilt limit of virtual flybar | 0                 | 100               |
| Roll Hiller| Tilt limit of virtual flybar | 0                 | 100               |
| Bell Gain| Amount of damping of control inputs around neutral | 0                 | 150               |
| Tail Servo Max | Sets max limit point for tail servo throw | 60                | 100               |
| Tail Servo Min | Sets min limit point for tail servo throw | 0                 | 40                |
| Collective Feed Forward| Feed-forward gain for collective compensation on yaw | 0                 | 100               |
| Gyro Filter Frequency| Gyro low-pass filter frequency: 0=256hz, 1=188hz, 2=98hz, 3=42hz, 4=20hz, 5=10hz, 6=5hz | 0                 | 6                 |
| Heading Hold Deadband| Deadband on rudder stick for heading-hold mode | 0                 | 3000              |