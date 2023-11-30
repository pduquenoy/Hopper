#ifndef HOPPERPLATFORM_H
#define HOPPERPLATFORM_H

#include <Arduino.h>
#include "Runtime.h"

// Machine

void Machine_Initialize();
Bool Machine_GetExited();
void Machine_SetExited(Bool value);

// lastError codes:
//   0x00 - ok
//   0x01 - list index out of range
//   0x02 - array index out of range
//   0x03 - no entry for key in dictionary
//   0x04 - division by zero attempted
//   0x05 - string index out of range
//   0x06 - call stack overflow
//   0x07 - argument stack overflow
//   0x08 - failed dynamic cast
//   0x09 - invalid variant type
//   0x0A - feature not implemented
//   0x0B - system failure (internal error)
//   0x0C - memory allocation failure
//   0x0D - numeric type out of range / overflow
//   0x0E - error returned from a failing child exe

void Error(Byte error, UInt pc);
void Error(Byte error);
void Error(Byte error, char * comment);
void Diagnostics_SetError(Byte value);


// Platform

void Platform_Release();
void Platform_Initialize();
void FileSystem_Initialize();

bool External_LoadAuto_Get();
UInt External_GetSegmentPages();
void External_WatchDog();

void External_WriteToJumpTable(UInt jumpTable, Byte opCode, InstructionDelegate instructionDelegate);
bool External_FunctionCall(UInt jumpTable, Byte opCode);

UInt External_GetMillis();
void External_Delay(UInt ms);
void External_PinMode(Byte pin, Byte value);
void External_DigitalWrite(Byte pin, Byte value);
Byte External_DigitalRead(Byte pin);

Bool Serial_IsAvailable_Get();
Char Serial_ReadChar();
void Serial_WriteChar(Char value);

Byte Memory_ReadCodeByte(UInt address);
void Memory_WriteCodeByte(UInt address, Byte value);
Byte Memory_ReadByte(UInt address);
void Memory_WriteByte(UInt address, Byte value);
UInt Memory_ReadWord(UInt address);
UInt Memory_ReadCodeWord(UInt address);
void Memory_WriteWord(UInt address, UInt value);
void Memory_WriteCodeWord(UInt address, UInt value);

UInt External_LongToFloat(UInt hrlong);
UInt External_FloatToLong(UInt hrfloat);
UInt External_FloatToUInt(UInt hrfloat);
UInt External_IntToFloat(Int i);
UInt External_UIntToFloat(UInt ui);
UInt External_FloatToString(UInt hrfloat);
Int  External_UIntToInt(UInt ui);
UInt External_IntToUInt(Int i);
Int  External_LongToInt(UInt hrlong);

bool External_FloatEQ(UInt n, UInt t);
bool External_FloatLT(UInt n, UInt t);
bool External_FloatLE(UInt n, UInt t);
bool External_FloatGE(UInt n, UInt t);
bool External_FloatGT(UInt n, UInt t);
UInt External_FloatAdd(UInt n, UInt t);
UInt External_FloatSub(UInt n, UInt t);
UInt External_FloatMul(UInt n, UInt t);
UInt External_FloatDiv(UInt n, UInt t);

bool External_LongEQ(UInt n, UInt t);
bool External_LongGT(UInt n, UInt t);
bool External_LongGE(UInt n, UInt t);
bool External_LongLT(UInt n, UInt t);
bool External_LongLE(UInt n, UInt t);
UInt External_LongAdd(UInt n, UInt t);
UInt External_LongSub(UInt n, UInt t);
UInt External_LongDiv(UInt n, UInt t);
UInt External_LongMod(UInt n, UInt t);
UInt External_LongMul(UInt n, UInt t);

void HRWire_Begin();
void HRWire_BeginTx(Byte address);
void HRWire_EndTx();
void HRWire_Write(Byte data);

#endif // HOPPERPLATFORM_H