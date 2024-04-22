unit Z80Library
{
    uses "CODEGEN/AsmZ80"
    uses "CODEGEN/Z80LibraryGenerated"
    
    <string, uint> libraryAddresses;
    
    uint GetAddress(string name)
    {
        return libraryAddresses[name];
    }
    uint compareSignedLocation;
    uint utilityMultiplyLocation;
    uint utilityDivideLocation;
    
    uint negateBCLocation;
    uint negateDELocation;
    uint negateHLLocation;
    uint doSignsLocation;
    
    Generate()
    {
        uint address = CurrentAddress;
        compareSigned();
        compareSignedLocation = address;
        
        address = CurrentAddress;
        utilityMultiply();
        utilityMultiplyLocation = address;
        
        address = CurrentAddress;
        utilityDivide();
        utilityDivideLocation = address;
        
        address = CurrentAddress;
        negateBC();
        negateBCLocation = address;
        
        address = CurrentAddress;
        negateDE();
        negateDELocation = address;
        
        address = CurrentAddress;
        negateHL();
        negateHLLocation = address;
        
        address = CurrentAddress;
        doSigns();
        doSignsLocation = address;
    
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMUL();
        libraryAddresses["MUL"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMULI();
        libraryAddresses["MULI"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitDIVMOD();
        libraryAddresses["DIVMOD"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitDIVI();
        libraryAddresses["DIVI"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMODI();
        libraryAddresses["MODI"] = address;
        
        /*
        address = CurrentAddress;
        Peephole.Reset();
        EmitEQ();
        libraryAddresses["EQ"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitNE();
        libraryAddresses["NE"] = address;
        
        */
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitLE();
        libraryAddresses["LE"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitLEI();
        libraryAddresses["LEI"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitLT();
        libraryAddresses["LT"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitLTI();
        libraryAddresses["LTI"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGT();
        libraryAddresses["GT"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGTI();
        libraryAddresses["GTI"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGE();
        libraryAddresses["GE"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGEI();
        libraryAddresses["GEI"] = address;
        
        /*
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITAND();
        libraryAddresses["BITAND"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITOR();
        libraryAddresses["BITOR"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITXOR();
        libraryAddresses["BITXOR"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITNOT();
        libraryAddresses["BITNOT"] = address;
        */
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITSHL();
        libraryAddresses["BITSHL"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitBITSHR();
        libraryAddresses["BITSHR"] = address;
        
        // SysCalls
        address = CurrentAddress;
        Peephole.Reset();
        EmitIntGetByte();
        libraryAddresses["IntGetByte"] = address;

        address = CurrentAddress;
        Peephole.Reset();
        EmitSerialIsAvailable();
        libraryAddresses["SerialIsAvailable"] = address;
                
        address = CurrentAddress;
        Peephole.Reset();
        EmitSerialWriteChar();
        libraryAddresses["SerialWriteChar"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitSerialReadChar();
        libraryAddresses["SerialReadChar"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMemoryAvailable();
        libraryAddresses["MemoryAvailable"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMemoryMaximum();
        libraryAddresses["MemoryMaximum"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMemoryAllocate();
        libraryAddresses["MemoryAllocate"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitMemoryFree();
        libraryAddresses["MemoryFree"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGCCreate();
        libraryAddresses["GCCreate"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGCClone();
        libraryAddresses["GCClone"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitGCRelease();
        libraryAddresses["GCRelease"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitStringNew();
        libraryAddresses["StringNew"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitStringGetLength();
        libraryAddresses["StringGetLength"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitArrayNew();
        libraryAddresses["ArrayNew"] = address;
        
        address = CurrentAddress;
        Peephole.Reset();
        EmitArrayGetCount();
        libraryAddresses["ArrayGetCount"] = address;
    }
    
    EmitIntGetByte()
    {
        Emit(OpCode.BIT_0_E);     // 0 or 1?
        EmitOffset(OpCode.JR_Z_e, +2);     // skip to where we clear MSB
        Emit(OpCode.LD_E_H);
        Emit(OpCode.LD_L_E);
        Emit(OpCode.LD_H_D);             // use zero D to clear MSB
        Emit(OpCode.RET);
    }
    
    utilityDivide() // BC = BC / DE, remainder in HL
    {
        // https://map.grauw.nl/articles/mult_div_shifts.php
        Peephole.Disabled = true;
        Emit(OpCode.AND_A);

        EmitWord(OpCode.LD_HL_nn, 0);
        Emit(OpCode.LD_A_B);
        EmitByte(OpCode.LD_B_n, 8);
// Div16_Loop1:
        Emit(OpCode.RLA);
        Emit(OpCode.ADC_HL_HL);
        Emit(OpCode.SBC_HL_DE);
        EmitOffset(OpCode.JR_NC_e, +1); // Div16_NoAdd1
        Emit(OpCode.ADD_HL_DE);
// Div16_NoAdd1:
        EmitOffset(OpCode.DJNZ_e, -10);// Div16_Loop1
        
        Emit(OpCode.RLA);
        Emit(OpCode.CLP);
        Emit(OpCode.LD_B_A);
        Emit(OpCode.LD_A_C);
        Emit(OpCode.LD_C_B);
        EmitByte(OpCode.LD_B_n, 8);
        
// Div16_Loop2:
        Emit(OpCode.RLA);
        Emit(OpCode.ADC_HL_HL);
        Emit(OpCode.SBC_HL_DE);
        EmitOffset(OpCode.JR_NC_e, +1); // Div16_NoAdd2
        Emit(OpCode.ADD_HL_DE);
// Div16_NoAdd2:
        EmitOffset(OpCode.DJNZ_e, -10);// Div16_Loop2
        
        Emit(OpCode.RLA);
        Emit(OpCode.CLP);
        Emit(OpCode.LD_B_C);
        Emit(OpCode.LD_C_A); 
        
        Emit(OpCode.RET);
        
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    utilityMultiply() // DEHL=BC*DE
    {
        Peephole.Disabled = true;
        // https://tutorials.eeems.ca/Z80ASM/part4.htm
        EmitWord(OpCode.LD_HL_nn, 0);                          
        EmitByte(OpCode.LD_A_n, 16);
//Mul16Loop:
        Emit(OpCode.ADD_HL_HL);
        Emit(OpCode.RL_E);
        Emit(OpCode.RL_D);
        EmitOffset(OpCode.JR_NC_e, +4); // NoMul16:
        Emit(OpCode.ADD_HL_BC);
        EmitOffset(OpCode.JR_NC_e, +1); // NoMul16:
        Emit(OpCode.INC_DE);
//NoMul16:
        Emit(OpCode.DEC_A);
        EmitOffset(OpCode.JR_NZ_e, -14); // //Mul16Loop:
        Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitLE()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL <= BC ? 1 : 0   
        
        EmitWord(OpCode.LD_DE_nn, 1);     // LSB: result = true
        
        Emit(OpCode.LD_A_H);              // MSB
        Emit(OpCode.CP_A_B);     
        EmitOffset(OpCode.JR_NZ_e,  +2);  // UseMSB
        Emit(OpCode.LD_A_L);              // LSB
        Emit(OpCode.CP_A_C);      
//UseMSB:        
        EmitOffset(OpCode.JR_Z_e, +4);    // Exit
        EmitOffset(OpCode.JR_C_e, +2);    // Exit
        EmitByte(OpCode.LD_E_n, 0);       // LSB: result = false
// Exit:       
        Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitLT()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL < BC ? 1 : 0   
        
        EmitWord(OpCode.LD_DE_nn, 0);     // LSB: result = false
        
        Emit(OpCode.LD_A_H);              // MSB
        Emit(OpCode.CP_A_B);     
        EmitOffset(OpCode.JR_NZ_e, +2);   // UseMSB
        Emit(OpCode.LD_A_L);              // LSB
        Emit(OpCode.CP_A_C);      
//UseMSB:
        EmitOffset(OpCode.JR_NC_e, +2);   // Exit
        EmitByte(OpCode.LD_E_n, 1);       // LSB: result = true
// Exit:       
        Emit(OpCode.RET); 
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitGT()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL > BC ? 1 : 0   
        
        EmitWord(OpCode.LD_DE_nn, 0);     // LSB: result = false
        
        Emit(OpCode.LD_A_H);              // MSB
        Emit(OpCode.CP_A_B);     
        EmitOffset(OpCode.JR_NZ_e,  +2);  // UseMSB
        Emit(OpCode.LD_A_L);              // LSB
        Emit(OpCode.CP_A_C);      
//UseMSB:        
        EmitOffset(OpCode.JR_Z_e, +4);    // Exit
        EmitOffset(OpCode.JR_C_e, +2);    // Exit
        EmitByte(OpCode.LD_E_n, 1);       // LSB: result = true
// Exit:       
        Emit(OpCode.RET); 
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitEQ()
    {
        Peephole.Disabled = true;
        // top -> BC, next -> HL 
        
        EmitWord(OpCode.LD_DE_nn, 0);    // LSB: result = false
        
        // Compare BC and HL
        Emit(OpCode.LD_A_B);             // MSB     
        Emit(OpCode.CP_A_H);     
        EmitOffset(OpCode.JR_NZ_e,  +6); // B!= H -> Exit
        Emit(OpCode.LD_A_C);             // LSB
        Emit(OpCode.CP_A_L);      
        EmitOffset(OpCode.JR_NZ_e,  +2); // C != L -> Exit
        // BC == HL
        EmitByte(OpCode.LD_E_n, 1);      // LSB: result = true
// Exit:        
        //Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    EmitNE()
    {
        Peephole.Disabled = true;
        // top -> BC, next -> HL 
        
        EmitWord(OpCode.LD_DE_nn, 1);     // LSB: result = true
        
        // Compare BC and HL
        Emit(OpCode.LD_A_B);              // MSB     
        Emit(OpCode.CP_A_H);     
        EmitOffset(OpCode.JR_NZ_e,  +6);  // B!= H -> Exit
        Emit(OpCode.LD_A_C);              // LSB
        Emit(OpCode.CP_A_L);      
        EmitOffset(OpCode.JR_NZ_e,  +2);  // C != L -> Exit
        // BC == HL
        EmitByte(OpCode.LD_E_n, 0);       // LSB: result = false
// Exit:        
        //Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitGE()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // GE: next = HL >= BC ? 1 : 0   
        
        EmitWord(OpCode.LD_DE_nn, 0);     // LSB: result = false
        
        Emit(OpCode.LD_A_H);              // MSB
        Emit(OpCode.CP_A_B);     
        EmitOffset(OpCode.JR_NZ_e, +2);   // UseMSB
        Emit(OpCode.LD_A_L);              // LSB
        Emit(OpCode.CP_A_C);      
//UseMSB:
        EmitOffset(OpCode.JR_C_e, +2);    // Exit
        EmitByte(OpCode.LD_E_n, 1);       // LSB: result = true
// Exit:       
        Emit(OpCode.RET); 
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitBITSHL()
    {
        // next -> HL, top -> BC 
        // HL = next << top
        
        Emit(OpCode.LD_B_C); // (assuming the shift is < 256)
        
        Peephole.Disabled = true;
        Emit(OpCode.AND_A);
        Emit(OpCode.SLA_L);
        Emit(OpCode.RL_H);
        EmitOffset(OpCode.DJNZ_e, -7);
        Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    EmitBITSHR()
    {
        // next -> HL, top -> BC
        // HL = next >> top
        
        Emit(OpCode.LD_B_C); // (assuming the shift is < 256)
        
        Peephole.Disabled = true;
        Emit(OpCode.AND_A);
        Emit(OpCode.SRL_H);
        Emit(OpCode.RR_L);
        EmitOffset(OpCode.DJNZ_e, -7);
        Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    
    EmitBITAND()
    {
        // next -> HL, top -> BC
        // HL = next & top
        
        Emit(OpCode.LD_A_L);
        Emit(OpCode.AND_A_C);
        Emit(OpCode.LD_L_A);
        Emit(OpCode.LD_A_H);
        Emit(OpCode.AND_A_B);
        Emit(OpCode.LD_H_A);
        //Emit(OpCode.RET);
    }
    
    EmitBITOR()
    {
        // next -> HL, top -> BC
        // HL = next | top
        
        Emit(OpCode.LD_A_L);
        Emit(OpCode.OR_A_C);
        Emit(OpCode.LD_L_A);
        Emit(OpCode.LD_A_H);
        Emit(OpCode.OR_A_B);
        Emit(OpCode.LD_H_A);
        //Emit(OpCode.RET);
    }
    
    EmitBITXOR()
    {
        // next -> HL, top -> BC
        // HL = next ^ top
        
        Emit(OpCode.LD_A_L);
        Emit(OpCode.XOR_A_C);
        Emit(OpCode.LD_L_A);
        Emit(OpCode.LD_A_H);
        Emit(OpCode.XOR_A_B);
        Emit(OpCode.LD_H_A);
        //Emit(OpCode.RET);
    }
    
    EmitBITNOT()
    {
        // top -> HL
        // HL = ~top
        
        Emit(OpCode.LD_A_L);
        Emit(OpCode.CPL_A_A);
        Emit(OpCode.LD_L_A);
        Emit(OpCode.LD_A_H);
        Emit(OpCode.CPL_A_A);
        Emit(OpCode.LD_H_A);
        //Emit(OpCode.RET);
    }
    
    compareSigned()
    {
        // From Rodnay Zaks' book:
        // sets the carry flag if HL < BC and the Z flag is HL == BC
        
        Emit(OpCode.LD_A_H);
        EmitByte(OpCode.AND_A_n, 0x80);  // test sign, clear carry
        EmitOffset(OpCode.JR_NZ_e, +9);  // --> HL is -ve
        Emit(OpCode.BIT_7_B);
        Emit(OpCode.RET_NZ);             // --> BC is -ve
        Emit(OpCode.LD_A_H);
        Emit(OpCode.CP_A_B);
        Emit(OpCode.RET_NZ);             // --> both signs are +ve
        Emit(OpCode.LD_A_L);
        Emit(OpCode.CP_A_C);
        Emit(OpCode.RET);
// --> HL is -ve
        Emit(OpCode.XOR_A_B);
        Emit(OpCode.RLA);                // sign bit to carry
        Emit(OpCode.RET_C);              // signs different
        Emit(OpCode.LD_A_H);
        Emit(OpCode.CP_A_B);
        Emit(OpCode.RET_Z);              // --> bith signs -ve
        Emit(OpCode.LD_A_L);
        Emit(OpCode.CP_A_C);
        Emit(OpCode.RET);                // -->
    }
     /*  
    EmitLTI()
    {
        Peephole.Disabled = true;
        
        EmitWord(OpCode.LD_DE_nn, 0);     // LSB: result = false
        
        // sets the C flag if HL < BC and the Z flag is HL == BC
        EmitWord(OpCode.CALL_nn, compareSignedLocation);
        //EmitOffset(OpCode.JR_NZ_e, +4);
        EmitOffset(OpCode.JR_NC_e, +2);
        EmitByte(OpCode.LD_E_n, 1);       // LSB: result = true
        Emit(OpCode.RET);
        Peephole.Disabled = false;
        Peephole.Reset();
    }    
    */
    EmitLTI()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL < BC ? 1 : 0   
        
        Emit(OpCode.LD_A_H);
        Emit(OpCode.XOR_A_B);
        EmitWord(OpCode.JP_M_nn, 0);           // -> differentSigns
        
        uint jumpAddress = CurrentAddress-2;
        Emit(OpCode.SBC_HL_BC);
        EmitOffset(OpCode.JR_NC_e, +8);       // HL - BC >= 0? (same signs) : NC -> falseExit
        // C implies HL < BC
// trueExit:
        EmitWord(OpCode.LD_DE_nn, 1);         // result = true
        Emit(OpCode.RET);
        
// differentSigns:        
        uint jumpToAddress = CurrentAddress;
        Emit(OpCode.BIT_7_B);        
        EmitOffset(OpCode.JR_Z_e, -8);        // BC is +ve (which means HL is -ve) -> trueExit
        
// falseExit:
        EmitWord(OpCode.LD_DE_nn, 0);         // result = false
        Emit(OpCode.RET);
        
        
        PatchByte(jumpAddress+0, byte (jumpToAddress & 0xFF));
        PatchByte(jumpAddress+1, byte (jumpToAddress >> 8));
        
        Peephole.Disabled = false;
        Peephole.Reset();
    }   
    
    // https://www.msx.org/forum/development/msx-development/how-compare-16bits-registers-z80
    EmitGEI()
    {
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL >= BC ? 1 : 0   
        
        
        Emit(OpCode.LD_A_H);
        Emit(OpCode.XOR_A_B);
        EmitWord(OpCode.JP_M_nn, 0);           // -> differentSigns
        uint jumpAddress = CurrentAddress-2;
        
        // same signs: HL - BC >= 0?
        Emit(OpCode.SBC_HL_BC);
        EmitOffset(OpCode.JR_NC_e, +8);       // NC implies >= -> trueExit
        // C implies HL < BC
// falseExit:
        EmitWord(OpCode.LD_DE_nn, 0);         // result = false
        Emit(OpCode.RET);
        
// differentSigns:        
        uint jumpToAddress = CurrentAddress;
        Emit(OpCode.BIT_7_B);        
        EmitOffset(OpCode.JR_Z_e, -8);        // BC is +ve (which means HL is -ve) -> falseExit
        
// trueExit:
        EmitWord(OpCode.LD_DE_nn, 1);         // result = true
        Emit(OpCode.RET);
        
        
        PatchByte(jumpAddress+0, byte (jumpToAddress & 0xFF));
        PatchByte(jumpAddress+1, byte (jumpToAddress >> 8));
        
        Peephole.Disabled = false;
        Peephole.Reset();
    }  
    
    EmitLEI()
    { 
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL <= BC ? 1 : 0   
        
        Emit(OpCode.LD_A_H);
        Emit(OpCode.XOR_A_B);
        EmitWord(OpCode.JP_M_nn, 0);           // -> differentSigns
        
        uint jumpAddress = CurrentAddress-2;
        Emit(OpCode.SBC_HL_BC);
        EmitOffset(OpCode.JR_Z_e, +2);        // HL == BC : -> trueExit
        EmitOffset(OpCode.JR_NC_e, +8);       // HL - BC >= 0? (same signs) : C -> falseExit
        // C implies HL >= BC
// trueExit:
        EmitWord(OpCode.LD_DE_nn, 1);         // result = true
        Emit(OpCode.RET);
        
// differentSigns:        
        uint jumpToAddress = CurrentAddress;
        Emit(OpCode.BIT_7_B);        
        EmitOffset(OpCode.JR_Z_e, -8);        // BC is +ve (which means HL is -ve) -> trueExit
        
// falseExit:
        EmitWord(OpCode.LD_DE_nn, 0);         // result = false
        Emit(OpCode.RET);
        
        
        PatchByte(jumpAddress+0, byte (jumpToAddress & 0xFF));
        PatchByte(jumpAddress+1, byte (jumpToAddress >> 8));
        
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    
    EmitGTI()
    { 
        Peephole.Disabled = true;
        // next -> HL, top -> BC
        // LE: next = HL > BC ? 1 : 0   
        
        Emit(OpCode.LD_A_H);
        Emit(OpCode.XOR_A_B);
        EmitWord(OpCode.JP_M_nn, 0);           // -> differentSigns
        
        uint jumpAddress = CurrentAddress-2;
        Emit(OpCode.SBC_HL_BC);
        EmitOffset(OpCode.JR_Z_e, +2);        // HL == BC : -> falseExit
        EmitOffset(OpCode.JR_NC_e, +8);       // HL - BC >= 0? (same signs) : C -> trueExit
        // C implies HL >= BC
// falseExit:
        EmitWord(OpCode.LD_DE_nn, 0);         // result = false
        Emit(OpCode.RET);
        
// differentSigns:        
        uint jumpToAddress = CurrentAddress;
        Emit(OpCode.BIT_7_B);        
        EmitOffset(OpCode.JR_Z_e, -8);        // BC is +ve (which means HL is -ve) -> falseExit
        
// trueExit:
        EmitWord(OpCode.LD_DE_nn, 1);         // result = true
        Emit(OpCode.RET);
        
        
        PatchByte(jumpAddress+0, byte (jumpToAddress & 0xFF));
        PatchByte(jumpAddress+1, byte (jumpToAddress >> 8));
        
        Peephole.Disabled = false;
        Peephole.Reset();
    }
    
    EmitMUL()
    {
        // top -> BC, next -> DE
        // HL = next * top
        EmitWord(OpCode.JP_nn, utilityMultiplyLocation); // DEHL=BC*DE
    }
    EmitDIVMOD()
    {
        // top -> BC, next -> DE
        // BC = next / top
        // HL = next % top
        
        EmitWord(OpCode.JP_nn, utilityDivideLocation); // BC = BC / DE, remainder in HL
    }
    
    // https://github.com/Zeda/Z80-Optimized-Routines/blob/master/math/subtraction/A_Minus_HL.z80
    negateBC()
    {
        Emit(OpCode.XOR_A_A);
        Emit(OpCode.SUB_A_C);
        Emit(OpCode.LD_C_A);
        Emit(OpCode.SBC_A_A);
        Emit(OpCode.SUB_A_B);
        Emit(OpCode.LD_B_A);
        Emit(OpCode.RET);
    }
    negateDE()
    {
        Emit(OpCode.XOR_A_A);
        Emit(OpCode.SUB_A_E);
        Emit(OpCode.LD_E_A);
        Emit(OpCode.SBC_A_A);
        Emit(OpCode.SUB_A_D);
        Emit(OpCode.LD_D_A);
        Emit(OpCode.RET);
    }
    negateHL()
    {
        Emit(OpCode.XOR_A_A);
        Emit(OpCode.SUB_A_L);
        Emit(OpCode.LD_L_A);
        Emit(OpCode.SBC_A_A);
        Emit(OpCode.SUB_A_H);
        Emit(OpCode.LD_H_A);
        Emit(OpCode.RET);
    }
    doSigns()
    {   
        // next = BC, top = DE
        EmitWord(OpCode.LD_HL_nn, Sign);
        EmitByte(OpCode.LD_iHL_n, 0);
        
        Emit(OpCode.BIT_7_B);     
        EmitOffset(OpCode.JR_Z_e, +4);  // -> check DE
// BC is -ve        
        Emit(OpCode.INC_iHL);
        EmitWord(OpCode.CALL_nn, negateBCLocation);
// check DE
        Emit(OpCode.BIT_7_D);
        EmitOffset(OpCode.JR_Z_e, +4);
// DE is -ve        
        Emit(OpCode.INC_iHL);
        EmitWord(OpCode.CALL_nn, negateDELocation);
// exit 
        Emit(OpCode.RET);   
    }
    EmitMULI()
    {
        EmitWord(OpCode.CALL_nn, doSignsLocation);
        EmitWord(OpCode.CALL_nn, utilityMultiplyLocation); // DEHL=BC*DE
     
        EmitWord(OpCode.LD_A_inn, Sign);   
        Emit(OpCode.RRA);    // bit 0 -> C
        Emit(OpCode.RET_NC); // even
        EmitWord(OpCode.CALL_nn, negateHLLocation);
        Emit(OpCode.RET);
    }
    EmitDIVI()
    {
        EmitWord(OpCode.CALL_nn, doSignsLocation);
        EmitWord(OpCode.CALL_nn, utilityDivideLocation); // BC = BC / DE, remainder in HL
        
        EmitWord(OpCode.LD_A_inn, Sign);   
        Emit(OpCode.RRA);    // bit 0 -> C
        Emit(OpCode.RET_NC); // even
        EmitWord(OpCode.CALL_nn, negateBCLocation);
        Emit(OpCode.RET);
    }
    EmitMODI()
    {
        EmitWord(OpCode.CALL_nn, doSignsLocation);
        EmitWord(OpCode.CALL_nn, utilityDivideLocation); // BC = BC / DE, remainder in HL
        Emit(OpCode.RET);
    }
    ISR()
    {
        Emit      (OpCode.PUSH_AF);
        Emit      (OpCode.PUSH_HL);
        
        EmitByte  (OpCode.IN_A_in, StatusRegister);
        
        // bit 7 is  interrupt request by 6850 
        Emit      (OpCode.BIT_7_A);        
        EmitOffset(OpCode.JR_Z_e, +30); // not 6850 ->Exit
        
        // bit 0 is  RDRF : receive data register full        
        Emit      (OpCode.BIT_0_A);        
        EmitOffset(OpCode.JR_Z_e, +26); // not full ->Exit
        
        EmitByte  (OpCode.IN_A_in, DataRegister); // reads the byte from serial (which clears the flags in StatusRegister)
        EmitByte  (OpCode.CP_A_n, 0x03);                   
        EmitOffset(OpCode.JR_NZ_e, +6); // not <ctrl><C>
        
// <ctrl><C>:
        EmitWord  (OpCode.LD_HL_nn, BreakFlag);
        Emit      (OpCode.INC_iHL);
        EmitOffset(OpCode.JR_e, +14); // Exit
        
// not <ctrl><C>:
        Emit      (OpCode.PUSH_DE);
        EmitWord  (OpCode.LD_DE_nn, InBuffer);
        EmitWord  (OpCode.LD_HL_nn, InWritePointer);
        Emit      (OpCode.LD_L_iHL);
        EmitByte  (OpCode.LD_H_n, 0);
        Emit      (OpCode.ADD_HL_DE);
        Emit      (OpCode.LD_iHL_A);
        EmitWord  (OpCode.LD_HL_nn, InWritePointer);
        Emit      (OpCode.INC_iHL);
        Emit      (OpCode.POP_DE); 
// Exit
        Emit      (OpCode.POP_HL);
        Emit      (OpCode.POP_AF);
        Emit      (OpCode.RETI);
    }
    EmitSerialWriteChar()
    {
        EmitByte  (OpCode.IN_A_in,  StatusRegister);
        Emit      (OpCode.BIT_1_A);     // Bit 1 - Transmit Data Register Empty (TDRE)
        EmitOffset(OpCode.JR_Z_e, -6);  // loop if not ready (bit set means TDRE is empty and ready)
        Emit      (OpCode.LD_A_L);
        EmitByte  (OpCode.OUT_in_A, DataRegister);
        Emit(OpCode.RET);
    }
    EmitSerialIsAvailable()
    {
        Emit      (OpCode.DI);
        Emit      (OpCode.XOR_A_A);
        EmitWord  (OpCode.LD_HL_nn, BreakFlag);
        Emit      (OpCode.CP_A_iHL);
        EmitOffset(OpCode.JR_NZ_e, +15); // <ctrl><C> -> True Exit
        
        EmitWord  (OpCode.LD_HL_nn, InWritePointer);
        Emit      (OpCode.LD_A_iHL);
        EmitWord  (OpCode.LD_HL_nn, InReadPointer);
        Emit      (OpCode.CP_A_iHL);
        EmitOffset(OpCode.JR_NZ_e, +5); // -> True Exit

// False Exit:        
        EmitWord  (OpCode.LD_HL_nn, 0x0000);
        EmitOffset(OpCode.JR_e, +3); // -> Exit
        
// True Exit:        
        EmitWord  (OpCode.LD_HL_nn, 0x0001);
// Exit:        
        Emit      (OpCode.EI);
        Emit      (OpCode.RET);
        // 0 or 1 returned in HL (R0)
    }
    EmitSerialReadChar()
    {
        EmitWord  (OpCode.CALL_nn, GetAddress("SerialIsAvailable"));
        Emit      (OpCode.XOR_A_A);
        Emit      (OpCode.CP_A_L);
        EmitOffset(OpCode.JR_Z_e, -7); // loop until available       
        
        EmitWord  (OpCode.LD_HL_nn, BreakFlag);
        Emit      (OpCode.CP_A_iHL);
        EmitOffset(OpCode.JR_Z_e, +7); // not break
        
        Emit      (OpCode.DI);
        Emit      (OpCode.DEC_iHL);        
        Emit      (OpCode.EI);
        EmitByte  (OpCode.LD_A_n, 0x03); // <ctrl><C>
        
        EmitOffset(OpCode.JR_e, +15); // -> Exit
        
// not break        
        
        EmitWord  (OpCode.LD_DE_nn, InBuffer);
        EmitWord  (OpCode.LD_HL_nn, InReadPointer);
        Emit      (OpCode.LD_L_iHL);
        EmitByte  (OpCode.LD_H_n, 0);
        Emit      (OpCode.ADD_HL_DE);
        Emit      (OpCode.LD_A_iHL);
        
        EmitWord  (OpCode.LD_HL_nn, InReadPointer);
        Emit      (OpCode.INC_iHL);
        
        Emit      (OpCode.LD_L_A);
        EmitByte  (OpCode.LD_H_n, 0);
        
// Exit        
        Emit(OpCode.RET);
        // character returned in HL (R0)
    }
    
    bool firstSysNotImplemented = true;
    bool SysCall(byte iSysCall, byte iOverload, ref bool referenceR0)
    {
        // iOverload is in A if it is needed
        switch (SysCalls(iSysCall))
        {
            case SysCalls.DiagnosticsDie:
            {
                Emit(OpCode.EX_iSP_HL); // error code is in [top] (HL)
                Emit(OpCode.LD_A_L);
                EmitWord(OpCode.LD_inn_A, LastError);
                Emit(OpCode.HALT);
            }
            case SysCalls.DiagnosticsSetError:
            {
                Emit(OpCode.EX_iSP_HL); // error code is in [top] (HL)
                EmitWord(OpCode.LD_inn_HL, LastError);
            }
            
            case SysCalls.MemoryReadByte:
            {
                Emit(OpCode.EX_iSP_IX);          // get the address from the stack
                EmitByte(OpCode.LD_L_iIX_d, +0); // read  the LSB
                EmitByte(OpCode.LD_H_n, 0);      // clear the MSB and return it in R0 (HL)
                referenceR0 = false;
            }
            case SysCalls.MemoryReadWord:
            {
                Emit(OpCode.EX_iSP_IX);          // get the address from the stack
                EmitByte(OpCode.LD_L_iIX_d, +0); // read the LSB
                EmitByte(OpCode.LD_H_iIX_d, +1); // read the MSB and  return it in R0 (HL)
                referenceR0 = false;
            }
            case SysCalls.MemoryWriteByte:
            {
                Emit(OpCode.POP_HL);                      // pop the value
                Emit(OpCode.POP_IX);                      // pop the address
                Emit(OpCode.PUSH_IX);                     // restore value (caller clears in CDecl)
                Emit(OpCode.PUSH_HL);                     // restore value (caller clears in CDecl)
                EmitByte(OpCode.LD_iIX_d_L,       +0);    // write the LSB
            }
            case SysCalls.MemoryWriteWord:
            {
                Emit(OpCode.POP_HL);              // pop the value
                Emit(OpCode.POP_IX);              // pop the address
                Emit(OpCode.PUSH_IX);             // restore value (caller clears in CDecl)
                Emit(OpCode.PUSH_HL);             // restore value (caller clears in CDecl)
                EmitByte(OpCode.LD_iIX_d_L, +0);  // write the LSB
                EmitByte(OpCode.LD_iIX_d_H, +1);  // write the MSB
            }
            case SysCalls.MemoryAvailable:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("MemoryAvailable"));
                referenceR0 = false;
            }
            case SysCalls.MemoryMaximum:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("MemoryMaximum"));
                referenceR0 = false;
            }
            case SysCalls.MemoryAllocate:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("MemoryAllocate"));
                referenceR0 = false;
            }
            case SysCalls.MemoryFree:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("MemoryFree"));
            }
            
            
            case SysCalls.IntGetByte:
            {
                Emit(OpCode.POP_DE);             // pop index: 0 for LSB and 1 for MSB
                Emit(OpCode.EX_iSP_HL);          // get 'int'
                Emit(OpCode.PUSH_DE);            // restore index (caller clears in CDecl)
                EmitWord(OpCode.CALL_nn, GetAddress("IntGetByte")); // 
                // return it in R0 (HL)
                referenceR0 = false;
            }
            case SysCalls.IntFromBytes:
            {
                Emit(OpCode.POP_DE);             // pop MSB
                Emit(OpCode.EX_iSP_HL);          // get LSB
                Emit(OpCode.PUSH_DE);            // restore MSB (caller clears in CDecl)
                Emit(OpCode.LD_H_E);             // set MSB and return it in R0 (HL)
                referenceR0 = false;
            }
            case SysCalls.UIntToInt:
            {
#ifdef CHECKED
                // TODO: validate that it is <= 32767 and Die(0x0D) if not
#endif       
                Emit(OpCode.POP_HL);
                Emit(OpCode.PUSH_HL);            // return it in R0 (HL)       
                referenceR0 = false;
            }
            
            case SysCalls.TimeDelay:
            {
                Emit(OpCode.EX_iSP_HL);          // load delay in ms into HL
                // TODO
                Emit(OpCode.NOP); 
            }
            case SysCalls.TimeSeconds:
            {
                // TODO: ZT0..ZT3
                if (firstSysNotImplemented)
                {
                    PrintLn("iSysCall=0x" + (byte(iSysCall)).ToHexString(2) + " not implemented");
                }
                firstSysNotImplemented = false;
                Emit(OpCode.NOP);
                referenceR0 = false;
                return false;
            }
            case SysCalls.SerialIsAvailableGet:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("SerialIsAvailable"));
                referenceR0 = false;
            }
            case SysCalls.SerialReadChar:
            {
                EmitWord(OpCode.CALL_nn, GetAddress("SerialReadChar"));
                referenceR0 = false;
            }
            case SysCalls.SerialWriteChar:
            {
                Emit      (OpCode.EX_iSP_HL);   // character to emit is in [top] (HL)
                EmitWord  (OpCode.CALL_nn, GetAddress("SerialWriteChar")); 
            }
            
            case SysCalls.ArrayNew:
            {
                EmitWord  (OpCode.CALL_nn, GetAddress("ArrayNew")); 
                referenceR0 = true;
            }
            case SysCalls.ArrayCountGet:
            {
                EmitWord  (OpCode.CALL_nn, GetAddress("ArrayGetCount")); 
                referenceR0 = false;
            }
            case SysCalls.StringNew:
            {
                EmitWord  (OpCode.CALL_nn, GetAddress("StringNew")); 
                referenceR0 = true;
            }
            case SysCalls.StringLengthGet:
            {
                EmitWord  (OpCode.CALL_nn, GetAddress("StringGetLength")); 
                referenceR0 = false;
            }
                                                         
            default:
            {
                if (firstSysNotImplemented)
                {
                    PrintLn("iSysCall=0x" + (byte(iSysCall)).ToHexString(2) + " not implemented");
                }
                firstSysNotImplemented = false;
                Emit(OpCode.NOP);
                return false;
            }
        }
        return true;
    }
    
}
