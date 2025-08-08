unit Stacks // Stacks.asm
{
    #define HOPPER_STACK
    
    uses "/Source/Runtime/6502/Utilities"
    
    Initialize()
    {
#ifdef CPU_65C02S        
        STZ ZP.SP
        STZ ZP.BP
        STZ ZP.CSP
        
        // zeroes mean faster debug protocol
        STZ IDXL  // setting this to 0 once is enough (ClearPages does not modify IDXL)
#else
        LDA # 0
        STA ZP.SP
        STA ZP.BP
        STA ZP.CSP
        
        // zeroes mean faster debug protocol
        STA IDXL // setting this to 0 once is enough (ClearPages does not modify IDXL)
#endif

        LDA # (Address.CallStackLSB >> 8)
        STA IDXH
        LDX # 5                 // 5 contiguous pages for CallStack, TypeStack and ValueStack
        Utilities.ClearPages(); // with IDX (memory location) and X (number of pages) initialized (does not modify IDXL)
    }
    
    PopBP()
    {
        DEC ZP.CSP    
        LDY ZP.CSP
        LDA Address.CallStackLSB, Y
        STA ZP.BP
    }
    PushBP()
    {
        LDX ZP.CSP
        LDA ZP.BP
        STA Address.CallStackLSB, X
        INC ZP.CSP
    }
    PopPC()
    {
        DEC ZP.CSP    
        LDY ZP.CSP
        LDA Address.CallStackLSB, Y
        STA ZP.PCL
        LDA Address.CallStackMSB, Y
        STA ZP.PCH
    }
    PushPC()
    {
        LDY ZP.CSP
        LDA ZP.PCL
        STA Address.CallStackLSB, Y
        LDA ZP.PCH
        STA Address.CallStackMSB, Y
        INC ZP.CSP
    }
    
#ifdef HOPPER_BASIC
    PopXID()
    {
        DEC ZP.CSP    
        LDY ZP.CSP
        LDA Address.CallStackLSB, Y
        STA ZP.XIDL
        LDA Address.CallStackMSB, Y
        STA ZP.XIDH
    }
    PushXID()
    {
        LDY ZP.CSP
        LDA ZP.XIDL
        STA Address.CallStackLSB, Y
        LDA ZP.XIDH
        STA Address.CallStackMSB, Y
        INC ZP.CSP
    }
#endif
    
    PopTop()
    {
        DEC ZP.SP
        LDX ZP.SP
        LDA Address.ValueStackLSB, X
        STA ZP.TOPL
        LDA Address.ValueStackMSB, X
        STA ZP.TOPH
        LDA Address.TypeStackLSB, X
        STA ZP.TOPT
    }
    PushTop() // type is in A
    {
        LDY ZP.SP
        STA Address.TypeStackLSB, Y
        LDA ZP.TOPL
        STA Address.ValueStackLSB, Y
        LDA ZP.TOPH
        STA Address.ValueStackMSB, Y
        INC ZP.SP
    }
    PushIDX() // type is in A
    {
        LDY ZP.SP
        STA Address.TypeStackLSB, Y
        LDA ZP.IDXL
        STA Address.ValueStackLSB, Y
        LDA ZP.IDXH
        STA Address.ValueStackMSB, Y
        INC ZP.SP
    }
    PopNext()
    {
        DEC ZP.SP
        LDX ZP.SP
        LDA Address.ValueStackLSB, X
        STA ZP.NEXTL
        LDA Address.ValueStackMSB, X
        STA ZP.NEXTH
        LDA Address.TypeStackLSB, X
        STA ZP.NEXTT
    }
    PopTopNext()
    {
#ifdef INLINE_EXPANSIONS  
        DEC ZP.SP
        LDX ZP.SP
        LDA Address.ValueStackLSB, X
        STA ZP.TOPL
        LDA Address.ValueStackMSB, X
        STA ZP.TOPH
        LDA Address.TypeStackLSB, X
        STA ZP.TOPT 
        
        DEC ZP.SP
        DEX
        LDA Address.ValueStackLSB, X
        STA ZP.NEXTL
        LDA Address.ValueStackMSB, X
        STA ZP.NEXTH
        LDA Address.TypeStackLSB, X
        STA ZP.NEXTT     
#else
        Stacks.PopTop();
        Stacks.PopNext();
#endif
    }
    PushNext() // type is in A
    {
        LDY ZP.SP
        STA Address.TypeStackLSB, Y
        LDA ZP.NEXTL
        STA Address.ValueStackLSB, Y
        LDA ZP.NEXTH
        STA Address.ValueStackMSB, Y
        INC ZP.SP
    }
    PushACC()
    {
        LDY ZP.SP
        LDA ZP.ACCL
        STA Address.ValueStackLSB, Y
        LDA ZP.ACCH
        STA Address.ValueStackMSB, Y
        LDA ZP.ACCT
        STA Address.TypeStackLSB, Y
        INC ZP.SP
    }
    PushX()
    {
        // value is in X: 0 or 1
        STX ZP.NEXTL
#ifdef CPU_65C02S   
        STZ ZP.NEXTH     
#else
        LDA # 0
        STA ZP.NEXTH
#endif
        LDA #Types.Bool
        STA ZP.NEXTT
        PushNext();
    }
    
    PopACC()
    {
        DEC ZP.SP
        LDY ZP.SP
        LDA Address.ValueStackLSB, Y
        STA ZP.ACCL
        LDA Address.ValueStackMSB, Y
        STA ZP.ACCH
        // Type is never used / checked
        //LDA Address.TypeStackLSB, Y
        //STA ZP.ACCT
    }
    PopIDX()
    {
        DEC ZP.SP
        LDY ZP.SP
        LDA Address.ValueStackLSB, Y
        STA ZP.IDXL
        LDA Address.ValueStackMSB, Y
        STA ZP.IDXH
    }
    PopIDY()
    {
        DEC ZP.SP
        LDY ZP.SP
        LDA Address.ValueStackLSB, Y
        STA ZP.IDYL
        LDA Address.ValueStackMSB, Y
        STA ZP.IDYH
    }
    
    PopA() // pop a byte (don't care about type or MSB)
    {
        DEC ZP.SP
        LDY ZP.SP
        LDA Address.ValueStackLSB, Y
    }
}
