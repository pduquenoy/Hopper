program Blink
{
//#define TINYHOPPER
#define RP2040PICO
//#define RP2040PICOW
//#define TINY2040
//#define SEEEDRP2040
//#define ARDUINONANORP2040
//#define ARDUINONANOESP32
//#define WEMOSD1MINI
//#define WAVESHARERP2040ONE
    
    uses "/Source/Library/MCU"
    
    {
        loop
        {
            LED = true;
            Write('+');
            Delay(500);
            LED = false;    
            Write('-');
            Delay(500);
        }
    }
}
