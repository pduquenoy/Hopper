program Blink
{
    #define CPU_4MHZ
    #define CPU_65C02S
    
    uses "/Source/Runtime/6502/ZeroPage"
    
    Delay()
    {
        LDX # 0
        loop
        {
            LDY # 0
            loop
            {
                DEY
                if (Z) { break;} 
            }
            
            DEX
            if (Z) { break;} 
        } 
    }
    Hopper()
    {
        SEI
        
        LDA # 0b00000001 // PA0 is output (LED)
        STA ZP.DDRA
               
        LDA # 0b11111111
        STA ZP.DDRB
        
        LDY #0
        PHY
        loop
        {
            LDA # 0b00000000  // LED off
            STA ZP.PORTA
            
            PLY
            INY   
            STY ZP.PORTB
            PHY
            
            
            Delay();       
            /*
            LDX # 0
            loop
            {
                LDY # 0
                loop
                {
                    DEY
                    if (Z) { break;} 
                }
                
                DEX
                if (Z) { break;} 
            }
            */
            LDA # 0b00000001  // LED on
            STA ZP.PORTA
            
            Delay(); 
            /*
            LDX # 0
            loop
            {
                LDY # 0
                loop
                {
                    DEY
                    if (Z) { break;} 
                }
                
                DEX
                if (Z) { break;} 
            }
            */
        }
    }
}
