def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return (
        (funct7 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | opcode
    )

def i_type(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF

    return (
        (imm << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | opcode
    )

def s_type(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF

    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F

    return (
        (imm11_5 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (imm4_0 << 7)
        | opcode
    )

def b_type(imm, rs2, rs1, funct3, opcode):
    imm &= 0x1FFF

    imm12   = (imm >> 12) & 0x1
    imm11   = (imm >> 11) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1  = (imm >> 1) & 0xF

    return (
        (imm12 << 31)
        | (imm10_5 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (imm4_1 << 8)
        | (imm11 << 7)
        | opcode
    )

def j_type(imm, rd, opcode):
    imm &= 0x1FFFFF

    imm20 = (imm >> 20) & 1
    imm19_12 = (imm >> 12) & 0xFF
    imm11 = (imm >> 11) & 1
    imm10_1 = (imm >> 1) & 0x3FF

    return (
        (imm20 << 31)
        | (imm19_12 << 12)
        | (imm11 << 20)
        | (imm10_1 << 21)
        | (rd << 7)
        | opcode
    )

def c_addi(rd, imm):

    rd = reg(rd)

    if rd == 0:
        raise Exception("rd cannot be x0")

    if imm < -32 or imm > 31:
        raise Exception("Immediate out of range")

    imm &= 0x3F

    instr = 0

    instr |= 0b01
    instr |= rd << 7
    instr |= (imm & 0x1F) << 2
    instr |= ((imm >> 5) & 1) << 12
    instr |= 0b000 << 13

    return instr

def c_li(rd, imm):

    rd = reg(rd)

    if rd == 0:
        raise Exception("c.li requires rd != x0")

    if imm < -32 or imm > 31:
        raise Exception("Immediate out of range")

    imm &= 0x3F

    return (
        (0b010 << 13) |
        (((imm >> 5) & 1) << 12) |
        (rd << 7) |
        ((imm & 0x1F) << 2) |
        0b01
    )

def c_lui(rd, imm):

    rd = reg(rd)

    if rd == 0:
        raise Exception("c.lui rd cannot be x0")

    if rd == 2:
        raise Exception("Use c.addi16sp")

    if imm == 0:
        raise Exception("Immediate cannot be zero")

    if imm < -32 or imm > 31:
        raise Exception("Immediate out of range")

    imm &= 0x3F

    return (
        (0b011 << 13) |
        (((imm >> 5) & 1) << 12) |
        (rd << 7) |
        ((imm & 0x1F) << 2) |
        0b01
    )

def c_addi16sp(imm):

    if imm == 0:
        raise Exception("Immediate cannot be zero")

    if imm % 16 != 0:
        raise Exception("Immediate must be multiple of 16")

    if imm < -512 or imm > 496:
        raise Exception("Immediate out of range")

    imm &= 0x3FF

    instr = 0

    instr |= 0b011 << 13
    instr |= 2 << 7          # rd = x2
    instr |= 0b01

    # immediate
    instr |= ((imm >> 9) & 1) << 12
    instr |= ((imm >> 4) & 1) << 6
    instr |= ((imm >> 6) & 1) << 5
    instr |= ((imm >> 8) & 1) << 4
    instr |= ((imm >> 7) & 1) << 3
    instr |= ((imm >> 5) & 1) << 2

    return instr

def c_addi4spn(rd, imm):

    rd = creg(rd)

    if imm == 0:
        raise Exception("Immediate cannot be zero")

    if imm % 4 != 0:
        raise Exception("Immediate must be word aligned")

    if imm < 0 or imm > 1020:
        raise Exception("Immediate out of range")

    instr = 0

    instr |= 0b000 << 13
    instr |= rd << 2
    instr |= 0b00

    instr |= ((imm >> 9) & 1) << 10
    instr |= ((imm >> 8) & 1) << 9
    instr |= ((imm >> 7) & 1) << 8
    instr |= ((imm >> 6) & 1) << 7

    instr |= ((imm >> 5) & 1) << 12
    instr |= ((imm >> 4) & 1) << 11

    instr |= ((imm >> 3) & 1) << 5
    instr |= ((imm >> 2) & 1) << 6

    return instr

def c_lw(rd, offset, rs1):

    rd = creg(rd)
    rs1 = creg(rs1)

    if offset < 0:
        raise Exception("Offset must be unsigned")

    if offset % 4 != 0:
        raise Exception("Offset must be word aligned")

    instr = 0

    instr |= 0b010 << 13
    instr |= 0b00

    instr |= rs1 << 7
    instr |= rd << 2

    instr |= ((offset >> 5) & 1) << 5
    instr |= ((offset >> 3) & 0b11) << 11
    instr |= ((offset >> 2) & 1) << 10

    return instr

def c_sw(rs2, offset, rs1):

    rs1 = creg(rs1)
    rs2 = creg(rs2)

    if offset < 0:
        raise Exception("Offset must be unsigned")

    if offset % 4 != 0:
        raise Exception("Offset must be word aligned")

    instr = 0

    instr |= 0b110 << 13
    instr |= 0b00

    instr |= rs1 << 7
    instr |= rs2 << 2

    instr |= ((offset >> 5) & 1) << 5
    instr |= ((offset >> 3) & 0b11) << 11
    instr |= ((offset >> 2) & 1) << 10

    return instr

def c_jr(rs1):

    rs1 = reg(rs1)

    if rs1 == 0:
        raise Exception("c.jr requires rs1 != x0")

    instr = 0

    instr |= 0b100 << 13
    instr |= 0b10

    instr |= rs1 << 7

    # rs2 = 0
    # bit12 = 0

    return instr

def c_jalr(rs1):

    rs1 = reg(rs1)

    if rs1 == 0:
        raise Exception("c.jalr requires rs1 != x0")

    instr = 0

    instr |= 0b100 << 13
    instr |= 0b10

    instr |= 1 << 12

    instr |= rs1 << 7

    return instr

def c_j(offset):

    if offset & 1:
        raise Exception("Jump offset must be 2-byte aligned")

    if offset < -2048 or offset > 2046:
        raise Exception("Offset out of range")

    offset &= 0xFFF

    instr = 0

    instr |= 0b101 << 13
    instr |= 0b01

    instr |= ((offset >> 11) & 1) << 12

    instr |= ((offset >> 4) & 1) << 11

    instr |= ((offset >> 8) & 1) << 10
    instr |= ((offset >> 9) & 1) << 9

    instr |= ((offset >> 10) & 1) << 8

    instr |= ((offset >> 6) & 1) << 7

    instr |= ((offset >> 7) & 1) << 6

    instr |= ((offset >> 1) & 0x7) << 3

    instr |= ((offset >> 5) & 1) << 2

    return instr

def c_mv(rd, rs2):

    rd = reg(rd)
    rs2 = reg(rs2)

    if rd == 0:
        raise Exception("rd cannot be x0")

    if rs2 == 0:
        raise Exception("rs2 cannot be x0")

    instr = 0

    instr |= 0b100 << 13
    instr |= 0b10

    instr |= rd << 7
    instr |= rs2 << 2

    return instr

def c_add(rd, rs2):

    rd = reg(rd)
    rs2 = reg(rs2)

    if rd == 0:
        raise Exception("rd cannot be x0")

    if rs2 == 0:
        raise Exception("rs2 cannot be x0")

    instr = 0

    instr |= 0b100 << 13
    instr |= 1 << 12
    instr |= 0b10

    instr |= rd << 7
    instr |= rs2 << 2

    return instr

def c_beqz(rs1, offset):

    rs1 = creg(rs1)

    if offset & 1:
        raise Exception("Branch offset must be 2-byte aligned")

    if offset < -256 or offset > 254:
        raise Exception("Offset out of range")

    offset &= 0x1FF

    instr = 0

    instr |= 0b110 << 13
    instr |= 0b01

    instr |= rs1 << 7

    instr |= ((offset >> 8) & 1) << 12

    instr |= ((offset >> 7) & 1) << 6
    instr |= ((offset >> 6) & 1) << 5

    instr |= ((offset >> 5) & 1) << 2

    instr |= ((offset >> 4) & 1) << 11
    instr |= ((offset >> 3) & 1) << 10

    instr |= ((offset >> 2) & 1) << 4
    instr |= ((offset >> 1) & 1) << 3

    return instr

def c_bnez(rs1, offset):

    rs1 = creg(rs1)

    if offset & 1:
        raise Exception("Branch offset must be 2-byte aligned")

    if offset < -256 or offset > 254:
        raise Exception("Offset out of range")

    offset &= 0x1FF

    instr = 0

    instr |= 0b111 << 13
    instr |= 0b01

    instr |= rs1 << 7

    instr |= ((offset >> 8) & 1) << 12

    instr |= ((offset >> 7) & 1) << 6
    instr |= ((offset >> 6) & 1) << 5

    instr |= ((offset >> 5) & 1) << 2

    instr |= ((offset >> 4) & 1) << 11
    instr |= ((offset >> 3) & 1) << 10

    instr |= ((offset >> 2) & 1) << 4
    instr |= ((offset >> 1) & 1) << 3

    return instr

def c_slli(rd, shamt):

    rd = reg(rd)

    if rd == 0:
        raise Exception("rd cannot be x0")

    if shamt < 0 or shamt > 31:
        raise Exception("Invalid shamt")

    instr = 0

    instr |= 0b000 << 13
    instr |= 0b10

    instr |= rd << 7
    instr |= (shamt & 0x1F) << 2
    instr |= ((shamt >> 5) & 1) << 12

    return instr

def c_srli(rd, shamt):

    rd = creg(rd)

    if shamt < 0 or shamt > 31:
        raise Exception("Invalid shamt")

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7

    instr |= ((shamt >> 5) & 1) << 12
    instr |= (shamt & 0x1F) << 2

    # funct2 = 00
    instr |= 0b00 << 10

    instr |= 0b01

    return instr

def c_srai(rd, shamt):

    rd = creg(rd)

    if shamt < 0 or shamt > 31:
        raise Exception("Invalid shamt")

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7

    instr |= ((shamt >> 5) & 1) << 12
    instr |= (shamt & 0x1F) << 2

    instr |= 0b01 << 10

    instr |= 0b01

    return instr

def c_andi(rd, imm):

    rd = creg(rd)

    if imm < -32 or imm > 31:
        raise Exception("Immediate out of range")

    imm &= 0x3F

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7

    instr |= ((imm >> 5) & 1) << 12
    instr |= (imm & 0x1F) << 2

    instr |= 0b10 << 10

    instr |= 0b01

    return instr

def c_sub(rd, rs2):

    rd = creg(rd)
    rs2 = creg(rs2)

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7
    instr |= rs2 << 2

    instr |= 0b11 << 10
    instr |= 0b00 << 5

    instr |= 0b01

    return instr

def c_xor(rd, rs2):

    rd = creg(rd)
    rs2 = creg(rs2)

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7
    instr |= rs2 << 2

    instr |= 0b11 << 10
    instr |= 0b01 << 5

    instr |= 0b01

    return instr

def c_or(rd, rs2):

    rd = creg(rd)
    rs2 = creg(rs2)

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7
    instr |= rs2 << 2

    instr |= 0b11 << 10
    instr |= 0b10 << 5

    instr |= 0b01

    return instr

def c_and(rd, rs2):

    rd = creg(rd)
    rs2 = creg(rs2)

    instr = 0

    instr |= 0b100 << 13
    instr |= rd << 7
    instr |= rs2 << 2

    instr |= 0b11 << 10
    instr |= 0b11 << 5

    instr |= 0b01

    return instr
def check_creg(r):

    r = reg(r)

    if r < 8 or r > 15:
        raise Exception("Compressed register must be x8-x15")

    return r


def check_signed(value, bits):

    low = -(1 << (bits-1))
    high = (1 << (bits-1)) - 1

    if value < low or value > high:
        raise Exception("Immediate out of range")


def check_unsigned(value, bits):

    if value < 0 or value >= (1 << bits):
        raise Exception("Immediate out of range")

def c_nop():

    return 0x0001

def reg(x):
    return int(x.replace("x", ""))

def creg(x):
    r = reg(x)

    if r < 8 or r > 15:
        raise Exception("Compressed register must be x8-x15")

    return r - 8


assembly = [

    "addi x1, x0, 100",        # Base address = 0
    "addi x2, x0, 128",        # Loop count

    # Loop (exercises load, branch, forwarding, hazard handling)
    "lw   x3, 0(x1)",
    "addi x1, x1, 4",
    "bne x2,x1,-8",

    # RV32M
    "addi x5, x0, 6",
    "addi x6, x0, 7",
    "mul  x7, x5, x6",         # x7 = 6 * 7 = 42

    "addi x8, x0, 20",
    "addi x9, x0, 3",
    "div  x10, x8, x9",        # x10 = 20 / 3  = 6
    "rem  x11, x8, x9",        # x11 = 20 % 3  = 2

    "addi x12, x0, -20",
    "div  x13, x12, x9",       # x13 = -20 / 3 = -6 (truncate toward zero)
    "rem  x14, x12, x9",       # x14 = -20 % 3 = -2 (sign follows dividend)
    "divu x15, x12, x9",       # x15 = unsigned(-20) / 3 = 1431655758
    "mulh x16, x12, x9",       # x16 = upper32(signed(-20) * signed(3)) = 0xFFFFFFFF
]

program = []

def emit16(instr):
    program.append(instr & 0xFFFF)

def emit32(instr):
    program.append(instr & 0xFFFF)
    program.append((instr >> 16) & 0xFFFF)

for line in assembly:

    parts = (
        line.replace(",", " ")
            .replace("(", " ")
            .replace(")", " ")
            .split()
    )

    op = parts[0]

    if op == "addi":
        emit32(
            i_type(
                int(parts[3]),
                reg(parts[2]),
                0b000,
                reg(parts[1]),
                0b0010011
            )
        )

    elif op == "lw":
        emit32(
            i_type(
                int(parts[2]),
                reg(parts[3]),
                0b010,
                reg(parts[1]),
                0b0000011
            )
        )

    elif op == "jalr":
        emit32(
            i_type(
                int(parts[2]),
                reg(parts[3]),
                0b000,
                reg(parts[1]),
                0b1100111
            )
        )

    elif op == "add":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b000,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "sub":
        emit32(
            r_type(
                0b0100000,
                reg(parts[3]),
                reg(parts[2]),
                0b000,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "and":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b111,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "or":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b110,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "xor":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b100,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "slt":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b010,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "sltu":
        emit32(
            r_type(
                0b0000000,
                reg(parts[3]),
                reg(parts[2]),
                0b011,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "mul":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b000,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "mulh":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b001,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "mulhsu":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b010,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "mulhu":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b011,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "div":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b100,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "divu":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b101,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "rem":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b110,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "remu":
        emit32(
            r_type(
                0b0000001,
                reg(parts[3]),
                reg(parts[2]),
                0b111,
                reg(parts[1]),
                0b0110011
            )
        )

    elif op == "sw":
        emit32(
            s_type(
                int(parts[2]),
                reg(parts[1]),
                reg(parts[3]),
                0b010,
                0b0100011
            )
        )
    
    elif op == "beq":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b000,
                0b1100011
            )
        )

    elif op == "bne":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b001,
                0b1100011
            )
        )

    elif op == "blt":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b100,
                0b1100011
            )
        )

    elif op == "bge":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b101,
                0b1100011
            )
        )

    elif op == "bltu":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b110,
                0b1100011
            )
        )

    elif op == "bgeu":

        emit32(
            b_type(
                int(parts[3]),
                reg(parts[2]),
                reg(parts[1]),
                0b111,
                0b1100011
            )
        )
        
    elif op == "jal":

        emit32(
            j_type(
                int(parts[2]),      # immediate
                reg(parts[1]),      # rd
                0b1101111           # opcode
            )
        )

    elif op == "c.nop":

        emit16(
            c_nop()
        )

    elif op == "c.addi":

        emit16(
            c_addi(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.li":

        emit16(
            c_li(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.lui":

        emit16(
            c_lui(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.addi16sp":

        emit16(
            c_addi16sp(
                int(parts[1])
            )
        )

    elif op == "c.addi4spn":

        emit16(
            c_addi4spn(
                parts[1],
                int(parts[2])
            )
        )
    
    elif op == "c.lw":

        emit16(
            c_lw(
                parts[1],
                int(parts[2]),
                parts[3]
            )
        )

    elif op == "c.sw":

        emit16(
            c_sw(
                parts[1],
                int(parts[2]),
                parts[3]
            )
        )

    elif op == "c.jr":

        emit16(
            c_jr(
                parts[1]
            )
        )

    elif op == "c.jalr":

        emit16(
            c_jalr(
                parts[1]
            )
        )

    elif op == "c.j":

        emit16(
            c_j(
                int(parts[1])
            )
        )

    elif op == "c.mv":

        emit16(
            c_mv(
                parts[1],
                parts[2]
            )
        )

    elif op == "c.add":

        emit16(
            c_add(
                parts[1],
                parts[2]
            )
        )

    elif op == "c.beqz":

        emit16(
            c_beqz(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.bnez":

        emit16(
            c_bnez(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.slli":

        emit16(
            c_slli(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.srli":

        emit16(
            c_srli(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.srai":

        emit16(
            c_srai(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.andi":

        emit16(
            c_andi(
                parts[1],
                int(parts[2])
            )
        )

    elif op == "c.sub":

        emit16(
            c_sub(
                parts[1],
                parts[2]
            )
        )

    elif op == "c.xor":

        emit16(
            c_xor(
                parts[1],
                parts[2]
            )
        )

    elif op == "c.or":

        emit16(
            c_or(
                parts[1],
                parts[2]
            )
        )

    elif op == "c.and":

        emit16(
            c_and(
                parts[1],
                parts[2]
            )
        )

    else:
        raise Exception(f"Unsupported instruction: {op}")
    

import os
output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "program.mem")
with open(output_path, "w") as f:
    for instr in program:
        f.write(f"{instr:04x}\n")

print("program.mem generated")