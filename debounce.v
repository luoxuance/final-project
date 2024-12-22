module debounce (
    input wire clk,
    input wire pb,
    output wire pb_debounced
);
    reg [19:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[19:1] <= shift_reg[18:0];
        shift_reg[0] <= pb;
    end
    assign pb_debounced = (shift_reg == 20'b1111) ? 1'b1 : 1'b0;
endmodule