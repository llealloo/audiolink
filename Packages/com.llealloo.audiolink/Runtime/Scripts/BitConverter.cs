using System;
using UnityEngine;

namespace VRCAudioLink.Utils
{
    public static class BitConverter
    {
        public static float GetBytesIntToSingle(int v)
        {
            uint value = ((uint) (byte) ((v >> 24) & 0xFF) << 24) |
                         ((uint) (byte) ((v >> 16) & 0xFF) << 16) | ((uint) (byte) ((v >> 8) & 0xFF) << 8) |
                         (byte) (v & 0xFF);


            if (value == 0 || value == 0x80000000) return 0f;

            int exp = (int) ((value & 0x7F800000) >> 23);
            int frac = (int) (value & 0x007FFFFF);
            bool negate = (value & 0x80000000) == 0x80000000;
            if (exp == 0xFF)
            {
                if (frac == 0)
                {
                    return negate ? float.NegativeInfinity : float.PositiveInfinity;
                }

                return float.NaN;
            }

            bool normal = exp != 0x00;
            if (normal) exp -= 127;
            else exp = -126;

            float result = frac / 8388608F;
            if (normal) result += 1f;

            result *= Mathf.Pow(2, exp);
            if (negate) result = -result;
            return result;
        }

        public static float ToFloat(uint value)
        {
            uint frac = value & 0x007FFFFF;
            return (frac / 8388608F) * 1.1754944e-38F;
        }
        public static int GetBytesSingleToInt32(float v)
        {
            float value = v;
            uint tmp = 0;
            if (float.IsNaN(value))
            {
                tmp = 0x7F800000 | 0x007FFFFF;
            }
            else if (float.IsInfinity(value))
            {
                tmp = 0x7F800000;
                if (float.IsNegativeInfinity(value)) tmp |= 0x80000000;
            }
            else if (value != 0f)
            {
                if (value < 0f)
                {
                    value = -value;
                    tmp |= 0x80000000;
                }

                int exp = 0;
                bool normal = true;
                while (value >= 2f)
                {
                    value *= 0.5f;
                    exp++;
                }

                while (value < 1f)
                {
                    if (exp == -126)
                    {
                        normal = false;
                        break;
                    }

                    value *= 2f;
                    exp--;
                }

                if (normal)
                {
                    value -= 1f;
                    exp += 127;
                }
                else exp = 0;

                tmp |= Convert.ToUInt32(exp << 23) & 0x7F800000;
                tmp |= Convert.ToUInt32(value * 0x800000) & 0x007FFFFF;
            }

            return ((byte) ((tmp >> 24) & 255u) << 24) | ((byte) ((tmp >> 16) & 255u) << 16) |
                   ((byte) ((tmp >> 8) & 255u) << 8) | (byte) (tmp & 255u);
        }

    }
}