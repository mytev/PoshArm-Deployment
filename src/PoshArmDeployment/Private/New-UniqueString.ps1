#Requires -Version 5.0
function New-UniqueString {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $InputObject,
        [switch]
        $PassThru
    )

    Begin {
        $f = $MyInvocation.InvocationName
        Write-Verbose -Message "$f - START"

        $UniqueStringHelperCode = @"
using System.Text;

namespace Hashing
{
    public static class UniqueStringHelper
    {
        public static string GenerateBase32HashedString(string str)
        {
            return Base32Encode(MurmurHash64(Encoding.UTF8.GetBytes(str)));
        }

        // <summary>
        /// Converts 64 bits value to Base32 encoded string.
        /// </summary>
        /// <param name="input">The value to be encoded.</param>
        private static string Base32Encode(ulong input)
        {
            var charset = "abcdefghijklmnopqrstuvwxyz234567";
            var sb = new StringBuilder();

            for (var index = 0; index < 13; index++)
            {
                sb.Append(charset[(int)(input >> 59)]);
                input <<= 5;
            }

            return sb.ToString();
        }

        private static ulong MurmurHash64(byte[] data, uint seed = 0)
        {
            const uint C1 = 0x239b961b;
            const uint C2 = 0xab0e9789;
            const uint C3 = 0x561ccd1b;
            const uint C4 = 0x0bcaa747;
            const uint C5 = 0x85ebca6b;
            const uint C6 = 0xc2b2ae35;

            int length = data.Length;

            unchecked
            {
                uint h1 = seed;
                uint h2 = seed;

                int index = 0;
                while (index + 7 < length)
                {
                    uint k1 = (uint)(data[index + 0] | data[index + 1] << 8 | data[index + 2] << 16 | data[index + 3] << 24);
                    uint k2 = (uint)(data[index + 4] | data[index + 5] << 8 | data[index + 6] << 16 | data[index + 7] << 24);

                    k1 *= C1;
                    k1 = k1.RotateLeft32(15);
                    k1 *= C2;
                    h1 ^= k1;
                    h1 = h1.RotateLeft32(19);
                    h1 += h2;
                    h1 = (h1 * 5) + C3;

                    k2 *= C2;
                    k2 = k2.RotateLeft32(17);
                    k2 *= C1;
                    h2 ^= k2;
                    h2 = h2.RotateLeft32(13);
                    h2 += h1;
                    h2 = (h2 * 5) + C4;

                    index += 8;
                }

                int tail = length - index;
                if (tail > 0)
                {
                    uint k1 = (tail >= 4) ? (uint)(data[index + 0] | data[index + 1] << 8 | data[index + 2] << 16 | data[index + 3] << 24) :
                            (tail == 3) ? (uint)(data[index + 0] | data[index + 1] << 8 | data[index + 2] << 16) :
                            (tail == 2) ? (uint)(data[index + 0] | data[index + 1] << 8) :
                                            (uint)data[index + 0];

                    k1 *= C1;
                    k1 = k1.RotateLeft32(15);
                    k1 *= C2;
                    h1 ^= k1;

                    if (tail > 4)
                    {
                        uint k2 = (tail == 7) ? (uint)(data[index + 4] | data[index + 5] << 8 | data[index + 6] << 16) :
                                (tail == 6) ? (uint)(data[index + 4] | data[index + 5] << 8) :
                                                (uint)data[index + 4];

                        k2 *= C2;
                        k2 = k2.RotateLeft32(17);
                        k2 *= C1;
                        h2 ^= k2;
                    }
                }

                h1 ^= (uint)length;
                h2 ^= (uint)length;

                h1 += h2;
                h2 += h1;

                h1 ^= h1 >> 16;
                h1 *= C5;
                h1 ^= h1 >> 13;
                h1 *= C6;
                h1 ^= h1 >> 16;

                h2 ^= h2 >> 16;
                h2 *= C5;
                h2 ^= h2 >> 13;
                h2 *= C6;
                h2 ^= h2 >> 16;

                h1 += h2;
                h2 += h1;

                return ((ulong)h2 << 32) | (ulong)h1;
            }
        }

        private static uint RotateLeft32(this uint value, int count)
        {
            return (value << count) | (value >> (32 - count));
        }
    }
}
"@
        Add-Type -TypeDefinition $UniqueStringHelperCode
    }

    Process {
        Write-Verbose -Message "$f -  Processing"

        [Hashing.UniqueStringHelper]::GenerateBase32HashedString(($InputObject -join ''))

        if ($PassThru.IsPresent) {
            $InputObject
        }
    }

    End {
        Write-Verbose -Message "$f - End"
    }
}