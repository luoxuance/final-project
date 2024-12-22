module monitor(
    input clk,
    input rst,
    input [59:0] text_buffer_in_line,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    );
    reg [9:0] font_rom[35:0][9:0];

    wire clk_25MHz;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480


    clock_divider clk_wiz_0_inst(
        .clk(clk),
        .clk1(clk_25MHz)
    );

    pixel_gen pixel_gen_inst(
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .valid(valid),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

    vga_controller   vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
endmodule
