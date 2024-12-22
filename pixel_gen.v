module pixel_gen(
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input valid,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
    );
    parameter big_height = 100;
    parameter big_width = 480;
    parameter small_height = 60;
    parameter small_width = 440;
    parameter center_x = 320;
    parameter center_y = 360;
    always @(*) begin
        if(!valid)
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
        else if(h_cnt > center_x - small_width / 2 &&
                    h_cnt < center_x + small_width / 2 &&
                    v_cnt > center_y - small_height / 2 &&
                    v_cnt < center_y + small_height / 2)
            {vgaRed, vgaGreen, vgaBlue} = 12'hfff;
        else if(h_cnt > center_x - big_width / 2 &&
                    h_cnt < center_x + big_width / 2 &&
                    v_cnt > center_y - big_height / 2 &&
                    v_cnt < center_y + big_height / 2)
            {vgaRed, vgaGreen, vgaBlue} = 12'h00f;
        else if(h_cnt < center_x - big_width / 2 ||
                    h_cnt > center_x + big_width / 2 ||
                    v_cnt < center_y - big_height / 2 ||
                    v_cnt > center_y + big_height / 2)
            {vgaRed, vgaGreen, vgaBlue} = 12'hfff;
        else
            {vgaRed, vgaGreen, vgaBlue} = 12'h0;
    end
endmodule
