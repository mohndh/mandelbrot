// Project F: Fixed-Point Mandelbrot Set
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/mandelbrot-set-verilog/

// Is (re,im) in the Mandelbrot set?

`default_nettype none
`timescale 1ns / 1ps

module mandelbrot #(
    parameter ITERW=$clog2(256)  // maximum iteration width (bits)
    ) (
    input  wire logic clk,    // clock
    input  wire logic rst,    // reset
    input  wire logic start,  // start calculation
    input  wire logic signed [25-1:0] re, im,  // coordinate
    output      logic [ITERW-1:0] iter,  // iterations
    output      logic calculating,  // calculation in progress
    output      logic done  // calculation complete (high for one tick)
    );

  wire        _mulModule_io_done;
  wire [24:0] _mulModule_io_valOut;
  reg  [24:0] x0;
  reg  [24:0] y0;
  reg  [24:0] x2;
  reg  [24:0] y2;
  reg  [24:0] x;
  reg  [24:0] y;
  reg  [24:0] mulA;
  reg  [24:0] mulB;
  reg  [24:0] mulValP;
  reg         mulStart;
  reg  [24:0] xt;
  reg  [24:0] xy2;
  reg  [2:0]  state;
  reg  [7:0]  io_iter;
  reg         io_calculating;
  reg         io_done;
  always @(posedge clk) begin
    automatic logic             _GEN;
    automatic logic             _GEN_0;
    automatic logic             _GEN_1;
    automatic logic             _GEN_2;
    automatic logic             _GEN_3;
    automatic logic             _GEN_4;
    automatic logic             _GEN_5;
    automatic logic             _GEN_6;
    automatic logic             _GEN_7;
    automatic logic             _GEN_8;
    automatic logic [24:0]      _GEN_9;
    automatic logic [24:0]      _GEN_10;
    automatic logic [7:0][24:0] _GEN_11;
    automatic logic [7:0][24:0] _GEN_12;
    _GEN = state == 3'h0;
    _GEN_0 = state == 3'h1;
      _GEN_1 = $signed(xy2[24:21]) < 4'sh5 & io_iter != 8'hFF;
    _GEN_2 = state == 3'h2;
    _GEN_3 = _GEN_2 & _mulModule_io_done;
    _GEN_4 = state == 3'h3;
    _GEN_5 = state == 3'h4;
    _GEN_6 = state == 3'h5;
    _GEN_7 = _GEN_6 & _mulModule_io_done;
    _GEN_8 = _GEN_0 | _GEN_2 | _GEN_4 | _GEN_5 | ~_GEN_7;
    _GEN_9 = _GEN_8 ? y2 : _mulModule_io_valOut;
    _GEN_10 = _GEN_8 ? xy2 : x2 + _mulModule_io_valOut;
    if (_GEN & start) begin
      x0 <= re;
      y0 <= im;
    end
    if (_GEN) begin
      if (start) begin
        x2 <= 25'h0;
        x <= 25'h0;
        y <= 25'h0;
        xt <= 25'h0;
      end
    end
    else begin
      automatic logic _GEN_13;
      _GEN_13 = _GEN_5 & _mulModule_io_done;
      if (_GEN_0 | _GEN_2 | _GEN_4 | ~_GEN_13) begin
      end
      else
        x2 <= _mulModule_io_valOut;
      if (_GEN_0 | _GEN_2 | ~_GEN_4) begin
      end
      else begin
        x <= xt;
        y <= {mulValP[23:0], 1'h0} + y0;
      end
      if (_GEN_0) begin
        if (_GEN_1) begin
          mulA <= x;
          mulB <= y;
        end
        mulStart <= _GEN_1 | mulStart;
      end
      else begin
        if (~_GEN_2) begin
          if (_GEN_4) begin
            mulA <= xt;
            mulB <= xt;
          end
          else if (_GEN_13) begin
            mulA <= y;
            mulB <= y;
          end
        end
        mulStart <=
          ~_GEN_2 & (_GEN_4 | (_GEN_5 ? _mulModule_io_done : ~_GEN_6 & mulStart));
      end
      if (_GEN_0 | ~_GEN_3) begin
      end
      else
        xt <= x2 - y2 + x0;
    end
    _GEN_11 =
      {{_GEN_9}, {_GEN_9}, {_GEN_9}, {y2}, {y2}, {y2}, {y2}, {start ? 25'h0 : y2}};
    y2 <= _GEN_11[state];
    if (_GEN | _GEN_0 | ~_GEN_3) begin
    end
    else
      mulValP <= _mulModule_io_valOut;
    _GEN_12 =
      {{_GEN_10},
       {_GEN_10},
       {_GEN_10},
       {xy2},
       {xy2},
       {xy2},
       {xy2},
       {start ? 25'h0 : xy2}};
    xy2 <= _GEN_12[state];
    if (rst) begin
      state <= 3'h0;
      io_iter <= 8'h0;
      io_calculating <= 1'h0;
      io_done <= 1'h0;
    end
    else begin
      automatic logic [2:0]      _GEN_14;
      automatic logic [7:0]      _GEN_15;
      automatic logic [7:0][2:0] _GEN_16;
      automatic logic [7:0][7:0] _GEN_17;
      _GEN_14 = _GEN_7 ? 3'h1 : state;
      _GEN_15 = _GEN_8 ? io_iter : io_iter + 8'h1;
      _GEN_16 =
        {{_GEN_14},
         {_GEN_14},
         {_GEN_14},
         {_mulModule_io_done ? 3'h5 : state},
         {3'h4},
         {_mulModule_io_done ? 3'h3 : state},
         {{1'h0, _GEN_1, 1'h0}},
         {start ? 3'h1 : state}};
      state <= _GEN_16[state];
      _GEN_17 =
        {{_GEN_15},
         {_GEN_15},
         {_GEN_15},
         {io_iter},
         {io_iter},
         {io_iter},
         {io_iter},
         {start ? 8'h0 : io_iter}};
      io_iter <= _GEN_17[state];
      if (_GEN)
        io_calculating <= start | io_calculating;
      else
        io_calculating <= (~_GEN_0 | _GEN_1) & io_calculating;
      if (_GEN | ~_GEN_0) begin
      end
      else
        io_done <= ~_GEN_1;
    end
  end // always @(posedge)
  mul mulModule (
    .clk     (clk),
    .rst     (rst),
    .start  (mulStart),
    .done   (_mulModule_io_done),
    .a      (mulA),
    .b      (mulB),
    .val (_mulModule_io_valOut)
  );
    assign io_iter = iter;
    assign io_calculating = calculating;
    assign io_done = done;
endmodule

