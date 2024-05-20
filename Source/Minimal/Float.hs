unit Float
{
    uses "Diagnostics" // for Die
    uses "Int"         // for Int.ToString
    uses "Long"        // so we can use Long for the 23 bit mantissa
    
    friend UInt;       // so UInt.ToFloat can access Float.normalize and Float.combineComponents
    friend  Int;       // so Int.ToFloat  can access Float.normalize and Float.combineComponents
    friend Long;       // so Long.ToFloat can access Float.normalize and Float.combineComponents
    
    byte GetByte(float this, byte index) system;
    float FromBytes(byte b0, byte b1, byte b2, byte b3) system;
    const float Pi = 3.1415926535;
    
    float Add(float a, float b)
    {
        byte signA     = getSign(a);
        int exponentA  = getExponent(a);  // Change to int for processing
        long mantissaA = getMantissa(a);
    
        byte signB     = getSign(b);
        int exponentB  = getExponent(b);  // Change to int for processing
        long mantissaB = getMantissa(b);
    
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
    
        // Align exponents
        if (exponentA > exponentB)
        {
            int shift = exponentA - exponentB;
            mantissaB = Long.shiftRight(mantissaB, shift);
            exponentB = exponentA;
        }
        else if (exponentA < exponentB)
        {
            int shift = exponentB - exponentA;
            mantissaA = Long.shiftRight(mantissaA, shift);
            exponentA = exponentB;
        }
    
        long resultMantissa;
        if (signA == signB)
        {
            resultMantissa = Long.Add(mantissaA, mantissaB); // Same sign: addition
        }
        else
        {
            if (Long.GE(mantissaA, mantissaB))
            {
                resultMantissa = Long.Sub(mantissaA, mantissaB); // Different signs: subtraction
            }
            else
            {
                resultMantissa = Long.Sub(mantissaB, mantissaA);
                signA = signB;
            }
        }
    
        if (Long.GE(resultMantissa, Long.FromBytes(0, 0, 0x01, 0))) // 0x01000000 in 32-bit
        {
            resultMantissa = Long.shiftRight(resultMantissa, 1);
            exponentA++;
        }
        else
        {
            normalize(ref resultMantissa, ref exponentA); // Pass exponent as int for normalization
        }
    
        return combineComponents(signA, byte(exponentA), resultMantissa); // Convert exponent back to byte for combining
    }
    
    float Sub(float a, float b)
    {
        byte signB = getSign(b);
        signB = signB ^ 1; // Flip the sign of b
        float negativeB = combineComponents(signB, getExponent(b), getMantissa(b));
        return Add(a, negativeB);
    }
    
    float Mul(float a, float b)
    {
        byte signA = getSign(a);
        byte exponentA = getExponent(a);
        long mantissaA = getMantissa(a);
        byte signB = getSign(b);
        byte exponentB = getExponent(b);
        long mantissaB = getMantissa(b);
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        long resultMantissa = Long.shiftRight(Long.Mul(mantissaA, mantissaB), 23); // Multiply mantissas
        int resultExponent = int(exponentA) + int(exponentB) - 127; // Add exponents
        byte resultSign = signA ^ signB; // Determine the sign
        if (Long.GE(resultMantissa, Long.FromBytes(0, 0, 0x01, 0))) // 0x01000000 in 32-bit
        {
            resultMantissa = Long.shiftRight(resultMantissa, 1);
            resultExponent++;
        }
        else
        {
            normalize(ref resultMantissa, ref resultExponent);
        }
        return combineComponents(resultSign, byte(resultExponent), resultMantissa);
    }
    
    float Div(float a, float b)
    {
        byte signA = getSign(a);
        byte exponentA = getExponent(a);
        long mantissaA = getMantissa(a);
        byte signB = getSign(b);
        byte exponentB = getExponent(b);
        long mantissaB = getMantissa(b);
        // Add the implicit leading bit
        mantissaA = Long.or(mantissaA, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        mantissaB = Long.or(mantissaB, Long.FromBytes(0, 0, 0x80, 0)); // 0x00800000 in 32-bit
        long zero = Long.FromBytes(0, 0, 0, 0);
        if (Long.EQ(mantissaB, zero))
        {
            Die(0x04); // Division by zero
        }
        long resultMantissa = Long.shiftRight(Long.Div(Long.shiftLeft(mantissaA, 23), mantissaB), 0); // Divide mantissas
        int resultExponent = int(exponentA) - int(exponentB) + 127; // Subtract exponents
        byte resultSign = signA ^ signB; // Determine the sign
        if (Long.GE(resultMantissa, Long.FromBytes(0, 0, 0x01, 0))) // 0x01000000 in 32-bit
        {
            resultMantissa = Long.shiftRight(resultMantissa, 1);
            resultExponent++;
        }
        else
        {
            normalize(ref resultMantissa, ref resultExponent);
        }
        return combineComponents(resultSign, byte(resultExponent), resultMantissa);
    }
    
    bool EQ(float a, float b)
    {
        return (GetByte(a, 0) == GetByte(b, 0)) &&
               (GetByte(a, 1) == GetByte(b, 1)) &&
               (GetByte(a, 2) == GetByte(b, 2)) &&
               (GetByte(a, 3) == GetByte(b, 3));
    }
    
    bool LT(float a, float b)
    {
        byte signA = getSign(a);
        byte signB = getSign(b);
        if (signA != signB)
        {
            return signA > signB;
        }
        byte exponentA = getExponent(a);
        byte exponentB = getExponent(b);
        if (exponentA != exponentB)
        {
            return (signA == 0) ? (exponentA < exponentB) : (exponentA > exponentB);
        }
        long mantissaA = getMantissa(a);
        long mantissaB = getMantissa(b);
        return (signA == 0) ? (mantissaA < mantissaB) : (mantissaA > mantissaB);
    }
    
    bool GT(float a, float b)
    {
        return !LE(a, b);
    }
    
    bool LE(float a, float b)
    {
        return LT(a, b) || EQ(a, b);
    }
    
    bool GE(float a, float b)
    {
        return GT(a, b) || EQ(a, b);
    }
    
    string ToString(float value)
    {
        float zero = Float.FromBytes(0, 0, 0, 0);
        if (Float.EQ(value, zero))
        {
            return "0";
        }
        bool isNegative = getSign(value) == 1;
        if (isNegative)
        {
            value = negate(value);
        }
        int integerPart = value.ToInt();
        float fractionalPart = Float.Sub(value, integerPart.ToFloat());
        string integerPartStr = integerPart.ToString();
        string fractionalPartStr = fractionToString(fractionalPart);
        string result = integerPartStr + "." + fractionalPartStr;
        if (isNegative)
        {
            result = "-" + result;
        }
        return result;
    }
    
    int ToInt(float f)
    {
        byte sign = getSign(f);
        int exponent = getExponent(f) - 127; // Bias adjustment
        long mantissa = getMantissa(f);
        mantissa = Long.or(mantissa, Long.FromBytes(0, 0, 0x80, 0)); // Add the implicit leading bit
    
        int result;
        if (exponent > 23)
        {
            result = int(Long.shiftLeft(mantissa, exponent - 23));
        }
        else if (exponent < 23)
        {
            result = int(Long.shiftRight(mantissa, 23 - exponent));
        }
        else
        {
            result = int(mantissa);
        }
    
        return sign == 1 ? -result : result;
    }
    
    uint ToUInt(float f)
    {
        int intValue = f.ToInt();
        if (intValue < 0)
        {
            Die(0x0D); // Overflow
        }
        return uint(intValue);
    }
    
    long ToLong(float f)
    {
        byte sign = getSign(f);
        byte exponent = getExponent(f);
        long mantissa = getMantissa(f);
        long result = Long.shiftRight(mantissa, 8);
        int shift = exponent - 127 - 23;
        if (shift > 0)
        {
            result = Long.shiftLeft(result, shift);
        }
        else if (shift < 0)
        {
            result = Long.shiftRight(result, -shift);
        }
        return sign == 1 ? -result : result;
    }
    
    byte getSign(float f)
    {
        return (GetByte(f, 3) >> 7) & 1;
    }
    
    byte getExponent(float f)
    {
        return (GetByte(f, 3) & 0x7F) << 1 | (GetByte(f, 2) >> 7);
    }
    
    long getMantissa(float f)
    {
        return Long.FromBytes(GetByte(f, 0), GetByte(f, 1), GetByte(f, 2) & 0x7F, 0);
    }
    
    float combineComponents(byte sign, byte exponent, long mantissa)
    {
        // Extract bytes from mantissa
        byte b0 = Long.GetByte(mantissa, 0);
        byte b1 = Long.GetByte(mantissa, 1);
        byte b2 = Long.GetByte(mantissa, 2) & 0x7F; // Only take the 7 least significant bits
        b2 |= byte((exponent & 1) << 7); // Set the least significant bit of the exponent in b2
    
        byte b3 = byte((exponent >> 1) & 0x7F); // Take the next 7 bits of the exponent
        b3 |= byte(sign << 7); // Set the sign bit in b3
    
        return FromBytes(b0, b1, b2, b3);
    }
    
    
    normalize(ref long mantissa, ref int exponent)
    {
        long implicitLeadingBit = Long.FromBytes(0, 0, 0x80, 0); // 0x00800000 in 32-bit
        long mask = Long.FromBytes(0xFF, 0xFF, 0x7F, 0x00); // 0x007FFFFF in 32-bit
        long zero = Long.FromBytes(0, 0, 0, 0);
    
        while (Long.EQ(Long.and(mantissa, implicitLeadingBit), zero))
        {
            mantissa = Long.shiftLeft(mantissa, 1);
            exponent--;
        }
        // No need to mask the mantissa as it is already normalized correctly
        int wtf = 0;
    }
       
    string IntToString(int value)
    {
        string result = "";
        bool isNegative = false;
        if (value == 0)
        {
            return "0";
        }
        if (value < 0)
        {
            isNegative = true;
            value = -value;
        }
        while (value > 0)
        {
            int digit = value % 10;
            result = (char)('0' + digit) + result;
            value /= 10;
        }
        if (isNegative)
        {
            result = "-" + result;
        }
        return result;
    }
    
    string fractionToString(float fractionalPart)
    {
        string result = "";
        int precision = 6; // Number of digits after the decimal point
        while (precision > 0)
        {
            fractionalPart = Mul(fractionalPart, Int.ToFloat(10));
            int digit = fractionalPart.ToInt();
            result += char(byte('0') + digit);
            fractionalPart = Sub(fractionalPart, Int.ToFloat(digit));
            precision--;
        }
        return result;
    }
    
    float negate(float value)
    {
        byte sign = getSign(value) ^ 1;
        byte exponent = getExponent(value);
        long mantissa = getMantissa(value);
        return combineComponents(sign, exponent, mantissa);
    }
    
    /*
    <byte> ToBytes(float this)
    {
        <byte> bytes;
        bytes.Append(this.GetByte(0));
        bytes.Append(this.GetByte(1));
        bytes.Append(this.GetByte(2));
        bytes.Append(this.GetByte(3));
        return bytes;
    }
    */
}
