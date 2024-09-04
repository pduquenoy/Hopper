unit Board // Adafruit Feather
{
    #define ADAFRUIT_FEATHER

    #define MCU_BOARD_DEFINED
    #define MCU_BOARD_RP
    #define FORMFACTOR_FEATHER

    // https://learn.adafruit.com/adafruit-feather-rp2040-pico/pinouts

    #define BOARD_HAS_NEOPIXEL
    #define BOARD_HAS_LED
    #define BOARD_I2C1_IS_DEFAULT
    #define BOARD_HAS_I2C
    #define BOARD_HAS_NO_SPI1
    #define BOARD_HAS_SPI
    #define BOARD_HAS_A0
    #define BOARD_HAS_A1
    #define BOARD_HAS_A2
    #define BOARD_HAS_A3

    const byte BuiltInLED = 13;
    const byte BuiltInNeoPixel = 16;
    const byte BuiltInNeoPixelLength = 1;

    const byte BuiltInA0 = 26;
    const byte BuiltInA1 = 27;
    const byte BuiltInA2 = 28;
    const byte BuiltInA3 = 29;
    const byte ADCResolution = 12;

    const byte I2CSDA0 = 24;
    const byte I2CSCL0 = 25;
    const byte I2CSDA1 = 2;
    const byte I2CSCL1 = 3;

    const byte SPI0Tx = 19;
    const byte SPI0Rx = 20;
    const byte SPI0SCK = 18;
    const byte SPI0SS = 17;

    const byte UART1Tx = 0;
    const byte UART1Rx = 1;

    const byte GP0 = 0;   // UART1Tx
    const byte GP1 = 1;   // UART1Rx
    const byte GP2 = 2;   // I2CSDA1 (STEMMA)
    const byte GP3 = 3;   // I2CSCL1 (STEMMA)
    const byte GP6 = 6;
    const byte GP7 = 7;
    const byte GP8 = 8;
    const byte GP9 = 9;
    const byte GP10 = 10;
    const byte GP11 = 11;
    const byte GP12 = 12;
    const byte GP13 = 13; // BuiltInLED
    const byte GP16 = 16; // BuiltInNeoPixel
    const byte GP18 = 18; // SPI0SCK
    const byte GP19 = 19; // SPI0Tx
    const byte GP20 = 20; // SPI0Rx
    const byte GP24 = 24; // I2CSDA0
    const byte GP25 = 25; // I2CSCL0
    const byte GP26 = 26; // BuiltInA0
    const byte GP27 = 27; // BuiltInA1
    const byte GP28 = 28; // BuiltInA2
    const byte GP29 = 29; // BuiltInA3

    uses "/Source/Library/MCU"

    string BoardName { get { return "Adafruit Feather"; } }

}
