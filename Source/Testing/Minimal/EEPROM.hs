program EEPROM
{
    //#define MCU
    uses "/Source/Minimal/System"
    uses "/Source/Minimal/MCU"
    
    const byte i2cEEPROMaddress = 0x50;
    Hopper()
    {
        _ = Wire.Initialize();
        for (byte i2cAddress = 8; i2cAddress < 120; i2cAddress++)
        {
            Wire.BeginTx(i2cAddress);
            if (0 == Wire.EndTx())
            {
                WriteLn(i2cAddress.ToHexString(2) + " exists");
            }
        }
        
        
        uint now = Time.Seconds;  // time stamp to be sure our write is working
        string writeStr = "Hello Serial EEPROM! (at " + now.ToString() + "s)";
        uint startAddress = 4242; // arbitrary address on the EEPROM
        
        IO.WriteLn("Now: " + now.ToString() + "s");
        IO.Write("Writing: '");
        for (uint i = 0; i < writeStr.Length; i++)
        {
            uint address = startAddress + i;
            Wire.BeginTx(i2cEEPROMaddress);
            Wire.Write(byte(address >> 8));
            Wire.Write(byte(address & 0xFF));
            Wire.Write(byte(writeStr[i]));
            _ = Wire.EndTx();
            // 5ms delay for EEPROM write (4ms worked but let's not push our luck)
            Time.Delay(5); 
            IO.Write(writeStr[i]);
        }
        IO.WriteLn("'");
        IO.Write("Reading: '");
        string readStr;
        
        Wire.BeginTx(i2cEEPROMaddress);
        Wire.Write(byte(startAddress >> 8)); 
        Wire.Write(byte(startAddress & 0xFF));
        _ = Wire.EndTx();
        uint bytes = Wire.RequestFrom(i2cEEPROMaddress, byte(writeStr.Length));
        for (uint i = 0; i < writeStr.Length; i++)
        {
            readStr += char(Wire.Read());
        }
        IO.WriteLn(readStr + "'");
        WriteLn("Bytes: " + bytes.ToString());
    }
}