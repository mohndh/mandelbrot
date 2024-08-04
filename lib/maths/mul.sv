import chisel3._
import chisel3.util._
import chisel3.stage.{ChiselStage, ChiselGeneratorAnnotation}


class mul(val width: Int = 8, val fbits: Int = 4) extends Module {
  val ibits = width - fbits
  val msb = 2 * width - ibits - 1
  val lsb = width - ibits
  val half = (1 << (fbits - 1))

  val io = IO(new Bundle {
    val clk = Input(Clock())
    val rst = Input(Bool())
    val start = Input(Bool())
    val busy = Output(Bool())
    val done = Output(Bool())
    val valid = Output(Bool())
    val ovf = Output(Bool())
    val a = Input(SInt(width.W))
    val b = Input(SInt(width.W))
    val valOut = Output(SInt(width.W))
  })

  val sigDiff = RegInit(false.B)
  val a1 = Reg(SInt(width.W))
  val b1 = Reg(SInt(width.W))
  val prodT = Reg(SInt(width.W))
  val prod = Reg(SInt((2 * width).W))
  val rbits = Reg(UInt(fbits.W))
  val round = RegInit(false.B)
  val even = RegInit(false.B)

  val idle :: calc :: trunc :: roundState :: Nil = Enum(4)
  val state = RegInit(idle)

  io.done := false.B
  io.busy := false.B
  io.valid := false.B
  io.ovf := false.B
  io.valOut := 0.S

  switch(state) {
    is(idle) {
      when(io.start) {
        state := calc
        a1 := io.a
        b1 := io.b
        sigDiff := io.a(width - 1) ^ io.b(width - 1)
        io.busy := true.B
      }
    }
    is(calc) {
      state := trunc
      prod := a1 * b1
    }
    is(trunc) {
      state := roundState
      prodT := prod(msb, lsb)
      rbits := prod(fbits - 1, 0)
      round := prod(fbits)
      even := !prod(fbits + 1)
    }
    is(roundState) {
      state := idle
      io.busy := false.B
      io.done := true.B

      // Gaussian rounding
      io.valOut := Mux(round && !(even && rbits === half.U), prodT + 1.S, prodT)

      // Overflow
      when(sigDiff === prodT(width - 1) && (prod(2 * width - 1, msb + 1) === 0.U || prod(2 * width - 1, msb + 1) === 1.U)) {
        io.valid := true.B
        io.ovf := false.B
      } .otherwise {
        io.valid := false.B
        io.ovf := true.B
      }
    }
  }

  when(io.rst) {
    state := idle
    io.busy := false.B
    io.done := false.B
    io.valid := false.B
    io.ovf := false.B
    io.valOut := 0.S
  }
}

/*object mul extends App {
  chisel3.Driver.execute(args, () => new mul())
}*/
object mul extends App {
  (new ChiselStage).execute(
    Array[String]("--target-dir", "generated"),
    Seq(ChiselGeneratorAnnotation(() => new mul))
  )
}
