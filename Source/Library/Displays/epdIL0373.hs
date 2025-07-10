unit DisplayDriver
{
    // The Hopper version of this EPD driver is based on work from Adafruit.
    // Buy their devices!
    
    /*
     *
     * This is a library for our EPD displays based on EPD drivers.
     * Designed specifically to work with Adafruit EPD displays.
     *
     * These displays use SPI to communicate, 4 or 5 pins are required to
     * interface
     *
     * Adafruit invests time and resources providing this open source code,
     * please support Adafruit and open-source hardware by purchasing
     * products from Adafruit!
     *
     * Written by Dean Miller for Adafruit Industries.
     *
     * BSD license, all text here must be included in any redistribution.
     *
     */

    #define DISPLAY_DRIVER
    
#ifdef MINIMAL_RUNTIME
    uses "/Source/Minimal/MCU"
#else    
  #ifdef SBC_BOARD_DEFINED
    uses "/Source/Library/SBC"
  #else
    uses "/Source/Library/MCU"
  #endif
#endif

    uses "/Source/Library/Display"
    
    friend Display;
    
    const byte IL0373_PANEL_SETTING = 0x00;
    const byte IL0373_POWER_SETTING = 0x01;
    const byte IL0373_POWER_OFF = 0x02;
    const byte IL0373_POWER_OFF_SEQUENCE = 0x03;
    const byte IL0373_POWER_ON = 0x04;
    const byte IL0373_POWER_ON_MEASURE = 0x05;
    const byte IL0373_BOOSTER_SOFT_START = 0x06;
    const byte IL0373_DEEP_SLEEP = 0x07;
    const byte IL0373_DTM1 = 0x10;
    const byte IL0373_DATA_STOP = 0x11;
    const byte IL0373_DISPLAY_REFRESH = 0x12;
    const byte IL0373_DTM2 = 0x13;
    const byte IL0373_PDTM1 = 0x14;
    const byte IL0373_PDTM2 = 0x15;
    const byte IL0373_PDRF = 0x16;
    const byte IL0373_LUT1 = 0x20;
    const byte IL0373_LUTWW = 0x21;
    const byte IL0373_LUTBW = 0x22;
    const byte IL0373_LUTWB = 0x23;
    const byte IL0373_LUTBB = 0x24;
    const byte IL0373_PLL = 0x30;
    const byte IL0373_CDI = 0x50;
    const byte IL0373_RESOLUTION = 0x61;
    const byte IL0373_VCM_DC_SETTING = 0x82;
    const byte IL0373_PARTIAL_WINDOW = 0x90;
    const byte IL0373_PARTIAL_ENTER = 0x91;
    const byte IL0373_PARTIAL_EXIT = 0x92;
    
    const byte EPD_RAM_BW    = 0x10;
    const byte EPD_RAM_RED  = 0x13;

    
    bool flipX;
    bool flipY;
    bool isPortrait;
    bool FlipX { get { return flipX; } set { flipX = value; }}
    bool FlipY { get { return flipY; } set { flipY = value; }}
    bool IsPortrait { get { return isPortrait; } set { isPortrait = value; } }
    
    const uint bufferSize = DeviceDriver.pw*(DeviceDriver.ph+8)/8;
    byte [bufferSize] blackBuffer;
    byte [bufferSize] colourBuffer;
    
    const byte[] il0373DefaultInitCode =
    {
        IL0373_POWER_SETTING, 5, 0x03, 0x00, 0x2b, 0x2b, 0x09,
        IL0373_BOOSTER_SOFT_START, 3, 0x17, 0x17, 0x17,
        IL0373_POWER_ON, 0,
        0xFF, 200,
        IL0373_PANEL_SETTING, 1, 0xCF,
        IL0373_CDI, 1, 0x37,
        IL0373_PLL, 1, 0x29,    
        IL0373_VCM_DC_SETTING, 1, 0x0A,
        0xFF, 20,
        0xFE
    };

    const byte[] ti290T5Gray4InitCode =
    {
      IL0373_POWER_SETTING, 5, 0x03, 0x00, 0x2b, 0x2b, 0x13,
      IL0373_BOOSTER_SOFT_START, 3, 0x17, 0x17, 0x17,
      IL0373_POWER_ON, 0,
      0xFF, 200,
      IL0373_PANEL_SETTING, 1, 0x3F,
      IL0373_PLL, 1, 0x3C,    
      IL0373_VCM_DC_SETTING, 1, 0x12,
      IL0373_CDI, 1, 0x97,
      0xFE // EOM
    };

    const byte[] ti290T5Gray4LutCode = 
    {
      //const unsigned char lut_vcom[] =
      0x20, 42,
      0x00, 0x0A, 0x00, 0x00, 0x00, 0x01,
      0x60, 0x14, 0x14, 0x00, 0x00, 0x01,
      0x00, 0x14, 0x00, 0x00, 0x00, 0x01,
      0x00, 0x13, 0x0A, 0x01, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

      //const unsigned char lut_ww[] ={
      0x21, 42,
      0x40, 0x0A, 0x00, 0x00, 0x00, 0x01,
      0x90, 0x14, 0x14, 0x00, 0x00, 0x01,
      0x10, 0x14, 0x0A, 0x00, 0x00, 0x01,
      0xA0, 0x13, 0x01, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

      //const unsigned char lut_bw[] ={
      0x22, 42,
      0x40, 0x0A, 0x00, 0x00, 0x00, 0x01,
      0x90, 0x14, 0x14, 0x00, 0x00, 0x01,
      0x00, 0x14, 0x0A, 0x00, 0x00, 0x01,
      0x99, 0x0C, 0x01, 0x03, 0x04, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

      //const unsigned char lut_wb[] ={
      0x23, 42,
      0x40, 0x0A, 0x00, 0x00, 0x00, 0x01,
      0x90, 0x14, 0x14, 0x00, 0x00, 0x01,
      0x00, 0x14, 0x0A, 0x00, 0x00, 0x01,
      0x99, 0x0B, 0x04, 0x04, 0x01, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

      //const unsigned char lut_bb[] ={
      0x24, 42,
      0x80, 0x0A, 0x00, 0x00, 0x00, 0x01,
      0x90, 0x14, 0x14, 0x00, 0x00, 0x01,
      0x20, 0x14, 0x0A, 0x00, 0x00, 0x01,
      0x50, 0x13, 0x01, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

      0xFE // EOM
    };
    
    bool visible
    {
        set
        {
            // TODO
        }
    }
    bool inTransaction;
    
    csHigh()
    {
        MCU.DigitalWrite(DeviceDriver.csPin, true);
        if (inTransaction) 
        {
            SPI.EndTransaction(DeviceDriver.spiController);
            inTransaction = false;
        }
    }
    csLow()
    {
        if (!inTransaction)
        {
            SPI.BeginTransaction(DeviceDriver.spiController);
            inTransaction = true;
        }
        MCU.DigitalWrite(DeviceDriver.csPin, false);
    }
    dcHigh()
    {
        MCU.DigitalWrite(DeviceDriver.dcPin, true);
    }
    dcLow()
    {
        MCU.DigitalWrite(DeviceDriver.dcPin, false);
    }
    
    epdCommandList(byte [] initCode) 
    {
        byte[64] buffer;
        uint index = 0;
        while (initCode[index] != 0xFE) 
        {
            byte cmd = initCode[index];
            index++;
            byte numArgs = initCode[index];
            index++;
            if (cmd == 0xFF) 
            {
                Delay(500);
                Delay(numArgs);
                continue;
            }
            for (byte i = 0; i < numArgs; i++) 
            {
                buffer[i] = initCode[index];
                index++;
            }
            epdCommand(cmd, buffer, numArgs);
        }
    }
    
    spiTransfer(byte tx)
    {
        csLow();   
        SPI.WriteByte(DeviceDriver.spiController, tx);
        csHigh();
    }
    
    epdCommand(byte cmd, byte[] buffer, uint length)
    {
        epdCommand(cmd, false);
        epdData(buffer, length);
    }
    epdCommand(byte cmd, bool end)
    {
        csHigh();
        dcLow();
        csLow();
        spiTransfer(cmd);
        if (end) 
        {
            csHigh();
        }
    }
    epdCommand(byte cmd)
    {
        epdCommand(cmd, true);
    }    
    epdData(byte[] buffer, uint length)
    {
        dcHigh();
        for (uint i=0; i < length; i++)
        {
            spiTransfer(buffer[i]);
        }
        csHigh();
    }
    epdData(byte data) 
    {
        csHigh();
        dcHigh();
        csLow();
        spiTransfer(data);
        csHigh();
    }
    
    writeRAMCommand(byte index) 
    {
        if (index == 0) 
        {
            epdCommand(EPD_RAM_BW,  false);
        }
        if (index == 1) 
        {
            epdCommand(EPD_RAM_RED, false);
        }
    }
    
    update()
    {
        powerUp();
        
        writeRAMCommand(0);
        dcHigh();
        csLow();   
        SPI.WriteBuffer(DeviceDriver.spiController, blackBuffer, 0, bufferSize);
        csHigh();
        
        Delay(2);
        
        writeRAMCommand(1);
        dcHigh();
        csLow();   
        SPI.WriteBuffer(DeviceDriver.spiController, colourBuffer, 0, bufferSize);
        csHigh();
        
        epdCommand(IL0373_DISPLAY_REFRESH);
        Delay(100);
        Delay(100);
        DelaySeconds(DeviceDriver.defaultRefreshDelay);
        
        powerDown();
    }
    
    powerUp() 
    {
        byte[4] buf;
#ifdef EPD_GRAY
        byte[] initCode = ti290T5Gray4InitCode;
#else
        byte[] initCode = il0373DefaultInitCode;
#endif        
        epdCommandList(initCode);
#ifdef EPD_GRAY        
        byte [] lutInitCode = ti290T5Gray4LutCode;
        epdCommandList(lutInitCode);
#endif        
        buf[0] = byte(DeviceDriver.ph & 0xFF);
        buf[1] = byte((uint(DeviceDriver.pw) >> 8) & 0xFF);
        buf[2] = byte(uint(DeviceDriver.pw) & 0xFF);
        epdCommand(IL0373_RESOLUTION, buf, 3);
    }
    
    PowerDown()
    {
        powerDown();
    }
    
    powerDown()
    {
        byte[4] buf;
        buf[0] = 0x17;
        epdCommand(IL0373_CDI, buf, 1);
        buf[0] = 0x00;
        epdCommand(IL0373_VCM_DC_SETTING, buf, 0);
        epdCommand(IL0373_POWER_OFF);
    }
    
    bool begin()
    {
        bool success = false;
        loop
        {
            if (DisplayDriver.IsPortrait)
            {
                Display.PixelWidth  = Int.Min(DeviceDriver.pw, DeviceDriver.ph);
                Display.PixelHeight = Int.Max(DeviceDriver.pw, DeviceDriver.ph);
            }
            else
            {
                Display.PixelWidth  = Int.Max(DeviceDriver.pw, DeviceDriver.ph);
                Display.PixelHeight = Int.Min(DeviceDriver.pw, DeviceDriver.ph);
            }
            
            Screen.ForeColour = Colour.Black;
            Screen.BackColour = Colour.White;
            
            MCU.PinMode(DeviceDriver.csPin, PinModeOption.Output);
            MCU.PinMode(DeviceDriver.dcPin, PinModeOption.Output);
            MCU.DigitalWrite(DeviceDriver.csPin, true);
            
            SPI.SetClkPin(DeviceDriver.spiController, DeviceDriver.clkPin);
            SPI.SetTxPin (DeviceDriver.spiController, DeviceDriver.txPin);
#if !defined(EPD_NO_RX)
            SPI.SetRxPin (DeviceDriver.spiController, DeviceDriver.rxPin);
#endif
            //SPI.Settings(DeviceDriver.spiController, 4000000, DataOrder.MSBFirst, DataMode.Mode0);// these are the defaults
            if (!SPI.Begin(DeviceDriver.spiController))
            {
                IO.WriteLn("DisplayDriver.Begin failed in SPI.Begin");
                return false;
            }
            powerDown();
            success = true;
            break;
        }
        return success;
    }
    scrollUp(uint lines)
    {
        /*
        uint drow;
        for (uint row = lines; row < int(Display.PixelHeight); row++)
        {
            for (int x = 0; x < int(Display.PixelWidth-1); x++)
            {
                setPixel(x, int(drow), getPixel(x, int(row)));
            }
            drow++;    
        }
        loop
        {
            if (drow >= int(Display.PixelHeight)) { break; }
            for (int x = 0; x < int(Display.PixelWidth-1); x++)
            {
                setPixel(x, int(drow), Colour.White);
            }
            drow++;   
        }
        */    
    }
    bool colourToBit0(uint colour)
    {
        bool bit0;
        switch (colour)
        {
            case 0x0000: { bit0 = DeviceDriver.epdBlack0; }
            case 0x0666: { bit0 = DeviceDriver.epdDark0;  }
            case 0x0CCC: { bit0 = DeviceDriver.epdLight0; }
            case 0x0F00: { bit0 = DeviceDriver.epdRed0;   }
            default:     { bit0 = DeviceDriver.epdWhite0; }
        }
        return bit0;
    }
    bool colourToBit1(uint colour)
    {
        bool bit1;
        switch (colour)
        {
            case 0x0000: { bit1 = DeviceDriver.epdBlack1; }
            case 0x0666: { bit1 = DeviceDriver.epdDark1;  }
            case 0x0CCC: { bit1 = DeviceDriver.epdLight1; }
            case 0x0F00: { bit1 = DeviceDriver.epdRed1;   }
            default:     { bit1 = DeviceDriver.epdWhite1; }
        }
        return bit1;
    }
    clear(uint colour)
    {
        bool bit0 = colourToBit0(colour);
        for (uint i = 0; i < bufferSize; i++)
        {
            blackBuffer[i] = bit0 ? 0x00 : 0xFF;
        }
        bool bit1 = colourToBit1(colour);
        for (uint i = 0; i < bufferSize; i++)
        {
            colourBuffer[i] = bit1 ? 0x00 : 0xFF;
        }
        int wtf = 0;     
    } 
    setPixel(int vx, int vy, uint colour)
    {
        if (FlipX)
        {
            vx = (Display.PixelWidth-1) - vx;
        }
        if (FlipY)
        {
            vy = (Display.PixelHeight-1) - vy;
        }
        int x = vx;
        int y = vy;
        if (IsPortrait)
        {
            x = vy;
            y = vx;
        }
        // deal with non-8-bit heights
        uint address = ((uint(DeviceDriver.pw) - 1 - uint(x)) * uint(DeviceDriver.ph) + uint(y)) / 8;
        
        bool bit0 = colourToBit0(colour);
        if (bit0) 
        {
            blackBuffer[address] = blackBuffer[address] & ~(1 << (7 - y % 8));
        } 
        else 
        {
            blackBuffer[address] = blackBuffer[address] | (1 << (7 - y % 8));
        }
        bool bit1 = colourToBit1(colour);
        if (bit1) 
        {
            colourBuffer[address] = colourBuffer[address] & ~(1 << (7 - y % 8));
        }
        else 
        {
            colourBuffer[address] = colourBuffer[address] | (1 << (7 - y % 8));
        }
        
    }  
    horizontalLine(int x1, int y, int x2, uint colour)
    {
        for (int x = x1; x <= x2; x++)
        {
            setPixel(x, y, colour);
        }
    }
    verticalLine(int x, int y1, int y2, uint colour)
    {
        for (int y = y1; y <= y2; y++)
        {
            setPixel(x, y, colour);
        }
    }
}
