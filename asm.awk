#!/usr/bin/env awk -f
#

function ltrim(str) { gsub(/^ */, "", str); return str; }
function rtrim(str) { gsub(/ *$/, "", str); return str; }
function trim(str) { return ltrim(rtrim(str)) }
function error(str) { print str > "/dev/stderr"; ERROR = 1; exit(1) }

BEGIN {
  dot = 0
  stack = 5000
  heap  = 1000

  ip = 0
  equal = 0

  REG["a"] = 0
  REG["b"] = 0
  REG["c"] = 0
  REG["d"] = 0
  REG["sp"] = stack
  REG["fp"] = 0

  for ( reg in REG ) {
    REGS[reg] = reg
  }

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
    if ( ARGV[i] == "-l"  ) { trace_labl = 1; continue }
    if ( ARGV[i] == "-d"  ) { trace_dump = 1; continue }
    if ( ARGV[i] == "-tc" ) { trace_call = 1; continue }
    if ( ARGV[i] == "-ti" ) { trace_inst = 1; continue }
    MEM[heap++]= ARGV[i]
    argc++
  }
  MEM[LABEL["_heap"]] = heap
  if ( argc > 0 ) {
      assemble("push " argv)
  } else {
      assemble("push " 0)
  }
  assemble("push " argc)
  assemble("call main")
  assemble("exit a")
  ARGC = 2
}

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

function assemble(instr) {
  n = split(instr, DECODE);
  ins = trim(DECODE[1])
  dst_mode = trim(demode(trim(DECODE[2])))
  src_mode = trim(demode(trim(DECODE[3])))

  MEM[dot++] = sprintf("%-12s %12s %12s", ins dst_mode src_mode, trim(DECODE[2]), trim(DECODE[3]))
}

/^ *assert +/ { $0 = "ass " $2 " " $3 }
/^ *inc +/ { $0 = "add " $2 " " 1 }
/^ *dec +/ { $0 = "add " $2 " " (-1) }

{ assemble($0) }

function decode(field, reg, label, n, indirect) {
  if ( field == "." ) {
    return dot
  }

  reg = REGS[field]
  if ( reg != "" ) {
    return reg;
  }

  label = LABEL[field]
  if ( label != "") {
    return label;
  }

  if ( field ~ /\[[a-z]+\]/ ) {
    gsub(/[[\]]/, "", field)
    field = decode(field)

    if ( REGS[field] != "" ) {
      return REG[decode(field)]
    } else {
      return field
    }
  }

  if ( field ~ /[a-z]+[-+]/ ) {
    gsub(/[[\]]/, "", field)
    gsub(/[+-]/, " &", field)
    n = split(field, indirect)

    n = REG[decode(trim(indirect[1]))] + indirect[2]
    return n
  }

  return field + 0
}

function demode(field, reg, label, n, indirect) {
  if ( field == "" ) {
    return ""
  }

  reg = REG[field]
  if ( reg != "") {
    return "-reg";
  }

  if ( field ~ /\[.*\]/ ) {
    return "-mem"
  }

  return "-imm"
}

function show(instr) {
    print sprintf("  a: %8s      fp: %8s", REG["a"], REG["fp"])
    print sprintf("  b: %8s      sp: %8s", REG["b"], REG["sp"])
    print sprintf("  c: %8s      ip: %8s", REG["c"], ip)
    print sprintf("  d: %8s      eq: %8s", REG["d"], equal)
    print ""
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
          printf("%6s: %12s %12s\n", i, LL[i], MEM[i])
      }
      if ( MEM[i] != "" ) {
          prev = 1
      } else {
          prev = 0
      }
  }
  print ""
}

function exec(instr, n, dst, src) {
  n = split(instr, DECODE);
  ins = trim(DECODE[1])
  dst = decode(trim(DECODE[2]))
  src = decode(trim(DECODE[3]))

  if ( trace_inst == 1 ) {
    print "EXEC", ip, instr, ":", dst, ", "  src > "/dev/stderr"
  }

  if ( ins == "mov-reg-imm" ) { REG[dst] = src; return }
  if ( ins == "mov-reg-reg" ) { REG[dst] = REG[src]; return }
  if ( ins == "mov-reg-mem" ) { REG[dst] = MEM[src]; return }
  if ( ins == "mov-mem-reg" ) { MEM[dst] = REG[src]; return }

  if ( ins == "push-reg" ) { MEM[--REG["sp"]] = REG[dst]; return }
  if ( ins == "push-imm" ) { MEM[--REG["sp"]] = dst; return }
  if ( ins == "pop" ) { REG["sp"]++; return }
  if ( ins == "pop-imm" ) { REG["sp"] += dst; return }
  if ( ins == "pop-reg" ) { REG[dst] = MEM[REG["sp"]++]; return }

  if ( ins == "add-reg-imm" ) { REG[dst] += src; return }
  if ( ins == "sub-reg-imm" ) { REG[dst] -= src; return }
  if ( ins == "mul-reg-imm" ) { REG[dst] *= src; return }
  if ( ins == "div-reg-imm" ) { REG[dst] /= src; REG[dst] = int(REG[dst]); return }
  if ( ins == "cmp-reg-imm" ) { 
    if ( REG[dst] - src == 0 ) {
      equal = 1
    } else {
      equal = 0
    }
    return
  }

  if ( ins == "add-reg-reg" ) { REG[dst] += REG[src]; return }
  if ( ins == "sub-reg-reg" ) { REG[dst] -= REG[src]; return }
  if ( ins == "mul-reg-reg" ) { REG[dst] *= REG[src]; return }
  if ( ins == "div-reg-reg" ) { REG[dst] /= REG[src]; REG[dst] = int(REG[dst]); return }
  if ( ins == "cmp-reg-reg" ) { 
    if ( REG[dst] - REG[src] == 0 ) {
      equal = 1
    } else {
      equal = 0
    }
    return
  }

  if ( ins == "jmp-imm" ) { ip = dst - 1;  return }
  if ( ins == "je-imm"  ) { if ( equal == 1 ) { ip = dst - 1 }; return }
  if ( ins == "jne-imm" ) { if ( equal == 0 ) { ip = dst - 1 }; return }

  if ( ins == "call-imm" ) { 
      if ( trace_call == 1 ) {
          print instr > "/dev/stderr"
      }
      if ( dst == 0 ) {
          error("Don't call to address 0!")
      }
      MEM[--REG["sp"]] = ip;  ip = dst - 1;  return 
  }
  if ( ins == "ret" ) { ip = MEM[REG["sp"]++];  return }

  if ( ins == "exit" ) { exit(0) }
  if ( ins == "exit-imm" ) { exit(dst) }
  if ( ins == "exit-reg" ) { exit(REG[dst]) }
  if ( ins == "show" ) { show(instr); return }
  if ( ins == "dump" ) { dump(0); return }
  if ( ins == "dump-reg" ) { dump(REG[dst]); return }

  if ( ins == "print-imm" ) { print dst; return }
  if ( ins == "print-reg" ) { print REG[dst]; return }
  if ( ins == "print-mem" ) { print MEM[dst]; return }

  if ( ins == "ass-reg-imm" ) {
    if ( REG[dst] != src ) {
      error("Assert fails: " REG[dst] " != " src " : " instr)
    }
    return 
  }
  if ( ins == "ass-mem-imm" ) {
    if ( MEM[dst] != src ) {
      error("Assert fails: " MEM[dst] " != " src " : " instr)
    }
    return 
  }

  dump(ip - 3, ip + 3)
  error("Ilegal instruciton : " ip " : " ins " \"" instr "\"")
}

END {
  if (ERROR == 1) { exit(1) }

  if ( trace_dump ) { dump(0); exit(0) }
  if ( trace_labl ) {
    for ( label in LABEL ) {
        print label, LABEL[label]
    }
    exit(0)
  }

  ip = LABEL["_start"]

  while ( 1 ) {
    instr = MEM[ip]
    exec(instr)
    ip++
  }
}
