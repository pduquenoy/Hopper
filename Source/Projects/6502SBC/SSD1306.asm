unit SSD1306
{    
    uses "I2C.asm"
    
    const byte[] ssd1306InitTable = {
                                0xAE,   // Turn off display
                                0xD5,   // set display clock divider
                                0xF0,   // 0x80 default - $f0 is faster for less tearing
                                0xA8,   // set multiplex
                                0x3F,   // for 128x64
                                0x40,   // Startline 0
                                0x8D,   // Charge pump
                                0x14,   // VCCstate 14
                                0xA1,   // Segment remap
                                0xC8,   // Com output scan direction
                                0x20,   // Memory mode
                                0x00,   //
                                0xDA,   // Com-pins
                                0x12,
                                0xFE,   // Set contrast - full power!
                                0x7F,   // About half
                                0xD9,   // Set precharge
                                0x11,   // VCC state 11
                                0xA4,   // Display all on resume
                                0xAF,   // Display on
                                //0xA5,   // Entire display ON  A5 Enable / A4 Disable 
                                0xB0, 0x10, 0x00, // Page 0, column 0.
                                0xFF // Stop byte
                              };
                              
    cmd()
    {
        // takes command in A
        PHA // save command
        LDA # 0x3C // SSD1306 address
        STA ZP.I2CADDR
        CLC // write flag
        I2C.Start();
        LDA # 0x00 // // 0x00 for commands or 0x40 for data
        STA ZP.OutB
        I2C.ByteOut();
        PLA // restore command
        STA ZP.OutB
        I2C.ByteOut();
    }
    Initialize()
    {
        CLC            // Write flag
        I2C.Start();
        LDY # 0

        loop
        {
            LDA ssd1306InitTable, Y
            CMP # 0xFF                // stop byte
            if (Z) { break; }
            STA ZP.OutB
            I2C.ByteOut();
            INY
        }
        I2C.Stop();
    }
    
    SetColumn()
    {
        ASL // 15 >> >> >> 120
        ASL
        ASL
        PHA
        LDA #0x21 // Set column command (0-127)
        cmd();
        PLA
        STA ZP.OutB
        I2C.ByteOut();
        LDA # 0x7F // 127
        STA ZP.OutB
        I2C.ByteOut();
        I2C.Stop();
    }
    SetLine()
    {
        // Takes line(page) in A
        PHA // save line
        LDA #0x22 // Set page cmd
        cmd();
        PLA // restore line
        STA ZP.OutB
        I2C.ByteOut();
        LDA #7 // ensure range
        STA ZP.OutB
        I2C.ByteOut();
        I2C.Stop(); 
    }
    
    Clear()
    {
        LDA # 0
        STA ZP.Cursor
        STA ZP.TFlags  // reset scroll
        SetLine();
        LDA # 0
        SetColumn();
        CLC             // write flag
        I2C.Start();
        LDA # 0x40      // 0x00 for commands or 0x40 for data
        STA ZP.OutB
        I2C.ByteOut();

        LDY # 0
        loop
        {
            LDA ZP.TOPL
            STA ZP.OutB
            I2C.ByteOut();
            
            LDA ZP.TOPL
            STA ZP.OutB
            I2C.ByteOut();
            
            LDA ZP.TOPL
            STA ZP.OutB
            I2C.ByteOut();
            
            LDA ZP.TOPL
            STA ZP.OutB
            I2C.ByteOut();
            DEY
            if (Z) { break; }
        }
        I2C.Stop();
        
        LDA # 0xD3 // Clear scroll
        cmd();
        LDA # 0
        STA ZP.Scroll
        STA ZP.OutB
        I2C.ByteOut();
        I2C.Stop();
    }
}
