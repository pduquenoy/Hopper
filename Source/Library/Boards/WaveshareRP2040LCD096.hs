unit Board // Waveshare RP2040 LCD 0.96
{
    #define WAVESHARE_RP2040_LCD_096

    #define MCU_BOARD_DEFINED
    #define MCU_BOARD_RP2040

    #define BOARD_HAS_I2C
    #define BOARD_HAS_SPI
    #define BOARD_HAS_A0
    #define BOARD_HAS_A1
    #define BOARD_HAS_A2
    #define BOARD_HAS_A3

    const byte BuiltInA0 = 26;
    const byte BuiltInA1 = 27;
    const byte BuiltInA2 = 28;
    const byte BuiltInA3 = 29;
    const byte ADCResolution = 12;

    const byte I2CSDA0 = 8;
    const byte I2CSCL0 = 9;
    const byte I2CSDA1 = 6;
    const byte I2CSCL1 = 7;

    const byte SPI0Tx = 19;
    const byte SPI0Rx = 16;
    const byte SPI0SCK = 18;
    const byte SPI0SS = 17;
    const byte SPI1Tx = 15;
    const byte SPI1Rx = 12;
    const byte SPI1SCK = 14;
    const byte SPI1SS = 13;

    const byte UART1Tx = 0;
    const byte UART1Rx = 1;
    const byte UART2Tx = 8;
    const byte UART2Rx = 9;


    uses "/Source/Library/MCU"

    string BoardName { get { return "Waveshare RP2040 LCD 0.96"; } }

}
