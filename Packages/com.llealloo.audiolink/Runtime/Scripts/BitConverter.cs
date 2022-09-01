/*
MIT License
Copyright (c) 2022 Miner28_3
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

using System;
using UnityEngine;

namespace VRCAudioLink.Utils
{
	public static class BitConverter
	{
		#region Constants

		private const int 
			Bit8 = 8,
			Bit16 = 16,
			Bit24 = 24,
			Bit32 = 32,
			Bit40 = 40,
			Bit48 = 48,
			Bit56 = 56;

		private const uint 
			FloatSignBit = 0x80000000,
			FloatExpMask = 0x7F800000,
			FloatFracMask = 0x007FFFFF;
		
		private const ulong 
			DoubleSignBit = 0x8000000000000000,
			DoubleExpMask = 0x7FF0000000000000,
			DoubleFracMask = 0x000FFFFFFFFFFFFF;
		
		private const byte
			_0x80 = 0x80,
			_0xC0 = 0xC0,
			_0x3F = 0x3F,
			_0xF0 = 0xF0,
			_0xF8 = 0xF8,
			_0x07 = 0x07,
			_0x1F = 0x1F,
			_0x0F = 0x0F,
			_0xE0 = 0xE0;
		
		//TODO Once U# supports static fields
		//private static int[] decimalBuffer = new int[4];
		//private static byte[] guidBuffer = new byte[16];
		

		#endregion
		
		#region DataReading
		#region UTF-8 String

		/// <summary>
		/// Gets a UTF-8 string from <see cref="byte"/>[]
		/// </summary>
		/// <returns>UTF-8 String</returns>
		public static string ToString(byte[] buffer)
		{
			var chars = new string[buffer.Length];
			var charIndex = 0;
			int character = 0;
			int charCounter = 0;
			int bytesCount = buffer.Length;

			for (var i = 0; i < bytesCount; i++)
			{
				byte value = buffer[i];
				if ((value & _0x80) == 0)
				{
					chars[charIndex++] = ((char) value).ToString();
				}
				else if ((value & _0xC0) == _0x80)
				{
					if (charCounter > 0)
					{
						character = character << 6 | (value & _0x3F);
						charCounter--;
						if (charCounter == 0)
						{
							chars[charIndex++] = char.ConvertFromUtf32(character);
						}
					}
				}
				else if ((value & _0xE0) == _0xC0)
				{
					charCounter = 1;
					character = value & _0x1F;
				}
				else if ((value & _0xF0) == _0xE0)
				{
					charCounter = 2;
					character = value & _0x0F;
				}
				else if ((value & _0xF8) == _0xF0)
				{
					charCounter = 3;
					character = value & _0x07;
				}
			}

			return string.Concat(chars);
		}
		#endregion
		#region Int Types

		/// <summary>
		/// Reads 8-bit signed integer <see cref="sbyte"/>
		/// </summary>
		/// <returns><see cref="sbyte"/></returns>
		public static sbyte ToSByte(byte inputValue)
		{
			int value = inputValue;
			if(value >= 0x80) value = value - 256;
			return Convert.ToSByte(value);
		}
		
		/// <summary>
		/// Reads 16-bit signed integer <see cref="short"/>
		/// </summary>
		/// <returns><see cref="short"/></returns>
		public static short ToInt16(byte[] buffer)
		{
			int value = buffer[0] << Bit8 | buffer[1];
			if(value > 0x8000) value -= 0xFFFF;
			return Convert.ToInt16(value);
		}
		
		/// <summary>
		/// Reads 16-bit unsigned integer <see cref="ushort"/>
		/// </summary>
		/// <returns><see cref="ushort"/></returns>
		public static ushort ToUInt16(byte[] buffer)
		{
			return Convert.ToUInt16(buffer[0] << Bit8 | buffer[1]);
		}

		/// <summary>
		/// Reads 32-bit signed integer <see cref="int"/>
		/// </summary>
		/// <returns><see cref="int"/></returns>
		public static int ToInt32(byte[] buffer, int i)
		{
			/*
			int value = 0;
			value |= buffer[0] << BIT24;
			value |= buffer[1] << BIT16;
			value |= buffer[2] << BIT8;
			value |= buffer[3];
			return value;
			*/
			return
			       (buffer[0] << Bit24) | (buffer[1] << Bit16) | 
			       (buffer[2] << Bit8) | buffer[3];
		}

		/// <summary>
		/// Reads 32-bit unsigned integer <see cref="uint"/>
		/// </summary>
		/// <returns><see cref="uint"/></returns>
		public static uint ToUInt32(byte[] buffer)
		{
			/*
			uint value = 0;
			value |= (uint)buffer[0] << BIT24;
			value |= (uint)buffer[1] << BIT16;
			value |= (uint)buffer[2] << BIT8;
			value |= (uint)buffer[3];
			return value;
			*/
			return
			       ((uint) buffer[0] << Bit24) | ((uint) buffer[1] << Bit16) | 
			       ((uint) buffer[2] << Bit8) | buffer[3];
		}
		
		
		/// <summary>
		/// Reads 64-bit signed integer <see cref="long"/>
		/// </summary>
		/// <returns><see cref="long"/></returns>
		public static long ToInt64(byte[] buffer)
		{
			/*
			long value = 0;
			value |= (long)buffer[0] << BIT56;
			value |= (long)buffer[1] << BIT48;
			value |= (long)buffer[2] << BIT40;
			value |= (long)buffer[3] << BIT32;
			value |= (long)buffer[4] << BIT24;
			value |= (long)buffer[5] << BIT16;
			value |= (long)buffer[6] << BIT8;
			value |= (long)buffer[7];
			return value;
			*/
			return
			       ((long) buffer[0] << Bit56) | ((long) buffer[1] << Bit48) | 
			       ((long) buffer[2] << Bit40) | ((long) buffer[3] << Bit32) | 
			       ((long) buffer[4] << Bit24) | ((long) buffer[5] << Bit16) |
			       ((long) buffer[6] << Bit8) | buffer[7];
		}

		/// <summary>
		/// Reads 64-bit unsigned integer <see cref="ulong"/>
		/// </summary>
		/// <returns><see cref="ulong"/></returns>
		public static ulong ToUInt64(byte[] buffer)
		{
			/*
			ulong value = 0;
			value |= (ulong)buffer[0] << BIT56;
			value |= (ulong)buffer[1] << BIT48;
			value |= (ulong)buffer[2] << BIT40;
			value |= (ulong)buffer[3] << BIT32;
			value |= (ulong)buffer[4] << BIT24;
			value |= (ulong)buffer[5] << BIT16;
			value |= (ulong)buffer[6] << BIT8;
			value |= (ulong)buffer[7];
			return value;
			*/
			return
			       ((ulong) buffer[0] << Bit56) | ((ulong) buffer[1] << Bit48) |
			       ((ulong) buffer[2] << Bit40) | ((ulong) buffer[3] << Bit32) |
			       ((ulong) buffer[4] << Bit24) | ((ulong) buffer[5] << Bit16) |
			       ((ulong) buffer[6] << Bit8) | buffer[7];
		}

		#endregion
		#region Other C# Types

		/// <summary>
		/// Reads <see cref="char"/>
		/// </summary>
		/// <remarks>Uses 2 bytes</remarks>
		/// <param name="buffer"></param>
		/// <returns></returns>
		public static char ToChar(byte[] buffer)
		{
			int value = buffer[0] << Bit8 | buffer[1];
			if(value > 0x8000) value -= 0xFFFF;
			return (char) Convert.ToInt16(value);
		}
		
		/// <summary>
		/// Reads <see cref="bool"/>
		/// </summary>
		/// <remarks>Uses 1 byte</remarks>
		/// <param name="buffer"></param>
		/// <returns></returns>
		public static bool ToBool(byte buffer)
		{
			return buffer == 1;
		}

		/// <summary>
		/// Reads 32-bit as <see cref="float"/>
		/// </summary>
		/// <returns><see cref="float"/></returns>
		public static float ToSingle(byte[] buffer, int i)
		{
			//uint value = ReadUInt32(buffer);
			uint value = ((uint) buffer[0] << Bit24) | ((uint) buffer[1] << Bit16) | ((uint) buffer[2] << Bit8) | buffer[3];

			
			if(value == 0 || value == FloatSignBit) return 0f;

			int exp = (int)((value & FloatExpMask) >> 23);
			int frac = (int)(value & FloatFracMask);
			bool negate = (value & FloatSignBit) == FloatSignBit;
			if(exp == 0xFF)
			{
				if(frac == 0)
				{
					return negate ? float.NegativeInfinity : float.PositiveInfinity;
				}
				return float.NaN;
			}

			bool normal = exp != 0x00;
			if(normal) exp -= 127;
			else exp = -126;

			float result = frac / 8388608F;
			if(normal) result += 1f;

			result *= Mathf.Pow(2, exp);
			if(negate) result = -result;
			return result;
		}
		
		/// <summary>
		/// Reads half-precision floating-point number
		/// </summary>
		/// <remarks>Takes 2 bytes</remarks>
		/// <returns>half-precision <see cref="float"/></returns>
		public static float ToHalf(byte[] buffer)
		{
			//return Mathf.HalfToFloat(Convert.ToUInt16(ReadUInt16(buffer)));
			return Mathf.HalfToFloat(Convert.ToUInt16(buffer[0] << Bit8 | buffer[1]));
		}

		
		/// <summary>
		/// Reads <see cref="DateTime"/>
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns><see cref="DateTime"/></returns>
		public static DateTime ToDateTime(byte[] buffer)
		{
			//return DateTime.FromBinary(ReadInt64(buffer));
			return DateTime.FromBinary(((long) buffer[0] << Bit56) | ((long) buffer[1] << Bit48) |
			                           ((long) buffer[2] << Bit40) | ((long) buffer[3] << Bit32) |
			                           ((long) buffer[4] << Bit24) | ((long) buffer[5] << Bit16) |
			                           ((long) buffer[6] << Bit8) | buffer[7]);
		}

		/// <summary>
		/// Reads <see cref="TimeSpan"/>
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns><see cref="TimeSpan"/></returns>
		public static TimeSpan ToTimeSpan(byte[] buffer)
		{
			//return new TimeSpan(ReadInt64(buffer));
			return new TimeSpan(((long) buffer[0] << Bit56) | ((long) buffer[1] << Bit48) |
			                    ((long) buffer[2] << Bit40) | ((long) buffer[3] << Bit32) |
			                    ((long) buffer[4] << Bit24) | ((long) buffer[5] << Bit16) | ((long) buffer[6] << Bit8) |
			                    buffer[7]);

		}

		/// <summary>
		/// Reads decimal floating-point number
		/// </summary>
		/// <remarks>Takes 16 bytes</remarks>
		/// <returns><see cref="decimal"/></returns>
		public static decimal ToDecimal(byte[] buffer)
		{
			/*
			TODO Move to static field once U# supports them
			int[] decimalBuffer = new int[4];
			decimalBuffer[0] = ReadInt32(buffer);
			decimalBuffer[1] = ReadInt32(buffer);
			decimalBuffer[2] = ReadInt32(buffer);
			decimalBuffer[3] = ReadInt32(buffer);
			*/
			
			return new decimal(new int[]
			{
				(buffer[0] << Bit24) | (buffer[1] << Bit16) | (buffer[2] << Bit8) | (buffer[3]),
				(buffer[4] << Bit24) | (buffer[5] << Bit16) | (buffer[6] << Bit8) | (buffer[7]),
				(buffer[8] << Bit24) | (buffer[9] << Bit16) | (buffer[10] << Bit8) | (buffer[11]),
				(buffer[12] << Bit24) | (buffer[13] << Bit16) | (buffer[14] << Bit8) | (buffer[15])
			});
		}
		
		/// <summary>
		/// Reads <see cref="double"/>
		/// </summary>
		/// <returns><see cref="double"/></returns>
		public static double ToDouble(byte[] buffer)
		{
			ulong value = ((ulong) buffer[0] << Bit56) | ((ulong) buffer[1] << Bit48) |
			              ((ulong) buffer[2] << Bit40) | ((ulong) buffer[3] << Bit32) |
			              ((ulong) buffer[4] << Bit24) | ((ulong) buffer[5] << Bit16) |
			              ((ulong) buffer[6] << Bit8) | buffer[7];
			
			if (value == 0.0 || value == DoubleSignBit) return 0.0;

			long exp = (long)((value & DoubleExpMask) >> 52);
			long frac = (long)(value & DoubleFracMask);
			bool negate = (value & DoubleSignBit) == DoubleSignBit;

			if (exp == 0x7FF)
			{
				if (frac == 0) return negate ? double.NegativeInfinity : double.PositiveInfinity;
				return double.NaN;
			}

			bool normal = exp != 0x000;
			if (normal) exp -= 1023;
			else exp = -1022;

			double result = (double)frac / 0x10000000000000UL;
			if (normal) result += 1.0;

			result *= Math.Pow(2, exp);
			if (negate) result = -result;

			return result;
		}


		/// <summary>
		/// Reads <see cref="Guid"/>
		/// </summary>
		/// <remarks>Takes 16 bytes</remarks>
		/// <returns><see cref="Guid"/></returns>
		public static Guid ToGuid(byte[] buffer)
		{
			return new Guid(buffer);
		}

		#endregion
		#endregion

		#region DataWriting
		#region UTF-8 String
		
		/// <summary>
		/// Writes UTF-8 string <see cref="string"/>
		/// </summary>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(string str)
		{
			byte[] buffer = new byte[GetStringSizeInBytes(str)];
			int byteIndex = 0;
			int len = str.Length;
			for(var i = 0; i < len; i++)
			{
				int value = char.ConvertToUtf32(str, i);
				if(value < 0x80)
				{
					buffer[byteIndex++] = (byte)value;
				}
				else if(value < 0x0800)
				{
					buffer[byteIndex++] = (byte)(value >> 6 | 0xC0);
					buffer[byteIndex++] = (byte)(value & 0x3F | 0x80);
				}
				else if(value < 0x010000)
				{
					buffer[byteIndex++] = (byte)(value >> 12 | 0xE0);
					buffer[byteIndex++] = (byte)((value >> 6) & 0x3F | 0x80);
					buffer[byteIndex++] = (byte)(value & 0x3F | 0x80);
				}
				else
				{
					buffer[byteIndex++] = (byte)(value >> 18 | 0xF0);
					buffer[byteIndex++] = (byte)((value >> 12) & 0x3F | 0x80);
					buffer[byteIndex++] = (byte)((value >> 6) & 0x3F | 0x80);
					buffer[byteIndex++] = (byte)(value & 0x3F | 0x80);
				}
				if(char.IsSurrogate(str, i)) i++;
			}
			return buffer;
		}
	    
		/// <summary>
		/// Gets the size of a string in bytes
		/// </summary>
		/// <returns>String Array of <see cref="byte"/></returns>
		public static int GetStringSizeInBytes(string str)
		{
			int byteIndex = 0;
			int len = str.Length;
			for(var i = 0; i < len; i++)
			{
				int value = char.ConvertToUtf32(str, i);
				if(value >= 0x80)
				{
					if(value < 0x0800)
					{
						byteIndex++;
					}
					else if(value < 0x010000)
					{
						byteIndex += 2;
					}
					else
					{
						byteIndex += 3;
					}
				}
				byteIndex++;
				if(char.IsSurrogate(str, i)) i++;
			}
			return byteIndex;
		}
		
		#endregion
		#region Int Types
		
		/// <summary>
		/// Writes signed 8-bit integer (<see cref="sbyte"/>)
		/// </summary>
		/// <remarks>Takes 1 byte</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte GetByte(sbyte value)
		{
			return 
				(byte) (value < 0 ? (value + 0xFFFF) : value);
		}

		/// <summary>
		/// Writes signed 16-bit integer (<see cref="short"/>)
		/// </summary>
		/// <remarks>Takes 2 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(short value)
		{
			int tmp = value < 0 ? (value + 0xFFFF) : value;
			return new[] {(byte) (tmp >> Bit8), (byte) (tmp & 0xFF)};
		}

		/// <summary>
		/// Writes unsigned 16-bit integer (<see cref="ushort"/>)
		/// </summary>
		/// <remarks>Takes 2 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(ushort value)
		{
			return new[] {(byte) (value >> Bit8), (byte) (value & 0xFF)};
		}

		/// <summary>
		/// Writes signed 32-bit integer (<see cref="int"/>)
		/// </summary>
		/// <remarks>Takes 4 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(int value)
		{
			return new[]
			{
				(byte) ((value >> Bit24) & 0xFF), (byte) ((value >> Bit16) & 0xFF), 
				(byte) ((value >> Bit8) & 0xFF), (byte) (value & 0xFF)
			};
		}

		/// <summary>
		/// Writes unsigned 32-bit integer (<see cref="uint"/>)
		/// </summary>
		/// <remarks>Takes 4 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(uint value)
		{
			return new[]
			{
				(byte)((value >> Bit24) & 255u), (byte)((value >> Bit16) & 255u), 
				(byte)((value >> Bit8) & 255u), (byte)(value & 255u)
			};
		}

		/// <summary>
		/// Writes signed 64-bit integer (<see cref="long"/>)
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(long value)
		{

			return new[]
			{
				(byte)((value >> Bit56) & 0xFF), (byte)((value >> Bit48) & 0xFF),
				(byte)((value >> Bit40) & 0xFF), (byte)((value >> Bit32) & 0xFF), 
				(byte)((value >> Bit24) & 0xFF), (byte)((value >> Bit16) & 0xFF), 
				(byte)((value >> Bit8) & 0xFF), (byte)(value & 0xFF), 
			};
		}

		/// <summary>
		/// Writes unsigned 64-bit integer (<see cref="ulong"/>)
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(ulong value)
		{
			return new[]
			{
				(byte)((value >> Bit56) & 255ul), (byte)((value >> Bit48) & 255ul), 
				(byte)((value >> Bit40) & 255ul), (byte)((value >> Bit32) & 255ul), 
				(byte)((value >> Bit24) & 255ul), (byte)((value >> Bit16) & 255ul), 
				(byte)((value >> Bit8) & 255ul), (byte)(value & 255ul), 
			};
		}
		
		#endregion
		#region Other C# Types
		
		/// <summary>
		/// Writes <see cref="char"/>
		/// </summary>
		/// <remarks>Uses 2 bytes</remarks>
		/// <param name="value"></param>
		/// <returns></returns>
		public static byte[] GetBytes(char value)
		{
			var sValue = (short) value;
			int tmp = sValue < 0 ? (sValue + 0xFFFF) : sValue;
			return new[] {(byte) (tmp >> Bit8), (byte) (tmp & 0xFF)};
			
		}

		/// <summary>
		/// Writes <see cref="bool"/>
		/// </summary>
		/// <remarks>Uses 1 byte</remarks>
		/// <param name="value"></param>
		/// <returns></returns>
		public static byte GetByte(bool value)
		{
			return (byte) (value ? 0 : 1);
		}

		/// <summary>
		/// Writes single-precision floating-point number
		/// </summary>
		/// <remarks>Takes 4 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(float value)
		{
			uint tmp = 0;
			if(float.IsNaN(value))
			{
				tmp = FloatExpMask | FloatFracMask;
			}
			else if(float.IsInfinity(value))
			{
				tmp = FloatExpMask;
				if(float.IsNegativeInfinity(value)) tmp |= FloatSignBit;
			}
			else if(value != 0f)
			{
				if(value < 0f)
				{
					value = -value;
					tmp |= FloatSignBit;
				}

				int exp = 0;
				bool normal = true;
				while(value >= 2f)
				{
					value *= 0.5f;
					exp++;
				}
				while(value < 1f)
				{
					if(exp == -126)
					{
						normal = false;
						break;
					}
					value *= 2f;
					exp--;
				}

				if(normal)
				{
					value -= 1f;
					exp += 127;
				}
				else exp = 0;

				tmp |= Convert.ToUInt32(exp << 23) & FloatExpMask;
				tmp |= Convert.ToUInt32(value * 0x800000) & FloatFracMask;
			}
			//return WriteUInt32(tmp);
			return new[]
			{
				(byte)((tmp >> Bit24) & 255u), (byte)((tmp >> Bit16) & 255u), 
				(byte)((tmp >> Bit8) & 255u), (byte)(tmp & 255u)
			};
		}
		
		/// <summary>
		/// Writes half-precision floating-point number
		/// </summary>
		/// <remarks>Takes 2 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] WriteHalf(float value)
		{
			//return WriteUInt16(Mathf.FloatToHalf(value));
			ushort tmp = Mathf.FloatToHalf(value);
			return new[] {(byte) (tmp >> Bit8), (byte) (tmp & 0xFF)};
		}

		/// <summary>
		/// Writes <see cref="DateTime"/> structure
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(DateTime value)
		{
			//return WriteInt64(value.ToBinary());
			long tmp = value.ToBinary();
			return new[]
			{
				(byte)((tmp >> Bit56) & 0xFF), (byte)((tmp >> Bit48) & 0xFF),
				(byte)((tmp >> Bit40) & 0xFF), (byte)((tmp >> Bit32) & 0xFF), 
				(byte)((tmp >> Bit24) & 0xFF), (byte)((tmp >> Bit16) & 0xFF), 
				(byte)((tmp >> Bit8) & 0xFF), (byte)(tmp & 0xFF), 
			};
		}

		/// <summary>
		/// Writes <see cref="TimeSpan"/> structure
		/// </summary>
		/// <remarks>Takes 8 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(TimeSpan value)
		{
			//return WriteInt64(value.Ticks);
			long tmp = value.Ticks;
			return new[]
			{
				(byte)((tmp >> Bit56) & 0xFF), (byte)((tmp >> Bit48) & 0xFF),
				(byte)((tmp >> Bit40) & 0xFF), (byte)((tmp >> Bit32) & 0xFF), 
				(byte)((tmp >> Bit24) & 0xFF), (byte)((tmp >> Bit16) & 0xFF), 
				(byte)((tmp >> Bit8) & 0xFF), (byte)(tmp & 0xFF), 
			};
		}

		/// <summary>
		/// Writes <see cref="decimal"/> floating-point number
		/// </summary>
		/// <remarks>Takes 16 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(decimal value)
		{
			var tmp = Decimal.GetBits(value);
			return new[]
			{
				(byte) ((tmp[0] >> Bit24) & 0xFF), (byte) ((tmp[0] >> Bit16) & 0xFF), 
				(byte) ((tmp[0] >> Bit8) & 0xFF), (byte) (tmp[0] & 0xFF),
				
				(byte) ((tmp[1] >> Bit24) & 0xFF), (byte) ((tmp[1] >> Bit16) & 0xFF), 
				(byte) ((tmp[1] >> Bit8) & 0xFF), (byte) (tmp[1] & 0xFF),
				
				(byte) ((tmp[2] >> Bit24) & 0xFF), (byte) ((tmp[2] >> Bit16) & 0xFF), 
				(byte) ((tmp[2] >> Bit8) & 0xFF), (byte) (tmp[2] & 0xFF),
				
				(byte) ((tmp[3] >> Bit24) & 0xFF), (byte) ((tmp[3] >> Bit16) & 0xFF), 
				(byte) ((tmp[3] >> Bit8) & 0xFF), (byte) (tmp[3] & 0xFF)
			};
		}
		
		/// <summary>
		/// Writes <see cref="double"/>
		/// </summary>
		/// <param name="value"></param>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(double value)
		{
			ulong tmp = 0;
			if (double.IsNaN(value))
			{
				tmp = DoubleExpMask | DoubleFracMask;
			}
			else if (double.IsInfinity(value))
			{
				tmp = DoubleExpMask;
				if (double.IsNegativeInfinity(value)) tmp |= DoubleSignBit;
			}
			else if (value != 0.0)
			{
				if (value < 0.0)
				{
					value = -value;
					tmp |= DoubleSignBit;
				}

				long exp = 0;
				while (value >= 2.0)
				{
					value *= 0.5;
					++exp;
				}

				bool normal = true;
				while (value < 1.0)
				{
					if (exp == -1022)
					{
						normal = false;
						break;
					}
					value *= 2.0;
					--exp;
				}

				if (normal)
				{
					value -= 1.0;
					exp += 1023;
				}
				else exp = 0;

				tmp |= Convert.ToUInt64(exp << 52) & DoubleExpMask;
				tmp |= Convert.ToUInt64(value * 0x10000000000000) & DoubleFracMask;
			}

			return new[]
			{
				(byte)((tmp >> Bit56) & 255ul), (byte)((tmp >> Bit48) & 255ul), 
				(byte)((tmp >> Bit40) & 255ul), (byte)((tmp >> Bit32) & 255ul), 
				(byte)((tmp >> Bit24) & 255ul), (byte)((tmp >> Bit16) & 255ul), 
				(byte)((tmp >> Bit8) & 255ul), (byte)(tmp & 255ul), 
			};
		}

		/// <summary>
		/// Writes <see cref="Guid"/> structure
		/// </summary>
		/// <remarks>Takes 16 bytes</remarks>
		/// <returns>Array of <see cref="byte"/></returns>
		public static byte[] GetBytes(Guid value)
		{
			return value.ToByteArray();
		}


		#endregion
		
		
		#endregion
	}
}