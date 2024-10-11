unit String
{
    friend GC, Diagnostics, IntMath, SysCall;
    
    // String memory map:
    //   0000 heap allocator size
    //   0F   type = tString
    //   00   GC reference count
    //   0000 string length n
    //   00   first char in string
    //   ..
    //   <n>  last char in string
    
    const uint siLength = 2;
    const uint siChars  = 4;
    
    dump()
    {
        PHA
        PHY
        
        // String in IDX
        LDA # ' '
        Serial.WriteChar();
        
        // length
        LDY # (siLength+2)
        INY
        LDA [IDX], Y
        Serial.HexOut();
        DEY
        LDA [IDX], Y
        TAX
        Serial.HexOut();
        
        LDA # ' '
        Serial.WriteChar();
        LDA # '\''
        Serial.WriteChar();
        
        LDY # (siChars+2)
        loop
        {
            CPX #0
            if (Z) { break; }
            LDA [IDX], Y
            Serial.WriteChar();
            INY
            DEX
        }
        LDA # '\''
        Serial.WriteChar();
        
        PLY
        PLA
    }
    
    new()
    {
        // round up string allocations to 16 byte boundaries
        CLC
        LDA FSIZEL
        ADC # 2
        STA FSIZEL
        LDA FSIZEH
        ADC # 0
        STA FSIZEH
        
        // type in A
        // size is in FSIZE
        // return address in IDX
        LDA # Types.String
        GC.Create();
    }
    
    getCapacity()
    {
        // this in IDX
        // return capacity in FSIZE
        //    munts ACC
        SEC
        LDA IDXL
        SBC # 2
        STA ACCL
        LDA IDXH
        SBC # 0
        STA ACCH
        
        LDY # 0
        SEC
        LDA [ACC], Y
        SBC # 6
        STA FSIZEL
        INY
        LDA [ACC], Y
        SBC # 0
        STA FSIZEH
    }
    getLength()
    {
        LDY # siLength
        LDA [IDX], Y
        STA FLENGTHL
        INY
        LDA [IDX], Y
        STA FLENGTHH
    }
    setLength()
    {
        LDY # siLength
        LDA FLENGTHL
        STA [IDX], Y
        INY
        LDA FLENGTHH
        STA [IDX], Y
    }
    loadDestFromIDX() 
    {
        CLC
        LDA IDXL
        ADC # siChars
        STA FDESTINATIONADDRESSL
        LDA IDXH
        ADC #0
        STA FDESTINATIONADDRESSH
    }
    loadDestFromIDY() 
    {
        CLC
        LDA IDYL
        ADC # siChars
        STA FDESTINATIONADDRESSL
        LDA IDYH
        ADC #0
        STA FDESTINATIONADDRESSH
    }
    
    loadSourceFromIDX() 
    {
        CLC
        LDA IDXL
        ADC # siChars
        STA FSOURCEADDRESSL
        LDA IDXH
        ADC #0
        STA FSOURCEADDRESSH
    }
    
    compareEqual()
    {
        // compare two objects in IDX and IDY
        //    munts Y, sets X
        //    uses LCOUNT, FSOURCEADDRESS, FDESTINATIONADDRESS
        
        loadSourceFromIDX();
        loadDestFromIDY();
        
        LDY # siLength
        LDA [IDX], Y
        STA LCOUNTL
        INY
        LDA [IDX], Y
        STA LCOUNTH
        
        loop
        {
            // check that lengths are the same
            LDA [IDY], Y
            CMP LCOUNTH
            if (NZ)
            {
                LDX # 0 // different -> not equal
                break;
            }
            DEY
            LDA [IDY], Y
            CMP LCOUNTL
            if (NZ)
            {
                LDX # 0 // different -> not equal
                break;
            }
            
            LDY # 0
            loop
            {
                LDA LCOUNTL
                if (Z)
                {
                    LDA LCOUNTH
                    if (Z)
                    {
                        LDX # 1 // no different -> equal
                        break;
                    }
                }
                LDA [FSOURCEADDRESS], Y
                CMP [FDESTINATIONADDRESS], Y
                if (NZ)
                {
                    LDX # 0 // different -> not equal
                    break;
                }
                IncDESTINATIONADDRESS();
                IncSOURCEADDRESS();
                
                LDA LCOUNTL
                if (Z)
                {
                    DEC LCOUNTH
                }
                DEC LCOUNTL 
            } // loop
            break;
        } // loop
    }
    
    // replace all references 'IDY' of FTYPE with 'IDX'
    //    munts Y
    replaceStackReferences()
    {
        LDY ZP.SP
        loop
        {
            CPY #0
            if (Z) { break; }
            DEY
            LDA Address.TypeStackLSB, Y       
            CMP FTYPE
            if (NZ) { continue; }
                    
            LDA Address.ValueStackLSB, Y
            CMP IDYL
            if (NZ) { continue; }
            
            LDA Address.ValueStackMSB, Y
            CMP IDYH
            if (NZ) { continue; }
            
            // winner
            LDA IDXL
            STA Address.ValueStackLSB, Y
            LDA IDXH
            STA Address.ValueStackMSB, Y
        } // loop
    }
    
    
        
    
    
    // string in IDX, required new length in FSIZE - new string returned in IDX (stack references updated)
    //    munts FSIZE, FDESTINATIONADDRESS, FTYPE
    stringEnlarge()
    {
        PHA
        LDA IDYL
        PHA
        LDA IDYH
        PHA
        LDA LCOUNTL
        PHA
        LDA LCOUNTH
        PHA
        LDA FSOURCEADDRESSL
        PHA
        LDA FSOURCEADDRESSH
        PHA
        
        // add 2 bytes for string length field
        CLC
        LDA FSIZEL  // LSB
        ADC # 2
        STA FSIZEL
        LDA FSIZEH  // MSB
        ADC # 0
        STA FSIZEH
        
        LDA IDXH
        STA IDYH
        LDA IDXL
        STA IDYL
        
        // type in A
        // size is in FSIZE
        // return address in IDX
        LDA # Types.String
        GC.Create();
        
        // clone size: string length + 2 bytes for length field + another 2 bytes for type and reference count
        IncSIZE();
        IncSIZE();
        
        LDA IDYL
        STA FSOURCEADDRESSL
        LDA IDYH
        STA FSOURCEADDRESSH
        
        LDA IDXL
        STA FDESTINATIONADDRESSL
        LDA IDXH
        STA FDESTINATIONADDRESSH
        
        LDA FSIZEL
        STA LCOUNTL
        LDA FSIZEH
        STA LCOUNTH
        
        // NOTES: in places we're using CopyBytes to clone the string header too (type, reference count and length : 4 bytes more than length)
        // copy LCOUNT chars from FSOURCEADDRESS to FDESTINATIONADDRESS
        Utilities.CopyBytes(); // munts LCOUNT, FSOURCEADDRESS, FDESTINATIONADDRESS, A, Y
        
        // IDY -> IDX
        LDA # Types.String
        STA FTYPE
        replaceStackReferences(); // munts Y
        
        LDA IDXL
        PHA
        LDA IDXH
        PHA
        
        LDA IDYL
        STA IDXL
        LDA IDYH
        STA IDXH
        Free.Free(); // free the original from under the nose of the GC
        
        PLA
        STA IDXH
        PLA
        STA IDXL
        
        PLA
        STA FSOURCEADDRESSH
        PLA
        STA FSOURCEADDRESSL
        PLA
        STA LCOUNTH
        PLA
        STA LCOUNTL
        PLA
        STA IDYH
        PLA
        STA IDYL
        PLA    
    }
    
    New()
    {
        LDA # 0
        STA FSIZEL
        STA FSIZEH
        new();
        
        // length=0
        LDY # siLength
        LDA # 0
        STA [IDX], Y
        INY
        STA [IDX], Y
        
        LDA IDXL
        STA TOPL
        LDA IDXH
        STA TOPH
        LDA # Types.String
        Stacks.PushTop();
    }
    newFromConstant0()
    {
        Stacks.PopTopNext();  // size, location
        LDA TOPL
        STA FLENGTHL
        STA FSIZEL
        LDA TOPH
        STA FLENGTHH
        STA FSIZEH
        
        // constant data address -> FSOURCEADDRESSL
        LDY # 2
        CLC
        LDA Address.HopperData, Y
        ADC # (Address.HopperData & 0xFF)
        STA FSOURCEADDRESSL
        INY
        LDA Address.HopperData, Y
        ADC # (Address.HopperData >> 8)
        STA FSOURCEADDRESSH
        
        // += location
        CLC
        LDA NEXTL
        ADC FSOURCEADDRESSL
        STA FSOURCEADDRESSL
        LDA NEXTH
        ADC FSOURCEADDRESSH
        STA FSOURCEADDRESSH
        
        new();
        
        LDY # siLength
        LDA FLENGTHL
        STA [IDX], Y
        STA LCOUNTL
        INY
        LDA FLENGTHH
        STA [IDX], Y
        STA LCOUNTH
        
        loadDestFromIDX();
        
        // copy LCOUNT chars from FSOURCEADDRESS to FDESTINATIONADDRESS
        Utilities.CopyBytes(); // munts LCOUNT, FSOURCEADDRESS, FDESTINATIONADDRESS, A, Y
               
        LDA IDXL
        STA TOPL
        LDA IDXH
        STA TOPH
        LDA # Types.String
        Stacks.PushTop();
    }
    newFromConstant1()
    {
        Stacks.PopTop();  // char0 and char1
        LDA TOPH
        //CMP # 0
        if (NZ)
        {
            LDA # 2
            STA FLENGTHL
        }
        else
        {
            LDA # 1
            STA FLENGTHL
        }
        STA FSIZEL
        
        LDA # 0
        STA FLENGTHH
        STA FSIZEH
             
        new();
        
        LDY # siLength
        LDA FLENGTHL
        STA [IDX], Y
        INY
        LDA FLENGTHH
        STA [IDX], Y
        
        CLC
        LDA IDXL
        ADC # siChars
        STA FDESTINATIONADDRESSL
        LDA IDXH
        ADC # 0
        STA FDESTINATIONADDRESSH
              
        // SOURCEADDRESS -> DESTINATIONADDRESS
        LDY # 0
        LDA TOPL
        STA [FDESTINATIONADDRESS], Y
        
        LDA TOPH
        //CMP # 0
        if (NZ)
        {
            INY    
            STA [FDESTINATIONADDRESS], Y
        }    
        
        LDA IDXL
        STA TOPL
        LDA IDXH
        STA TOPH
        LDA # Types.String
        Stacks.PushTop();
    }
    NewFromConstant()
    {
        LDA ACCL
        //CMP # 0
        if (Z)
        {
            newFromConstant0();
            return;
        }
        else
        {
            CMP #1
            if (Z)
            {
                newFromConstant1();
                return;
            }
        }
        LDA # 0x0B 
        Diagnostics.die();
    }
    LengthGet()
    {
        Stacks.PopIDX(); // this
        
        LDY # siLength
        LDA [IDX], Y
        STA NEXTL
        INY
        LDA [IDX], Y
        STA NEXTH
        
        GC.Release();
        
        LDA # Types.UInt
        Stacks.PushNext();
    }
    GetChar()
    {
        Stacks.PopIDY();  // index
        Stacks.PopIDX();  // this
#ifdef CHECKED
        // index < siLength?
        LDY # siLength+1
        LDA ZP.IDYH        // index MSB
        CMP [IDX], Y       // siLength MSB
        if (Z)
        {
            DEY
            LDA ZP.IDYL    // index LSB
            CMP [IDX], Y   // siLength LSB
        }
        if (C) // index < siLength?
        {
            // index >= siLength
            LDA # 0x05 // string index out of range
            Diagnostics.die();
        }
#endif
        CLC
        LDA IDYL
        ADC IDXL
        STA IDYL
        LDA IDYH
        ADC IDXH
        STA IDYH
        
        LDY # siChars
        LDA [IDY], Y
        STA TOPL
        LDA # 0
        STA TOPH
        
        GC.Release(); // this
        
        LDA # Types.Char
        Stacks.PushTop();
    }
    build0()
    {
        // Build(ref string build, string append) system;
        Stacks.PopTopNext();
        
        // appendString -> IDX
        LDA TOPL
        STA IDXL
        LDA TOPH
        STA IDXH
        
        getLength();                       // (IDX), 2 -> FLENGTH
        LDA FLENGTHL                       // number of characters to append -> LCOUNT
        STA LCOUNTL
        LDA FLENGTHH
        STA LCOUNTH
        loadSourceFromIDX();               // (IDX), 4 -> FSOURCEADDRESS
        
        // ref build -> IDX
        LDY NEXTL
        LDA Address.ValueStackLSB, Y
        STA IDXL
        LDA Address.ValueStackMSB, Y
        STA IDXH
        getCapacity();                     // IDX -> string, returns capacity in FSIZE
        getLength();                       // (IDX), 2 -> FLENGTH
        
        CLC                                // fVALUE = fLENGTH (length of build) + lCOUNT (length of appendString)
        LDA FLENGTHL 
        ADC LCOUNTL
        STA FVALUEL
        LDA FLENGTHH
        ADC LCOUNTH
        STA FVALUEH
        
        // fVALUE >= fSIZE?
        LDA FVALUEH
        CMP FSIZEH
        if (Z)
        {
            LDA FVALUEL
            CMP FSIZEL
        }
        if (C)
        {
            // FVALUE >= FSIZE
            LDA FVALUEL
            STA FSIZEL
            LDA FVALUEH
            STA FSIZEH
            
            // string in IDX, required new length in FSIZE - new string returned in IDX (stack references updated)
            stringEnlarge();
        }
        
        loadDestFromIDX();
        CLC
        LDA FDESTINATIONADDRESSL
        ADC FLENGTHL
        STA FDESTINATIONADDRESSL
        LDA FDESTINATIONADDRESSH
        ADC FLENGTHH
        STA FDESTINATIONADDRESSH
        
        // copy LCOUNT chars from FSOURCEADDRESS to FDESTINATIONADDRESS
        Utilities.CopyBytes();   // munts LCOUNT, FSOURCEADDRESS, FDESTINATIONADDRESS, A, Y
        
        LDA FVALUEL
        STA FLENGTHL
        LDA FVALUEH
        STA FLENGTHH
        setLength();  // FLENGTH -> (IDX), 2
        
        
        // release appendString
        LDA TOPL
        STA IDXL
        LDA TOPH
        STA IDXH
        GC.Release();
    }  
    build1()
    {
        // Build(ref string build, char append) system;
        Stacks.PopTopNext();
        
        // ref build -> IDY  X      
        LDY NEXTL
        LDA Address.ValueStackLSB, Y
        STA IDXL
        LDA Address.ValueStackMSB, Y
        STA IDXH
        
        getCapacity(); // -> FSIZE
        getLength();   // -> FLENGTH
        
        // FLENGTH >= FSIZE?
        LDA FLENGTHH
        CMP FSIZEH
        if (Z)
        {
            LDA FLENGTHL
            CMP FSIZEL
        }
        if (C)
        {
            // FLENGTH >= FSIZE
            LDA FLENGTHL
            STA FSIZEL
            LDA FLENGTHH
            STA FSIZEH
            IncSIZE();    // 1 for the new extra character
            
            // string in IDX, required new length in fSIZE - new string returned in IDX (stack references updated)
            stringEnlarge();
        }

        // build[length] = appendChar
        loadDestFromIDX();
        CLC
        LDA FDESTINATIONADDRESSL
        ADC FLENGTHL
        STA FDESTINATIONADDRESSL
        LDA FDESTINATIONADDRESSH
        ADC FLENGTHH
        STA FDESTINATIONADDRESSH                          
        LDY # 0
        LDA TOPL
        STA [FDESTINATIONADDRESS], Y
        
        IncLENGTH();                              // length++
        setLength();                              // FLENGTH -> (IDX), 2
    }  
    BuildFront()
    {
        // BuildFront(ref string build, char insert) system;
        Stacks.PopTopNext();
        
        // ref build -> IDY  X     
        LDY NEXTL
        LDA Address.ValueStackLSB, Y
        STA IDXL
        LDA Address.ValueStackMSB, Y
        STA IDXH
        
        getCapacity(); // -> FSIZE
        getLength();   // -> FLENGTH
        
        // FLENGTH >= FSIZE?
        LDA FLENGTHH
        CMP FSIZEH
        if (Z)
        {
            LDA FLENGTHL
            CMP FSIZEL
        }
        if (C)
        {
            // FLENGTH >= FSIZE
            LDA FLENGTHL
            STA FSIZEL
            LDA FLENGTHH
            STA FSIZEH
            IncSIZE();    // 1 for the new extra character
            
            // string in IDX, required new length in fSIZE - new string returned in IDX (stack references updated)
            stringEnlarge();
        }
        
        // shift string forward by one in reverse (make room in front)
        loadSourceFromIDX();
        CLC
        LDA FSOURCEADDRESSL
        ADC FLENGTHL
        STA FSOURCEADDRESSL
        STA FDESTINATIONADDRESSL
        LDA FSOURCEADDRESSH
        ADC FLENGTHH
        STA FSOURCEADDRESSH
        STA FDESTINATIONADDRESSH
        
        DecSOURCEADDRESS();        // by one.. (munts A)
        
        LDA FLENGTHL
        STA FSIZEL
        LDA FLENGTHH
        STA FSIZEH
        
        loop
        {
            LDA FSIZEL
            if (Z)
            {
                LDA FSIZEH
                if (Z)
                {
                    break;
                }
            }
    
            LDY # 0        
            LDA [FSOURCEADDRESS], Y
            STA [FDESTINATIONADDRESS] , Y
            
            DecSOURCEADDRESS();      // munts A
            
            LDA FDESTINATIONADDRESSL
            if (Z)
            {
                DEC FDESTINATIONADDRESSH
            }
            DEC FDESTINATIONADDRESSL
            
            LDA FSIZEL
            if (Z)
            {
                DEC FSIZEH
            }
            DEC FSIZEL
        }

        // build[0] = insertChar
        LDY # 0
        LDA TOPL
        STA [FDESTINATIONADDRESS], Y
        
        IncLENGTH();                              // length++
        setLength();                              // FLENGTH -> (IDX), 2
    }    
    build2()
    {
        // Build(ref string build) system;
        Stacks.PopTop(); 

        LDY TOPL
        LDA Address.ValueStackLSB, Y
        STA IDXL
        LDA Address.ValueStackMSB, Y
        STA IDXH
        
        LDY # siLength
        LDA # 0
        STA [IDX], Y
        INY
        STA [IDX], Y
    }
            
    Build()
    {
        LDA ACCL
        //CMP # 0
        if (Z)
        {
            build0();
            return;
        }
        else 
        {
            CMP # 1
            if (Z)
            {
                
                build1();
                return;
            }
            else
            {
                build2();
                return;
            }
        }
    }
}
