## LuaJIT Decompiler v2

*LuaJIT Decompiler v2* is a replacement tool for the old and now mostly defunct python decompiler.  
The project fixes all of the bugs and quirks the python decompiler had while also offering  
full support for gotos and stripped bytecode including locals and upvalues.

This repository variant also accepts KL82 bytecode (`1B 4B 4C 82`).
KL82 dumps with `FR2` use the current 97-opcode table. Historical KL82 dumps
without `FR2` use the LuaJIT 2.0 93-opcode table. Opcodes are normalized while
they are read; ordinary LuaJIT `LJ01` and `LJ02` inputs continue to use the
original parsing path.

## Usage

1. Head to the release section and download the latest executable.
2. Drag and drop a valid LuaJIT bytecode file or a folder containing such files onto the exe.  
Alternatively, run the program in a command prompt. Use `-?` to show usage and options.
3. All successfully decompiled `.lua` files are placed by default into the `output` folder  
located in the same directory as the exe.

The executable can be built from a normal PowerShell prompt with:

```powershell
.\build.ps1
```

The build script requires Visual Studio 2022 with the Desktop development with
C++ workload and writes `luajit-decompiler-v2.exe` beside this README.

## Memory-only worker protocol

Pass `--worker` to process multiple bytecode values through standard streams
without creating input, output, or intermediate content files. All integers are
unsigned 32-bit little-endian values.

Each request is framed as:

```text
bytecode_length | bytecode[bytecode_length]
```

Each response is framed as:

```text
status | payload_length | payload[payload_length]
```

Status `0` returns UTF-8 Lua source without a BOM and with LF line endings.
Status `1` reports rejected or unsupported bytecode with an empty payload.
Status `2` reports an internal request failure with an empty payload. Detailed
diagnostics are written only to stderr and never to the framed stdout stream.

The worker accepts requests up to 256 MiB. A clean EOF between requests exits
successfully. A truncated header, truncated body, or oversized frame writes a
diagnostic to stderr and terminates with a failure exit code. Closing stdin is
the caller's cancellation mechanism; callers may also terminate the isolated
worker process when cancelling an in-flight decompilation.

Feel free to [report any issues](https://github.com/marsinator358/luajit-decompiler-v2/issues/new) you have.

## TODO

* bytecode big endian support
* improved decompilation logic for conditional assignments

---

This project uses an boolean expression decompilation algorithm that is based on this paper:  
[www.cse.iitd.ac.in/~sak/reports/isec2016-paper.pdf](https://www.cse.iitd.ac.in/~sak/reports/isec2016-paper.pdf)
