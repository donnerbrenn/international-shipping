OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)
SEARCH_DIR("/lib"); 
SECTIONS
{
  PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x10000)); . = SEGMENT_START("text-segment", 0x10000) + SIZEOF_HEADERS; . = ALIGN(1) + (. & (1));
  .interp           : {*(.interp*)}
  .dynamic          : {*(.dynamic*)}
  .dynstr           : {*(.dynstr*)}
  .rodata           : {*(.rodata*)}
  .gnu.version_r    : {*(.gnu.version_r*)}
  .data             : {*(.data*)}
  .text             : {*(.text*)}
  .rela.got         : {*(.rela.got*)}
  .dynsym           : {*(.dynsym*)}
  .bss              : {*(.bss*)}
  .crap             : {*(.gnu.version*) *(.got*) *(.hash*) *(.plt*) *(.eh_frame*) *(.comment*) *(.note*) } 
}
