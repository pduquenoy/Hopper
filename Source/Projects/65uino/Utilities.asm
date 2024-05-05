unit Utilities
{
    // Original written by Anders Nielsen, 2023-2024
    // License: https://creativecommons.org/licenses/by-nc/4.0/legalcode
        
    uses "RIOT"
    
    DelayShort()
    {
        STA WTD8DI // Divide by 8 = A contains ticks to delay/8
        loop
        {
            NOP  // Sample every 8 cycles instead of every 6
            LDA READTDI
            if (Z) { break; }
        }
    }
    
    DelayLong()
    {
        STA WTD1KDI
        loop
        {
            LDA READTDI
            if (Z) { break; } // Loop until timer runs out
        }
    }
    
}
