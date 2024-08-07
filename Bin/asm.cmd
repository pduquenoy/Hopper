preprocess /source/compiler/65asm
preprocess /source/compiler/65gen
preprocess /source/compiler/65opt
preprocess /source/compiler/65dasm
preprocess /source/compiler/Z80Gen
preprocess /source/compiler/Z80Opt
preprocess /source/compiler/Z80DASM
preprocess /source/debugger/e6502
preprocess /source/debugger/eZ80
preprocess /source/languages/tiggerc/tcpp
preprocess /source/languages/tiggerc/tcc

compile 65asm -o
compile 65gen -o
compile 65opt -o
compile 65dasm -o
compile Z80Gen -o
compile Z80Opt -o
compile Z80DASM -o
compile e6502 -o
compile eZ80 -o
compile tcpp -o
compile tcc -o

optimize 65asm
optimize 65gen
optimize 65opt
optimize 65dasm
optimize Z80Gen
optimize Z80Opt
optimize Z80DASM
optimize e6502
optimize eZ80
optimize tcpp
optimize tcc

codegen 65asm
codegen 65gen
codegen 65opt
codegen 65dasm
codegen Z80Gen
codegen Z80Opt
codegen Z80DASM
codegen e6502
codegen eZ80
codegen tcpp
codegen tcc

dasm 65asm
dasm 65gen
dasm 65opt
dasm 65dasm
dasm Z80Gen
dasm Z80Opt
dasm Z80DASM
dasm e6502
dasm eZ80
dasm tcpp
dasm tcc

preprocess /source/runtime/r6502.asm -a
65asm r6502
65opt r6502
65gen r6502
65dasm r6502

