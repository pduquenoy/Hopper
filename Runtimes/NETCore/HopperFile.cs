﻿using System.Reflection;

namespace HopperNET
{
    public class HopperPath
    {
        static string hopperRoot;
        public static bool InitializeFolders()
        {
            string exePath = Environment.ProcessPath;
            string exeFolder = Path.GetDirectoryName(exePath);
            string subFolder = Path.GetFileName(exeFolder);
            exeFolder = Path.GetDirectoryName(exeFolder);
            if (subFolder == "Bin")
            {
                hopperRoot = exeFolder;
            }
            else
            {
                hopperRoot = exeFolder;
                while (!hopperRoot.EndsWith("Hopper"))
                {
                    hopperRoot = Path.GetDirectoryName(hopperRoot);
                    if (String.IsNullOrEmpty(hopperRoot)) { break; }
                }
            }
            if (string.IsNullOrEmpty(hopperRoot))
            {
                return false;
            }
            Directory.SetCurrentDirectory(hopperRoot);

            string tempFolder = Path.Combine(hopperRoot, "Temp");
            if (!Directory.Exists(tempFolder))
            {
                Directory.CreateDirectory(tempFolder);
            }
            string debugFolder = Path.Combine(hopperRoot, "Debug");
            if (!Directory.Exists(debugFolder))
            {
                Directory.CreateDirectory(debugFolder);
            }
            string objFolder = Path.Combine(debugFolder, "Obj");
            if (!Directory.Exists(objFolder))
            {
                Directory.CreateDirectory(objFolder);
            }
            return true;
        }
        public static string ToWindowsPath(string path)
        {
            if (!String.IsNullOrEmpty(path) && (path[0] != '/'))
            {
                path = HopperSystem.CurrentDirectory + path;
            }
            path = path.Replace("/", @"\");
            path = hopperRoot + path;
            return path;
        }
        public static string ToHopperPath(string path)
        {
            if (!path.Contains(hopperRoot))
            {
                throw new InvalidDataException();
            }
            path = path.Replace(hopperRoot, "");
            path = path.Replace(@"\", "/");
            return path;
        }
        public static bool IsCanonicalFullPath(String fullPath)
        {
            bool result = false;
            for (;;) // single exit point
            {
                if (String.IsNullOrEmpty(fullPath))
                {
                    break;
                }
                if (fullPath[0] != '/')
                {
                    break; // all full paths start with '/'
                }
                //ushort index = 0;
                //if (!String_IndexOf(fullPath, L'/', &index))
                //{
                //    break; // empty subFolder name not allowed
                //}
                result = true;
                break;
            }
            return result;
        }
        public static bool ValidatePath(string path)
        {
            foreach (char ch in path)
            {
                if ((ch >= '0') && (ch <= '9'))
                {
                    // ok
                }
                else if ((ch >= 'a') && (ch <= 'z'))
                {
                    // ok
                }
                else if ((ch >= 'A') && (ch <= 'Z'))
                {
                    // ok
                }
                else if (ch == '/')
                {
                    // ok
                }
                else if (ch == '.')
                {
                    // ok
                }
                else
                {
                    return false;
                }
            }
            int iSlash = path.LastIndexOf('/');
            if (iSlash != -1)
            {
                int iDot = path.LastIndexOf('.', iSlash);
                if (iDot != -1)
                {
                    if (iSlash > iDot)
                    {
                        return false; // '.' is in a folder name (not allowed be possible in Hopper)
                    }
                }
            }
            if (path.Contains(@"/."))
            {
                return false; // empty filenames are not allowed in Hopper
            }
            return true;
        }
    }
    public class HopperFile : Variant
    {
        public HopperFile()
        {
            Type = HopperType.tFile;
        }
        public override Variant Clone()
        {
            HopperFile clone = new HopperFile();
            clone.isValid = isValid;
            clone.path = path;
            clone.pos = pos;
            clone.reading = reading;
            clone.writing = writing;
            clone.bytes = bytes;
            clone.content = content;
            return clone;
        }
#if DEBUG
        public override void Validate()
        {
            Diagnostics.ASSERT(Type == HopperType.tFile, "HopperFile validation failed");
        }
#endif

        bool isValid;
        byte[] bytes;
        List<byte> content;
        Int32 pos = 0;
        string path;
        bool reading;
        bool writing;
        public static bool Exists(string path)
        {
            if (!HopperPath.ValidatePath(path)) return false;
            return File.Exists(HopperPath.ToWindowsPath(path));
        }
        public static void Delete(string path)
        {
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
        }
        public static Int32 GetSize(string path)
        {
            long length = 0;
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    length = fi.Length;
                }
            }
            return (Int32)length;
        }
        

        public byte Read()
        {
            byte b = 0;
            if (reading && isValid && (pos < bytes.Length))
            {
                b = bytes[pos];
                pos++;
            }
            else
            {
                isValid = false;
            }
            return b;
        }
        public ushort Read(HopperArray buffer, ushort bufferSize)
        {
            ushort bytesRead = 0;
            if (reading && isValid)
            {
                while ((pos < bytes.Length) && (bytesRead < bufferSize))
                {
                    buffer.Value[bytesRead] = bytes[pos];
                    bytesRead++;
                    pos++;
                }
            }
            else
            {
                isValid = false;
            }
            return bytesRead;
        }
        
        public string ReadLine()
        {
            string ln = "";
            if (reading && isValid && (pos < bytes.Length))
            {
                for (; ; )
                {
                    if (pos == bytes.Length)
                    {
                        isValid = ln.Length > 0; // EOF
                        break;
                    }
                    byte buffer = bytes[pos];
                    pos++;
                    if (buffer == 0x0D)
                    {
                        continue;
                    }
                    if (buffer == 0x0A)
                    {
                        break;
                    }
                    ln = ln + (char)buffer;
                }
            }
            else
            {
                isValid = false;
            }
            return ln;
        }
        public byte Read(Int32 seekpos)
        {
            byte b = 0;
            if (reading && isValid && (seekpos < bytes.Length))
            {
                b = bytes[seekpos];
            }
            else
            {
                isValid = false;
            }
            return b;
        }
        public void Append(byte b)
        {
            if (writing && isValid)
            {
                content.Add(b);
            }
            else
            {
                isValid = false;
            }
        }
        public void Append(string str)
        {
            if (writing && isValid)
            {
                foreach (char c in str)
                {
                    content.Add((byte)c);
                }
            }
            else
            {
                isValid = false;
            }
        }
        public void Flush()
        {
            if (writing && isValid)
            {
                File.WriteAllBytes(path, content.ToArray());
            }
            else
            {
                isValid = false;
            }
        }
        public bool IsValid()
        {
            return isValid;
        }

        public static HopperFile Open(string path)
        {
            HopperFile hopperFile = new HopperFile();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    hopperFile.bytes = File.ReadAllBytes(path);
                    hopperFile.isValid = true;
                    hopperFile.reading = true;
                    hopperFile.writing = false;
                }
            }
            return hopperFile;
        }
        public static HopperFile Create(string path)
        {
            HopperFile hopperFile = new HopperFile();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    File.Delete(path);
                    hopperFile.isValid = true;
                }
                hopperFile.path = path;
                hopperFile.isValid = true;
                hopperFile.reading = false;
                hopperFile.writing = true;
                hopperFile.content = new List<Byte>();
            }
            return hopperFile;
        }
        public static Int32 GetTimeStamp(string path)
        {
            long filetime = 0;
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    DateTime dt = fi.LastWriteTime;
                    long unixTime = ((DateTimeOffset)dt).ToUnixTimeSeconds();
                    filetime = unixTime;
                }
            }
            return (Int32)filetime;
        }
        public static HopperString GetTime(string path)
        {
            HopperString str = new HopperString();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    DateTime dt = fi.LastWriteTime;
                    str.Value = dt.ToString("HH:mm:ss");
                }
            }
            return str;
        }
        public static HopperString GetDate(string path)
        {
            HopperString str = new HopperString();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    DateTime dt = fi.LastWriteTime;
                    str.Value = dt.ToString("yyyy-MM-dd");
                }
            }
            return str;
        }

    }

    public class HopperDirectory : Variant
    {
        public static HopperString GetTime(string path)
        {
            HopperString str = new HopperString();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    DateTime dt = fi.LastWriteTime;
                    str.Value = dt.ToString("HH:mm:ss");
                }
            }
            return str;
        }
        public static HopperString GetDate(string path)
        {
            HopperString str = new HopperString();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (File.Exists(path))
                {
                    FileInfo fi = new FileInfo(path);
                    DateTime dt = fi.LastWriteTime;
                    str.Value = dt.ToString("yyyy-MM-dd");
                }
            }
            return str;
        }

        public HopperDirectory()
        {
            Type = HopperType.tDirectory;
        }
        bool isValid;
        string path;
#if DEBUG
        public override void Validate()
        {
            Diagnostics.ASSERT(Type == HopperType.tDirectory, "HopperDirectory validation failed");
        }
#endif
        public override Variant Clone()
        {
            HopperDirectory clone = new HopperDirectory();
            clone.isValid = isValid;
            clone.path = path;
            return clone;
        }

        public static bool Exists(string path)
        {
            if (!HopperPath.ValidatePath(path)) return false;
            return Directory.Exists(HopperPath.ToWindowsPath(path));
        }
        public static HopperDirectory Open(string fullDirectoryPath)
        {
            HopperDirectory directory = new HopperDirectory();
            if (HopperPath.ValidatePath(fullDirectoryPath))
            {
                if (!HopperPath.IsCanonicalFullPath(fullDirectoryPath))
                {
                    return directory;
                }
                string path = HopperPath.ToWindowsPath(fullDirectoryPath);
                if (Directory.Exists(path))
                {
                    directory.isValid = true;
                    directory.path = path;
                }
            }
            return directory;
        }
        public bool IsValid()
        {
            return isValid;
        }
        public static void Create(string path)
        {
            HopperDirectory directory = new HopperDirectory();
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (Directory.Exists(path))
                {
                    directory.isValid = true;
                    directory.path = path;
                }
                else
                {
                    try
                    {
                        DirectoryInfo info = Directory.CreateDirectory(path);
                        directory.path = path;
                        directory.isValid = true;
                    }
                    catch (IOException)
                    {
                        // something went wrong so !isValid
                    }
                }
            }
        }
        public static void Delete(string path)
        {
            if (HopperPath.ValidatePath(path))
            {
                path = HopperPath.ToWindowsPath(path);
                if (Directory.Exists(path))
                {
                    try
                    {
                        Directory.Delete(path);
                    }
                    catch (IOException)
                    {
                        // something went wrong
                    }
                }
            }
        }

        

        public HopperString GetDirectory(ushort index)
        {
            HopperString directory = new HopperString();
            if (isValid)
            {
                ushort count = 0;
                foreach (String windowsPath in Directory.GetDirectories(path))
                {
                    string hopperPath = HopperPath.ToHopperPath(windowsPath);
                    if (HopperPath.ValidatePath(hopperPath))
                    {
                        if (count == index)
                        {
                            directory.Value = hopperPath;
                            if (!windowsPath.EndsWith(@"\"))
                            {
                                directory.Value += "/";
                            }
                            break;
                        }
                        count++;
                    }
                }
            }
            return directory; // full hopper path, leading and trailing /
        }

        public HopperString GetFile(ushort index)
        {
            HopperString file = new HopperString();
            if (isValid)
            {
                ushort count = 0;
                foreach (String windowsPath in Directory.GetFiles(path))
                {
                    string hopperPath = HopperPath.ToHopperPath(windowsPath);
                    if (HopperPath.ValidatePath(hopperPath))
                    {
                        if (count == index)
                        {
                            file.Value = hopperPath;
                            break;
                        }
                        count++;
                    }
                }
            }
            return file; // full hopper path
        }

        public ushort GetDirectoryCount()
        {
            ushort skipped = 0;
            return GetDirectoryCount(ref skipped);
        }
        public ushort GetDirectoryCount(ref ushort skipped)
        {
            ushort count = 0;
            if (isValid)
            {
                foreach (String windowsPath in Directory.GetDirectories(path))
                {
                    string hopperPath = HopperPath.ToHopperPath(windowsPath);
                    if (HopperPath.ValidatePath(hopperPath))
                    {
                        count++; // TODO : ignore .. and .
                    }
                    else
                    {
                        skipped++;
                    }
                }
            }
            return count;
        }
        public ushort GetFileCount()
        {
            ushort skipped = 0;
            return GetFileCount(ref skipped);
        }
        public ushort GetFileCount(ref ushort skipped)
        {
            ushort count = 0;
            if (isValid)
            {
                foreach (String windowsPath in Directory.GetFiles(path))
                {
                    string hopperPath = HopperPath.ToHopperPath(windowsPath);
                    if (HopperPath.ValidatePath(hopperPath))
                    {
                        count++;
                    }
                    else
                    {
                        skipped++;
                    }
                }
            }
            return count;
        }
        
    }
}
