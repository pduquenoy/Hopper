program Pico433Tx
{
    //uses "/Source/Library/Boards/PiPicoW"
    //uses "/Source/Library/Boards/ChallengerNB2040WiFi"    
    uses "/Source/Library/Boards/PimoroniTiny2350"
    
    const byte ledPin = GP5;
    const byte ledPinBack = GP6;
    
    Hopper()
    {
#if defined(PIMORONI_TINY2040) || defined(PIMORONI_TINY2350)
        // 'true' is on for Pimoroni Tiny: turn off RGB LED left on by startup
        LEDR = false;
        LEDG = false;
        LEDB = false;
#endif
        
        PinMode(ledPin, PinModeOption.Output);
        PinMode(ledPinBack, PinModeOption.Output);
        
        UART.Setup(9600);
        
        //uint loops;
        
        loop // transmission loop
        {
            string time = (Millis).ToString();
            DigitalWrite(ledPin, true);
            IO.Write("Sent: " + time);
            UART.WriteString(time + Char.EOL);
            Delay(250);
            DigitalWrite(ledPin, false);
            Delay(50);
            if (UART.IsAvailable)
            {
                string returned;
                DigitalWrite(ledPinBack, true);
                loop // reception loop
                {
                   if (!UART.IsAvailable)
                   {
                       returned = "";
                       break;
                   }
                   char ch = UART.ReadChar();
                   if (ch == Char.EOL)
                   {
                       // finish reception on Char.EOL
                       IO.Write(", " + returned);
                       returned = "";
                       break;
                   }
                   returned += ch;
                } // reception loop
                Delay(250);
                DigitalWrite(ledPinBack, false);
            }
            else
            {
                Delay(250);
            }
            Delay(450);
            
            IO.WriteLn();
            /*
            loops++;
            if (loops > 20)
            {
                IO.WriteLn("Restarting..");
                Delay(100);
                MCU.Reboot(false);
            }
            */
        } // transmission loop
    }
}
