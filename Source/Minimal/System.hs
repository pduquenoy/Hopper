unit System
{
    #define MINIMAL_RUNTIME
#ifdef CPU_Z80
    #define NO_JIX_INSTRUCTIONS
#endif
    //#define NO_PACKED_INSTRUCTIONS
    
    uses "Char"
    uses "Bool"
    uses "Byte"
    uses "Int"
    uses "UInt"
    uses "Time"
    uses "String"
    uses "Array"
    uses "Type"
    
    uses "Long"
    uses "Float"
    uses "List"
    
    uses "Serial"
    uses "Diagnostics"
}
