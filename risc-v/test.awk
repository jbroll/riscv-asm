
function assertEQ(a, b, message, fmt) {
    if ( a != b ) {
      if ( fmt == "" ) {
          fmt = "%s"
      }
      error(sprintf("Assert fails: " fmt " != " fmt " : " message, a, b))
    }
}

BEGIN {
    initAsm()

    assertEQ(rd("x0" ), 0)
    assertEQ(rd("x1" ), 0x00000080, "rd", "0x%08x")
    assertEQ(rd("x31"), 0x00000f80, "rd", "0x%08x")

    assertEQ(rs1("x0" ), 0)
    assertEQ(rs1("x1" ), 0x00008000, "rs1", "0x%08x")
    assertEQ(rs1("x31"), 0x000f8000, "rs1", "0x%08x")

    assertEQ(rs2("x0" ), 0)
    assertEQ(rs2("x1" ), 0x00100000, "rs2", "0x%08x")
    assertEQ(rs2("x31"), 0x01f00000, "rs2", "0x%08x")

    assertEQ(imm12(    0), 0)
    assertEQ(imm12(    1), 0x00100000, "imm12 1", "0x%08x")
    assertEQ(imm12(0xfff), 0xfff00000, "imm12 fff", "0x%08x")
    assertEQ(and(imm12(-1), 0xffffffff), 0xfff00000, "imm12 -1", "0x%08x")

    assertEQ(bimm12(     0), 0)
    assertEQ(bimm12(     1), 0x00000000, "bimm12 1", "0x%08x")
    assertEQ(bimm12(     2), 0x00000100, "bimm12 2", "0x%08x")
    assertEQ(bimm12(0x1000), 0x80000000, "bimm12 sign", "0x%08x")
    assertEQ(bimm12(0x0800), 0x00000080, "bimm12 top", "0x%08x")
    assertEQ(bimm12(0x07c0), 0x7c000000, "bimm12 hi", "0x%08x")
    assertEQ(bimm12(0x001e), 0x00000f00, "bimm12 lo", "0x%08x")

    assertEQ(simm12(     0), 0)
    assertEQ(simm12(     1), 0x00000080, "simm12 1", "0x%08x")
    assertEQ(simm12(     2), 0x00000100, "simm12 2", "0x%08x")
    assertEQ(simm12(0x001f), 0x00000f80, "bimm12 lo", "0x%08x")
    assertEQ(simm12(0x0fe0), 0xfe000000, "bimm12 hi", "0x%08x")

    assertEQ(imm20(      0), 0)
    assertEQ(imm20(      1), 0x00001000, "imm20 1", "0x%08x")
    assertEQ(imm20(0xfffff), 0xfffff000, "imm20 fff", "0x%08x")

    assertEQ(jimm20(0), 0)
    assertEQ(jimm20(1), 0)
    assertEQ(jimm20(0x00100000), 0x80000000, "jimm20 sign", "0x%08x")
    assertEQ(jimm20(0x000ff000), 0x000ff000, "jimm20 hi", "0x%08x")
    assertEQ(jimm20(0x00000800), 0x00100000, "jimm20 11", "0x%08x")
    assertEQ(jimm20(0x000007fe), 0x7fe00000, "jimm20 lo", "0x%08x")
    assertEQ(jimm20(0x001ffffe), 0xfffff000, "jimm20 fff", "0x%08x")

    assertEQ(register("zero"), 0)
    assertEQ(register("ra"), 1)
    assertEQ(register("t6"), 31)

    assertEQ(register("x0"), 0)
    assertEQ(register("x1"), 1)
    assertEQ(register("x31"), 31)
    assertEQ(register("a1"), 11)

    print "Tested OK"
    exit
}

