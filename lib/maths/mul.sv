
module mul #() (
    input wire logic clock,    // clock
    input wire logic reset,    // reset
    input wire logic io_start,  // start calculation
    output     logic io_busy,   // calculation in progress
    output     logic io_done,   // calculation is complete (high for one tick)
    output     logic io_valid,  // result is valid
    output     logic io_ovf,    // overflow
    input wire logic signed [24:0] io_a,   // multiplier (factor)
    input wire logic signed [24:0] io_b,   // mutiplicand (factor)
    output     logic signed [24:0] io_valOut  // result value: product
    );

    // for selecting result
    localparam IBITS = 21;
    localparam MSB = 49 - IBITS;
    localparam LSB = 25 - IBITS;

    // for rounding
    localparam HALF = {1'b1, {4-1{1'b0}}};

    logic sig_diff;  // signs difference of inputs
    logic signed [24:0] a1, b1;  // copy of inputs
    logic signed [24:0] prod_t;  // unrounded, truncated product
    logic signed [49:0] prod;  // full product
    logic [3:0] rbits;          // rounding bits
    logic round;  // rounding required
    logic even;   // even number

    // calculation state machine
    enum {IDLE, CALC, TRUNC, ROUND} state;
    always_ff @(posedge clock) begin
        io_done <= 0;
        case (state)
            CALC: begin
                state <= TRUNC;
                prod <= a1 * b1;
            end
            TRUNC: begin
                // need to check for overflow (need to look at MSB)
                state <= ROUND;
                prod_t <= prod[MSB:LSB];
                rbits  <= prod[4-1:0];
                round  <= prod[4-1+:1];
                even  <= ~prod[4+:1];
            end
            ROUND: begin  // round half to even
                state <= IDLE;
                io_busy <= 0;
                io_done <= 1;

                // Gaussian rounding
                io_valOut <= (round && !(even && rbits == HALF)) ? prod_t + 1 : prod_t;

                // overflow
                if (sig_diff == prod_t[24+:1] &&  // compare input and answer sign
                    (prod[49:MSB+1] == '0 || prod[49:MSB+1] == '1)  // overflow bits
                ) begin
                    io_valid <= 1;
                    io_ovf <= 0;
                end else begin
                    io_valid <= 0;
                    io_ovf <= 1;
                end
            end
            default: begin
                if (io_start) begin
                    state <= CALC;
                    a1 <= a;  // register input a
                    b1 <= b;  // register input b
                    sig_diff <= (a[24+:1] ^ b[24+:1]);  // register input sign difference
                    io_busy <= 1;
                    io_ovf <= 0;
                end
            end
        endcase
        if (reset) begin
            state <= IDLE;
            io_busy <= 0;
            io_done <= 0;
            io_valid <= 0;
            io_ovf <= 0;
            io_val <= 0;
        end
    end
endmodule
