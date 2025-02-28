Digital Phase-Locked Loop (DPLL) as an ASIC design. 
The DPLL is designed to lock onto an reference oscillator @ 10MHz and generate a high-frequency output clock using a Ring Oscillator (DCO) operating @100MHz.
The feedback clock is rate divided through N-divide with division number of 10, and is phase-compared with the reference clock using a Phase Frequency Detector (PFD) and generate up/down control signal.
a PI controller is used for first-order filter transfer function and provide control signal for Oscillator.

RTL View
![default (1)](https://github.com/user-attachments/assets/788456bc-c500-4e06-a2b6-a815e76ecb4e)

Advisor: T.Kosteski
