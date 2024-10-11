unit SysCall
{
    uses "6502/Array"
    uses "6502/String"
#ifdef LISTS    
    uses "6502/List"
#endif
#ifdef LONGS    
    uses "6502/Long"
#endif
#ifdef FLOATS
    uses "6502/Float"
#endif
    uses "6502/Time"
    
    enum SysCalls
    {
        StringNewFromConstant = 0x00,
        StringBuild           = 0x01,
        StringNew             = 0x02,
        StringBuildFront      = 0x03,
        ArrayNewFromConstant  = 0x04,
        TimeSeconds           = 0x05,
        StringLengthGet       = 0x06,
        TimeDelay             = 0x07,
        DiagnosticsDie        = 0x08,
        SerialConnect         = 0x09,
        StringGetChar         = 0x0A,
        
        ArrayNew              = 0x0B,
        ArrayCountGet         = 0x0C,
        ArrayGetItem          = 0x0D,
        ArraySetItem          = 0x0E,
        
        SerialReadChar        = 0x0F,
        SerialWriteChar       = 0x10,
        SerialIsAvailable     = 0x11,
        
        MemoryReadByte        = 0x12,
        MemoryWriteByte       = 0x13,
        MemoryAvailable       = 0x14,
        MemoryMaximum         = 0x15,
        MemoryAllocate        = 0x16,
        MemoryFree            = 0x17,
        
        ByteToHex             = 0x18,
        IntGetByte            = 0x19,
        IntFromBytes          = 0x1A,
        
        ArrayItemTypeGet      = 0x1C,
        
        LongNew               = 0x1D,
        LongNewFromConstant   = 0x1E,
        LongFromBytes         = 0x1F,
        LongGetByte           = 0x20,
        
        FloatNew              = 0x21,
        FloatNewFromConstant  = 0x22,
        FloatFromBytes        = 0x23,
        FloatGetByte          = 0x24,
        
        TimeMillis            = 0x25,
        
        VariantBox            = 0x27,
        
        VariantUnBox          = 0x28, // TODO
        
        // ....
        
        IntToLong             = 0x35,
        UIntToLong            = 0x36,
        
        UIntToInt             = 0x37,
      //LongToString          = 0x38,
        UIntGetByte           = 0x39,
        
        LongToFloat           = 0x3A,
      //LongToInt             = 0x3B,
      //LongToUInt            = 0x3C,
        UIntFromBytes         = 0x3D,
        
        TimeSampleMicrosGet   = 0x3E,
        
        LongAdd               = 0x3F,
        LongSub               = 0x40,
        LongDiv               = 0x41,
        LongMul               = 0x42,
        LongMod               = 0x43,
        
        LongEQ                = 0x44,
        LongLT                = 0x45,
        LongLE                = 0x46,
        LongGT                = 0x47,
        LongGE                = 0x48,
        LongNegate            = 0x49,
        
        TimeSampleMicrosSet   = 0x4B,
        
        FloatAdd              = 0x4E,
        FloatSub              = 0x4F,
        FloatDiv              = 0x50,
        FloatMul              = 0x51,
        FloatEQ               = 0x52,
        FloatLT               = 0x53,
        
        FloatToLong           = 0xED,
        LongAddB              = 0xEE,
        LongSubB              = 0xEF,
        
        // ....
        
        TypesTypeOf           = 0x7E, // TODO
        TypesBoxTypeOf        = 0x81, // TODO
        
        RuntimeInDebuggerGet  = 0x97,
        RuntimeDateTimeGet    = 0x98,
        
        // ....
                
        ListNew               = 0xF4,
        ListCountGet          = 0xF5,
        ListAppend            = 0xF6,
        ListInsert            = 0xF7,
        ListGetItem           = 0xF8,
        ListGetItemAsVariant  = 0xF9,
        ListSetItem           = 0xFA,
        ListClear             = 0xFB,
        ListRemove            = 0xFC,
        ListContains          = 0xFD,
    }
    
    missing()
    {
#ifdef CHECKED
        TXA // SysCall not Implemented!
        Diagnostics.die();
#endif
    }
    
    inDebuggerGet()
    {
        LDX # 0
#ifdef CPU_65C02S
        if (BBS4, ZP.FLAGS)
        {
            INX
        }
#else
        LDA ZP.FLAGS
        AND # 0b00010000
        if (NZ)
        {
            INX
        }
#endif        
        Stacks.PushX();
    }
    dateTimeGet()
    {
        LDA # 0x07 // Bell
        Serial.WriteChar();
        LDA # 'D' // DateTime
        Serial.WriteChar();
        
        loop
        {
            Serial.IsAvailable();
            if (NZ) { break; }
        }
           
        String.New();
        loop
        {
            Serial.WaitForChar();
            CMP # 0x0A // Char.EOL
            if (Z)
            {
                break;
            }
            STA ZP.TOPL
#ifdef CPU_65C02S
            STZ TOPH
#else
            LDA #0
            STA TOPH
#endif
            
            LDY ZP.SP
            DEY
            STY ZP.NEXTL
#ifdef CPU_65C02S
            STZ ZP.NEXTH
#else
            LDA #0
            STA ZP.NEXTH
#endif
            LDA #Types.Reference
            Stacks.PushNext();
            
            LDA #Types.Char
            Stacks.PushTop(); // push ch
            
            // Build(ref string build, char ch)
            String.build1();
        }
    }
        
    serialConnect()
    {
        // NOP (we're already connected to serial)
    }
    serialWriteChar()
    {
        Stacks.PopA();
        Serial.WriteChar();
    }
    
    serialIsAvailable()
    {
        LDX # 1
        Serial.IsAvailable();
        if (Z)
        {
            DEX
        }
        Stacks.PushX();
    }
    serialReadChar()
    {
        Serial.WaitForChar();
        STA ZP.TOPL
#ifdef CPU_65C02S
        STZ ZP.TOPH
#else
        LDA # 0
        STA ZP.TOPH
#endif        
        LDA # Types.Char
        Stacks.PushTop(); // type is in A
    }
    
    byteToHex()
    {
        // convert nibble to hex char
        Stacks.PopA();
        CMP # 0x0A
        if (C)
        {
            // +'A' - 10   = 55
            // + 48 below  = 7
            // + 1 (carry) = 6
            ADC # 6
        }
        // +'0'
        ADC # '0' // 48
        
        STA ZP.TOPL
#ifdef CPU_65C02S
        STZ ZP.TOPH
#else
        LDA # 0
        STA ZP.TOPH
#endif
        LDA # Types.Char
        Stacks.PushTop();
    }
    intGetByte()
    {
        PopTopNext();
        LDA ZP.TOPL
        if (NZ)
        {
            LDA ZP.NEXTH // MSB
            STA ZP.NEXTL
        }
        LDA # 0
        STA ZP.NEXTH
        LDA # Types.Byte
        Stacks.PushNext();
    }
    intFromBytes()
    {
        PopTopNext();
        LDA ZP.TOPL
        STA ZP.NEXTH
        LDA # Types.Int
        Stacks.PushNext();
    }
    uintFromBytes()
    {
        PopTopNext();
        LDA ZP.TOPL
        STA ZP.NEXTH
        LDA # Types.UInt
        Stacks.PushNext();
    }
    
    SysCallShared()
    {
        // iOverload in ACCL
        // iSysCall  in X
        
        switch (X)
        {
            case SysCalls.DiagnosticsDie:
            {
                Diagnostics.Die();
            }
            
            case SysCalls.SerialConnect:
            {
                serialConnect();
            }
            case SysCalls.SerialWriteChar:
            {
                serialWriteChar();
            }
            case SysCalls.SerialReadChar:
            {
                serialReadChar();
            }
            case SysCalls.SerialIsAvailable:
            {
                serialIsAvailable();
            }
            
            case SysCalls.TimeDelay:
            {
                Time.Delay();
            }
            case SysCalls.TimeSampleMicrosSet:
            {
                Time.SampleMicrosSet();
            }
            case SysCalls.TimeSampleMicrosGet:
            {
                Time.SampleMicrosGet();
            }
            case SysCalls.TimeSeconds:
            {
                Time.Seconds();
            }
            case SysCalls.TimeMillis:
            {
#ifdef LONGS
                Time.Millis();
#else
                missing();
#endif
            }   
            
            case SysCalls.RuntimeInDebuggerGet:
            {
                inDebuggerGet();
            }
            
            case SysCalls.RuntimeDateTimeGet:
            {
                dateTimeGet();
            }
            
            case SysCalls.ByteToHex:
            {
                byteToHex();
            }
            case SysCalls.IntGetByte:
            {
                intGetByte();
            }
            case SysCalls.IntFromBytes:
            {
                intFromBytes();
            }
            case SysCalls.UIntGetByte:
            {
                intGetByte();
            }
            case SysCalls.UIntFromBytes:
            {
                uintFromBytes();
            }
            
            case SysCalls.MemoryReadByte:
            {
                Memory.ReadByte();
            }
            case SysCalls.MemoryWriteByte:
            {
                Memory.WriteByte();
            }
            case SysCalls.MemoryAvailable:
            {
                Memory.Available();
            }
            case SysCalls.MemoryMaximum:
            {
                Memory.Maximum();
            }
            case SysCalls.MemoryAllocate:
            {
                Memory.Allocate();
            }
            case SysCalls.MemoryFree:
            {
                Memory.Free();
            }
            
            case SysCalls.ArrayNew:
            {
                Array.New();
            }
            case SysCalls.ArrayCountGet:
            {
                Array.CountGet();
            }
            case SysCalls.ArrayItemTypeGet:
            {
                Array.ItemTypeGet();
            }
            case SysCalls.ArrayGetItem:
            {
                Array.GetItem();
            }
            case SysCalls.ArraySetItem:
            {
                Array.SetItem();
            }
            case SysCalls.ArrayNewFromConstant:
            {
                Array.NewFromConstant();
            }
            
            case SysCalls.StringNewFromConstant:
            {
                String.NewFromConstant();
            }
            case SysCalls.StringNew:
            {
                String.New();
            }
            case SysCalls.StringLengthGet:
            {
                String.LengthGet();
            }
            case SysCalls.StringGetChar:
            {
                String.GetChar();
            }
            case SysCalls.StringBuild:
            {
                String.Build();
            }
            case SysCalls.StringBuildFront:
            {
                String.BuildFront();
            }
            
            case SysCalls.LongNew:
            {
#ifdef LONGS
                Long.New();
#else
                missing();
#endif                
            }
            case SysCalls.LongNewFromConstant:
            {
#ifdef LONGS
                Long.NewFromConstant();
#else
                missing();
#endif                
            }
            case SysCalls.LongFromBytes:
            {
#ifdef LONGS
                Long.FromBytes();
#else
                missing();
#endif                
            }
            case SysCalls.LongGetByte:
            {
#ifdef LONGS
                Long.GetByte();
#else
                missing();
#endif                
            }
            case SysCalls.LongAdd:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Add();
#else
                missing();
#endif                
            }
            case SysCalls.LongSub:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Sub();
#else
                missing();
#endif                
            }
            case SysCalls.LongAddB:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.AddB();
#else
                missing();
#endif                
            }
            case SysCalls.LongSubB:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.SubB();
#else
                missing();
#endif                
            }
            case SysCalls.LongDiv:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Div();
#else
                missing();
#endif                
            }
            case SysCalls.LongMul:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Mul();
#else
                missing();
#endif                
            }
            case SysCalls.LongMod:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Mod();
#else
                missing();
#endif                
            }
            case SysCalls.LongNegate:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.Negate();
#else
                missing();
#endif                
            }
            case SysCalls.IntToLong:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                IntToLong();
#else
                missing();
#endif                
            }
            case SysCalls.UIntToLong:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                UIntToLong();
#else
                missing();
#endif                
            }            
            case SysCalls.LongEQ:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.EQ();
#else
                missing();
#endif                
            }
            case SysCalls.LongLT:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.LT();
#else
                missing();
#endif                
            }
            case SysCalls.LongGT:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.GT();
#else
                missing();
#endif                
            }
            case SysCalls.LongLE:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.LE();
#else
                missing();
#endif                
            }
            case SysCalls.LongGE:
            {
#if defined(LONGS) && defined(FAST_6502_RUNTIME)
                Long.GE();
#else
                missing();
#endif                
            }
            case SysCalls.FloatToLong:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.ToLong();
#else
                missing();
#endif                
            }
            case SysCalls.LongToFloat:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Long.ToFloat();
#else
                missing();
#endif                
            }
            
            
            
            case SysCalls.FloatNew:
            {
#ifdef FLOATS
                Float.New();
#else
                missing();
#endif                
            }
            case SysCalls.FloatNewFromConstant:
            {
#ifdef FLOATS
                Float.NewFromConstant();
#else
                missing();
#endif                
            }
            case SysCalls.FloatFromBytes:
            {
#ifdef FLOATS
                Float.FromBytes();
#else
                missing();
#endif                
            }
            case SysCalls.FloatGetByte:
            {
#ifdef FLOATS
                Float.GetByte();
#else
                missing();
#endif                
            }
            
            case SysCalls.FloatAdd:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.Add();
#else
                missing();
#endif                
            }
            case SysCalls.FloatSub:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.Sub();
#else
                missing();
#endif                
            }
            case SysCalls.FloatMul:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.Mul();
#else
                missing();
#endif                
            }
            case SysCalls.FloatDiv:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.Div();
#else
                missing();
#endif                
            }
            
            case SysCalls.FloatEQ:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.EQ();
#else
                missing();
#endif                
            }
            case SysCalls.FloatLT:
            {
#if defined(FLOATS) && defined(FAST_6502_RUNTIME)
                Float.LT();
#else
                missing();
#endif                
            }
            
            
            case SysCalls.VariantBox:
            {
#ifdef LISTS                
                Variant.Box();
#else
                missing();
#endif                
            }
            
            case SysCalls.VariantUnBox:
            {
#ifdef LISTS                
                Variant.UnBox();
#else
                missing();
#endif                
            }
            
            case SysCalls.UIntToInt:  
            {
                UIntToInt();
            }
            case SysCalls.TypesTypeOf:  
            {
#ifdef LISTS                
                Type.TypeOf();
#else
                missing();
#endif                
            }
            case SysCalls.TypesBoxTypeOf:  
            {
#ifdef LISTS                
                Type.BoxTypeOf();
#else
                missing();
#endif                
            }
            
            case SysCalls.ListNew:
            {
#ifdef LISTS
                List.New();
#else
                missing();
#endif                
            }
            case SysCalls.ListCountGet:
            {
#ifdef LISTS
                List.CountGet();
#else
                missing();
#endif                
            } 
            case SysCalls.ListAppend:
            {
#ifdef LISTS
                List.Append();
#else
                missing();
#endif                
            }  
            case SysCalls.ListInsert:
            {
#ifdef LISTS
                List.Insert();
#else
                missing();
#endif                
            } 
            case SysCalls.ListGetItem:
            {
#ifdef LISTS
                List.GetItem();
#else
                missing();
#endif                
            } 
            case SysCalls.ListGetItemAsVariant:
            {
#ifdef LISTS
                List.GetItemAsVariant();
#else
                missing();
#endif                
            } 
            case SysCalls.ListSetItem:
            {
#ifdef LISTS
                List.SetItem();
#else
                missing();
#endif                
            }  
            case SysCalls.ListClear:
            {
#ifdef LISTS
                List.Clear();
#else
                missing();
#endif                
            }
            case SysCalls.ListRemove:
            {
#ifdef LISTS
                List.Remove();
#else
                missing();
#endif                
            }
            case SysCalls.ListContains:
            {
#ifdef LISTS
                List.Contains();
#else
                missing();
#endif                
            }
            
            
            default:
            {
                missing();
            }
        }
    }
    SysCall()
    {
        ConsumeOperandA(); // iSysCall  -> A (uses ACC)
        PHA
        Stacks.PopACC();   // iOverload -> ACCL, only care about ACCL (not ACCT or ACCH)
        
        // load iSyscCall into X (because JMP [nnnn,X] is then possible)
#ifdef CPU_65C02S
        PLX
#else        
        PLA
        TAX
#endif
        // iOverload in ACCL
        // iSysCall  in X
        SysCallShared();
    }
#ifdef PACKED_INSTRUCTIONS    
    SysCall0()
    {
        ConsumeOperandA(); // iSysCall  -> A (uses ACC)
        TAX                // load iSysCall into X (because JMP [nnnn,X] is then possible)
        
        // iOverload -> ACCL
#ifdef CPU_65C02S
        STZ ACCL
#else        
        LDA # 0
        STA ACCL
#endif
        
        // iOverload in ACCL
        // iSysCall  in X
        SysCallShared();
    }
    SysCall1()
    {
        ConsumeOperandA(); // iSysCall  -> A (uses ACC)
        TAX                // load iSysCall into X (because JMP [nnnn,X] is then possible)
        
        // iOverload -> ACCL
        LDA # 1
        STA ACCL
        
        // iOverload in ACCL
        // iSysCall  in X
        SysCallShared();
    }
    SysCall2()
    {
        ConsumeOperandA(); // iSysCall  -> A (uses ACC)
        TAX                // load iSysCall into X (because JMP [nnnn,X] is then possible)
        
        // iOverload -> ACCL
        LDA # 2
        STA ACCL
        
        // iOverload in ACCL
        // iSysCall  in X
        SysCallShared();
    }
#endif
}
