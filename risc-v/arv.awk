#!/usr/bin/env tawk -f
#

function exp2(n, i, r) {
    if ( n == 0 ) { return 1 }

    r = 2
    for ( i = 1; i < n; i++ ) { r *= 2; }

    return r;
}

function ltrim(str) { gsub(/^ */, "", str); return str; }
function rtrim(str) { gsub(/ *$/, "", str); return str; }
function trim(str) { return ltrim(rtrim(str)) }
function error(str) { print str > "/dev/stderr"; ERROR = 1; exit(1) }

function mkHash(names, arr, regNames,              n, i) {
    n = split(names, regNames)
    for ( i = 1; i <= n; i++ ) {
        arr[regNames[i]] = i - 1
    }
}

function readInstrs(                    i) {
    while ( (getline < "instr.tab") > 0 ) {
        instr = trim($2)
        INSTR[instr, BITS] = trim($1)
        INSTR[instr, NARG] = NF -2
        for ( i = 2; i <= NF; i++ ) {
            INSTR[instr, i-2] = $i
        }
    }
}

function initAsm() {
    BITS = "bits"
    NARG = "narg"
    readInstrs()

  dot = 0
  stack = 5000
  heap  = 1000

  apinames = "zero ra  sp  gp  tp  t0  t1  t2  s0  s1  a0  a1  a2  a3  a4  a5  a6  a7  s1  s3  s4  s5  s6  s7  s8  s9  s10 s11 t3  t4  t5  t6  "
  regnames = "x0   x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 "

  mkHash(apinames, API, API_NAMES)
  mkHash(regnames, REG, REG_NAMES)
}

BEGIN {

  argc = 0
  here = heap
  LABEL["_start"] = dot
  LABEL["_stack"] = stack - 1
  LABEL["_heap"]  = heap
  LABEL["_start"] = dot

  MEM[LABEL["_heap"]] = heap++

  argv = heap
  argc = 0
  for (i = 2; i <= ARGC - 1; i++ ) {
    if ( ARGV[i] == "--l"  ) { trace_labl = 1; continue }
    if ( ARGV[i] == "--d"  ) { trace_dump = 1; continue }
    if ( ARGV[i] == "--tc" ) { trace_call = 1; continue }
    if ( ARGV[i] == "--ti" ) { trace_inst = 1; continue }
    MEM[heap++]= ARGV[i]
    argc++
  }
}

{ line = $0 }

{ gsub(/\t/, " ") }
{ gsub(/#.*$/, "") }
{ gsub(/,/, " ") }

/^ *[_a-zA-Z]+:/ {
  gsub(/:/, "")
  l = $1
  if ( LABEL[l] != "" ) {
    error("Duplicate label \"" l "\"")
  }
  LABEL[l] = dot
  $1 = ""
  $0 = $0
}

/\.org/ {
  dot = $2+0
  next
}

/\.mem/ {
  for ( i = 2; i <= NF; i++ ) {
    MEM[dot++] = $i
  }
  next
}

/^ *$/ { next }

function assemble(line) {
    nf = split(line, field)
    instr = field[1]

    bits = INSTR[instr, BITS]
    if ( bits== "" ) {
        error("unknown instruction : \"" instr "\"")
    }

    narg = INSTR[instr, NARG]
    if ( narg != nf-1 ) {
        error("instruction " instr " expects " INSTR[instr, NARG] " args")
    }

    for ( i = 1; i <= narg; i++ ) {
        bits = or(bits, encode(INSTR[instr, i], field[i+1]))
    }

    MEM[dot] = bits + 0
    dot += 1
}

/^ *assert +/ { $0 = "ass " $2 " " $3 }
/^ *inc +/    { $0 = "add " $2 " " 1 }
/^ *dec +/    { $0 = "add " $2 " " (-1) }

{ assemble($0) }

function    rd(name) { return register(name) * exp2( 7) }
function   rs1(name) { return register(name) * exp2(15) }
function   rs2(name) { return register(name) * exp2(20) }

function imm12(value) { return value * exp2(20) }
function bimm12(value) {
    return  or(     and(0x1000, value) * exp2(19),
            or(     and(0x0800, value) / exp2( 4),
            or(     and(0x07E0, value) * exp2(20), 
                    and(0x001E, value) * exp2( 7))))
}
function simm12(value) {
    return or(      and(0x0FE0, value) * exp2(20), 
                    and(0x001F, value) * exp2( 7))
}

function imm20(value) { return value * exp2(12) }
function jimm20(value) {
    return  or(     and(0x100000, value) * exp2(11),
            or(     and(0x0ff000, value) / exp2(0), 
            or(     and(0x000800, value) * exp2(9), 
                    and(0x0007fe, value) * exp2(20))))
}

function  rd_decode(value) { return and(0x1f, value / exp2( 7)) }
function rs1_decode(value) { return and(0x1f, value / exp2(15)) }
function rs2_decode(value) { return and(0x1f, value / exp2(20)) }

function imm12_decode(value) { return value * exp2(20) }
function bimm12_decode(value) {
    return  or(     and(0x1000, value) * exp2(19),
            or(     and(0x0800, value) / exp2( 4),
            or(     and(0x07E0, value) * exp2(20), 
                    and(0x001E, value) * exp2( 7))))
}
function simm12_decode(value) {
    return or(      and(0x0FE0, value) * exp2(20), 
                    and(0x001F, value) * exp2( 7))
}

function imm20_decode(value) { return value * exp2(12) }
function jimm20_decode(value) {
    return  or(     and(0x100000, value) * exp2(11),
            or(     and(0x0ff000, value) / exp2(0), 
            or(     and(0x000800, value) * exp2(9), 
                    and(0x0007fe, value) * exp2(20))))
}

function register(name) {
    reg = API[name]
    if ( reg == "" ) {
        reg = REG[name]
    }
    if ( reg == "" ) {
        error("expected register name found : " name)
    }

    return reg
}

function encode(type, value                 , field) {
    if ( type ==     "rd" ) { return     rd(value) }
    if ( type ==    "rs1" ) { return    rs1(value) } 
    if ( type ==    "rs2" ) { return    rs2(value) }
    if ( type ==  "imm12" ) { return  imm12(value) }

    if ( field == "." ) { value = dot }

    label = LABEL[field]
    if ( label != "") { value = label; }

    if ( type ==  "imm12" ) { return  imm12(value) }
    if ( type == "simm12" ) { return simm12(value) }
    if ( type == "bimm12" ) { return bimm12(value) }
    if ( type ==  "imm20" ) { return  imm20(value) }

    error("cannot encode " type " " value)
}

function dump(start, end) {
  if ( end == "" ) {
      end = stack
  }
  for ( l in LABEL ) {
    LL[LABEL[l]] = l
  }
  for ( i = start; i < stack; i++ ) {
      if ( MEM[i] != "" || prev == 1 ) {
          printf("%6s: %12s %08x\n", i, LL[i], MEM[i])
          prev = 0
      }
      if ( MEM[i] != "" ) {
          prev = 1
      }
  }
  print ""
}

END {
    if (ERROR == 1) { exit(1) }
    dump(0)

  if ( trace_dump ) { dump(0); exit(0) }
  if ( trace_labl ) {
    for ( label in LABEL ) {
        print label, LABEL[label]
    }
    exit(0)
  }
}
