unit Long
{
    uses "Float"
    
    friend Float, Int, UInt;
    
    byte GetByte(long this, byte index) system;
    long FromBytes(byte b0, byte b1, byte b2, byte b3) system;
        
    long Add(long a, long b)
    {
        // Extract bytes from both longs
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);
    
        byte b0 = GetByte(b, 0);
        byte b1 = GetByte(b, 1);
        byte b2 = GetByte(b, 2);
        byte b3 = GetByte(b, 3);
    
        // Perform addition byte-by-byte with carry
        byte result0;
        byte result1;
        byte result2;
        byte result3;
    
        uint carry = 0;
    
        // Add the lowest byte with carry
        uint temp = uint(a0) + uint(b0) + carry;
        result0 = byte(temp & 0xFF);
        carry = (temp > 0xFF) ? 1 : 0;
    
        // Add the second byte with carry
        temp = uint(a1) + uint(b1) + carry;
        result1 = byte(temp & 0xFF);
        carry = (temp > 0xFF) ? 1 : 0;
    
        // Add the third byte with carry
        temp = uint(a2) + uint(b2) + carry;
        result2 = byte(temp & 0xFF);
        carry = (temp > 0xFF) ? 1 : 0;
    
        // Add the highest byte with carry
        temp = uint(a3) + uint(b3) + carry;
        result3 = byte(temp & 0xFF);
        carry = (temp > 0xFF) ? 1 : 0;
    
        // Create new long from result bytes
        return FromBytes(result0, result1, result2, result3);
    }
        
        
    long Sub(long a, long b)
    {
        // Extract bytes from both longs
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);
    
        byte b0 = GetByte(b, 0);
        byte b1 = GetByte(b, 1);
        byte b2 = GetByte(b, 2);
        byte b3 = GetByte(b, 3);
    
        // Perform subtraction byte-by-byte with borrow
        byte result0;
        byte result1;
        byte result2;
        byte result3;
    
        uint borrow = 0;
    
        // Subtract the lowest byte with borrow
        uint temp = uint(a0) - uint(b0) - borrow;
        result0 = byte(temp & 0xFF);
        borrow = (temp > 0xFF) ? 1 : 0;
    
        // Subtract the second byte with borrow
        temp = uint(a1) - uint(b1) - borrow;
        result1 = byte(temp & 0xFF);
        borrow = (temp > 0xFF) ? 1 : 0;
    
        // Subtract the third byte with borrow
        temp = uint(a2) - uint(b2) - borrow;
        result2 = byte(temp & 0xFF);
        borrow = (temp > 0xFF) ? 1 : 0;
    
        // Subtract the highest byte with borrow
        temp = uint(a3) - uint(b3) - borrow;
        result3 = byte(temp & 0xFF);
        borrow = (temp > 0xFF) ? 1 : 0;
    
        // Create new long from result bytes
        return FromBytes(result0, result1, result2, result3);
    }
        
     
    long Mul(long a, long b)
    {
        // Determine the signs of the operands
        bool isNegativeA = (GetByte(a, 3) & 0x80) != 0;
        bool isNegativeB = (GetByte(b, 3) & 0x80) != 0;
    
        // If the values are negative, convert them to positive equivalents
        if (isNegativeA)
        {
            a = Negate(a);
        }
        if (isNegativeB)
        {
            b = Negate(b);
        }
        
        // Extract bytes from both longs
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);
    
        byte b0 = GetByte(b, 0);
        byte b1 = GetByte(b, 1);
        byte b2 = GetByte(b, 2);
        byte b3 = GetByte(b, 3);
    
        // Perform multiplication using 8-bit parts and cast results to long
        long result0 = long(uint(a0) * uint(b0));
        long result1 = long(uint(a0) * uint(b1)) + long(uint(a1) * uint(b0));
        long result2 = long(uint(a0) * uint(b2)) + long(uint(a1) * uint(b1)) + long(uint(a2) * uint(b0));
        long result3 = long(uint(a0) * uint(b3)) + long(uint(a1) * uint(b2)) + long(uint(a2) * uint(b1)) + long(uint(a3) * uint(b0));
        long result4 = long(uint(a1) * uint(b3)) + long(uint(a2) * uint(b2)) + long(uint(a3) * uint(b1));
        long result5 = long(uint(a2) * uint(b3)) + long(uint(a3) * uint(b2));
        long result6 = long(uint(a3) * uint(b3));
    
        // Combine results carefully to form the final 32-bit result
        long finalResult = Long.FromBytes(
            result0.GetByte(0),
            result1.GetByte(0) + result0.GetByte(1),
            result2.GetByte(0) + result1.GetByte(1),
            result3.GetByte(0) + result2.GetByte(1)
        );
    
        finalResult = Long.Add(finalResult, Long.shiftLeft(Long.FromBytes(
            result3.GetByte(2),
            result4.GetByte(1) + result3.GetByte(3),
            result5.GetByte(1) + result4.GetByte(2),
            result5.GetByte(3)
        ), 16));
    
        finalResult = Long.Add(finalResult, Long.shiftLeft(Long.FromBytes(
            result6.GetByte(1),
            result6.GetByte(2),
            result6.GetByte(3),
            0
        ), 24));
        
        if ((isNegativeA || isNegativeB) && (isNegativeA != isNegativeB))
        {
            finalResult = Negate(finalResult);
        }
        return finalResult;
    }
    
    
    long divMod(long dividend, long divisor, ref long remainder)
    {
        long zero = FromBytes(0, 0, 0, 0);

        if (EQ(divisor, zero))
        {
            Die(0x04); // division by zero attempted
        }
        
        // Determine the signs of the operands
        bool isNegativeA = (GetByte(dividend, 3) & 0x80) != 0;
        bool isNegativeB = (GetByte(divisor, 3) & 0x80) != 0;
    
        // If the values are negative, convert them to positive equivalents
        if (isNegativeA)
        {
            dividend = Negate(dividend);
        }
        if (isNegativeB)
        {
            divisor = Negate(divisor);
        }

        long one = FromBytes(1, 0, 0, 0);
        long quotient = zero;
        remainder = zero;

        for (int i = 31; i >= 0; i--)
        {
            // Shift the remainder left by 1 and bring down the next bit of the dividend
            remainder = remainder.shiftLeft(1);
            remainder = remainder.or((dividend.shiftRight(i)).and(one));

            // If the remainder is greater than or equal to the divisor
            if (GE(remainder, divisor))
            {
                remainder = remainder.Sub(divisor);
                quotient = quotient.or(one.shiftLeft(i));
            }
        }
        if ((isNegativeA || isNegativeB) && (isNegativeA != isNegativeB))
        {
            quotient = Negate(quotient);
        }
        return quotient;
    }

    long Div(long dividend, long divisor)
    {
        long remainder = 0;
        return divMod(dividend, divisor, ref remainder);
    }

    long Mod(long dividend, long divisor)
    {
        long remainder = 0;
        _ = divMod(dividend, divisor, ref remainder);
        return remainder;
    }

    bool EQ(long left, long right)
    {
        for (byte i = 0; i < 4; i++)
        {
            if (GetByte(left, i) != GetByte(right, i))
            {
                return false;
            }
        }
        return true;
    }

    bool GT(long left, long right)
    {
        byte leftSignByte = GetByte(left, 3);
        byte rightSignByte = GetByte(right, 3);

        // Compare the sign bytes first
        if (leftSignByte > rightSignByte)
        {
            return true;
        }
        else if (leftSignByte < rightSignByte)
        {
            return false;
        }

        // If sign bytes are equal, compare the rest
        for (int i = 2; i >= 0; i--)
        {
            byte leftByte = GetByte(left, byte(i));
            byte rightByte = GetByte(right, byte(i));

            if (leftByte > rightByte)
            {
                return true;
            }
            else if (leftByte < rightByte)
            {
                return false;
            }
        }
        return false; // They are equal
    }

    bool LT(long left, long right)
    {
        return !GE(left, right);
    }

    bool GE(long left, long right)
    {
        return GT(left, right) || EQ(left, right);
    }

    bool LE(long left, long right)
    {
        return LT(left, right) || EQ(left, right);
    }

    long Abs(long value)
    {
        long zero = FromBytes(0, 0, 0, 0); // 0 as a long
        return GreaterThanOrEqual(value, zero) ? value : Negate(value);
    }

    long Negate(long value)
    {
        long zero = FromBytes(0, 0, 0, 0); // 0 as a long
        return Sub(zero, value);
    }

    long Max(long a, long b)
    {
        return GT(a, b) ? a : b;
    }

    long Min(long a, long b)
    {
        return LT(a, b) ? a : b;
    }
    
    string ToString(long value)
    {
        long zero = FromBytes(0, 0, 0, 0); // 0 as a long
        long ten = FromBytes(10, 0, 0, 0); // 10 as a long
        string result = "";

        if (EQ(value, zero))
        {
            String.BuildFront(ref result, '0');
            return result;
        }

        bool isNegative = false;
        if (LT(value, zero))
        {
            isNegative = true;
            value = Negate(value);
        }

        while (!EQ(value, zero))
        {
            long remainder = 0;
            value = divMod(value, ten, ref remainder);
            char c = char(GetByte(remainder, 0) + '0');
            String.BuildFront(ref result, c);
        }

        if (isNegative)
        {
            String.BuildFront(ref result, '-');
        }

        return result;
    }

    string ToBinaryString(long this, byte digits)
    {
        char c;
        string result = "";
        for (int i = digits - 1; i >= 0; i--)
        {
            byte currentByte = GetByte(this, i / 8);
            byte bit = (currentByte >> (i % 8)) & 1;
            c = (bit == 1) ? '1' : '0';
            String.BuildFront(ref result, c);
        }
        return result;
    }

    string ToHexString(long this, byte digits)
    {
        char c;
        string result = "";
        for (byte i = 0; i < digits; i++)
        {
            byte currentByte = GetByte(this, (i >> 1));
            if (i % 2 == 1)
            {
                currentByte = currentByte >> 4;
            }
            c = Byte.ToHex(currentByte & 0x0F); // Masking the lower nibble
            String.BuildFront(ref result, c);
        }
        return result;
    }

    int ToInt(long l)
    {
        long intMax = Long.FromBytes(0xFF, 0xFF, 0x7F, 0x00); // Max value for int (32767)
        long intMin = Long.FromBytes(0x00, 0x00, 0x80, 0xFF); // Min value for int (-32768)
        long zero   = Long.FromBytes(0x00, 0x00, 0x00, 0x00); // Zero for comparison
        
        if (Long.GT(l, intMax) || Long.LT(l, intMin))
        {
            Die(0x0D); // numeric type out of range / overflow
        }
    
        int result;
        if (Long.LT(l, zero)) // Check if the value is negative
        {
            l = Long.Sub(zero, l); // Get the positive equivalent
            byte lowByte  = Long.GetByte(l, 0);
            byte highByte = Long.GetByte(l, 1);
            result = -Int.FromBytes(lowByte, highByte); // Negate the result
        }
        else
        {
            byte lowByte  = Long.GetByte(l, 0);
            byte highByte = Long.GetByte(l, 1);
            result = Int.FromBytes(lowByte, highByte); // Direct conversion for positive values
        }
        
        return result;
    }
    
    

    uint ToUInt(long l)
    {
        long uintMax = FromBytes(0xFF, 0xFF, 0x00, 0x00); // Max value for uint (65535)
        long uintMin = FromBytes(0x00, 0x00, 0x00, 0x00); // Min value for uint (0)

        if (Long.GT(l, uintMax) || Long.LT(l, uintMin))
        {
            Die(0x0D); // numeric type out of range / overflow
        }

        return UInt.FromBytes(GetByte(l, 0), GetByte(l, 1));
    }
    
    bool TryParse(string content, ref long returnValue)
    {
        long result;
        bool makeNegative;
        if (content.Length < 1)
        {
            return false;
        }
        if (content.StartsWith("0x"))
        {
            return tryParseHex(content, ref returnValue);
        }
        if (content.StartsWith('+'))
        {
            String.Substring(ref content, 1);
        }
        else if (content.StartsWith('-'))
        {
            String.Substring(ref content, 1);
            makeNegative = true;
        }
        foreach (var c in content)
        {
            result = result * 10;
            if (!c.IsDigit())
            {
                return false;
            }
            result = result + (byte(c) - 48); // 48 is ASCII for '0'
        }
        if (makeNegative)
        {
            result = -result;
        }
        returnValue = result;
        return true;
    }
    bool tryParseHex(string content, ref long returnValue)
    {
        bool success;
        uint length;
        uint i;
        char c;
        loop
        {
            returnValue = 0;
            if (!content.StartsWith("0x"))
            {
                break;
            }
            length = content.Length;
            if (length < 3)
            {
                break;
            }
            success = true;
            for (i=0; i < length-2; i++)
            {
                returnValue = returnValue * 16;
                c = content.GetChar(i+2);
                if (c.IsDigit())
                {
                    returnValue = returnValue + (byte(c) - 48); // 48 is ASCII for '0'
                }
                else if (c.IsHexDigit())
                {
                    returnValue = returnValue + (byte(c.ToLower()) - 87); // 97 is ASCII for 'a', -97+10 = -87
                }
                else
                {
                    success = false;
                    break;
                }
            }
            break;
        }
        return success;
    }
    
    float ToFloat(long l)
    {
        if (l == 0)
        {
            return Float.FromBytes(0, 0, 0, 0);
        }
        byte sign = (l < 0) ? 1 : 0;
        if (sign == 1)
        {
            l = -l;
        }
        int exponent = 127 + 23;
        long mantissa = shiftLeft(l, 8); // Shift the mantissa left by 8 bits
        exponent -= 8; // Adjust exponent for the left shift
        Float.normalize(ref mantissa, ref exponent);
        float result = Float.combineComponents(sign, byte(exponent), mantissa);
        return result;
    }
        
    long shiftLeft(long value, int bits)
    {
        // Shifts the long value left by the specified number of bits
        long result = value;
        for (int i = 0; i < bits; i++)
        {
            result = result.shiftLeftOne();
        }
        return result;
    }

    long shiftLeftOne(long value)
    {
        long result = FromBytes(
            (GetByte(value, 0) << 1),
            (GetByte(value, 1) << 1) | (GetByte(value, 0) >> 7),
            (GetByte(value, 2) << 1) | (GetByte(value, 1) >> 7),
            (GetByte(value, 3) << 1) | (GetByte(value, 2) >> 7)
        );
        return result;
    }

    long shiftRight(long value, int bits)
    {
        // Shifts the long value right by the specified number of bits
        long result = value;
        for (int i = 0; i < bits; i++)
        {
            result = result.shiftRightOne();
        }
        return result;
    }

    long shiftRightOne(long value)
    {
        // Shift the value right by 1 bit
        long result = FromBytes(
            (GetByte(value, 0) >> 1) | ((GetByte(value, 1) & 1) << 7),
            (GetByte(value, 1) >> 1) | ((GetByte(value, 2) & 1) << 7),
            (GetByte(value, 2) >> 1) | ((GetByte(value, 3) & 1) << 7),
            (GetByte(value, 3) >> 1)
        );
        return result;
    }

    long or(long left, long right)
    {
        return FromBytes(
            GetByte(left, 0) | GetByte(right, 0),
            GetByte(left, 1) | GetByte(right, 1),
            GetByte(left, 2) | GetByte(right, 2),
            GetByte(left, 3) | GetByte(right, 3)
        );
    }

    long and(long a, long b)
    {
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);
    
        byte b0 = GetByte(b, 0);
        byte b1 = GetByte(b, 1);
        byte b2 = GetByte(b, 2);
        byte b3 = GetByte(b, 3);
    
        byte result0 = a0 & b0;
        byte result1 = a1 & b1;
        byte result2 = a2 & b2;
        byte result3 = a3 & b3;
    
        return FromBytes(result0, result1, result2, result3);
    }

    long xor(long a, long b)
    {
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);

        byte b0 = GetByte(b, 0);
        byte b1 = GetByte(b, 1);
        byte b2 = GetByte(b, 2);
        byte b3 = GetByte(b, 3);

        byte result0 = a0 ^ b0;
        byte result1 = a1 ^ b1;
        byte result2 = a2 ^ b2;
        byte result3 = a3 ^ b3;

        return FromBytes(result0, result1, result2, result3);
    }

    long not(long a)
    {
        byte a0 = GetByte(a, 0);
        byte a1 = GetByte(a, 1);
        byte a2 = GetByte(a, 2);
        byte a3 = GetByte(a, 3);

        byte result0 = ~a0;
        byte result1 = ~a1;
        byte result2 = ~a2;
        byte result3 = ~a3;

        return FromBytes(result0, result1, result2, result3);
    }
    /*
    <byte> ToBytes(long this)
    {
        <byte> bytes;
        bytes.Append(this.GetByte(0));
        bytes.Append(this.GetByte(1));
        bytes.Append(this.GetByte(2));
        bytes.Append(this.GetByte(3));
        return bytes
    }
    */
}
