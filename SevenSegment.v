module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit, 
	input wire [6:0] nums,
	input wire rst,
	input wire clk  // Input 100Mhz clock
);
    
    reg [15:0] clk_divider;
    reg [6:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            clk_divider <= 15'b0;
        end else begin
            clk_divider <= clk_divider + 15'b1;
        end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
        if (rst) begin
            display_num <= 7'b1111111;
            digit <= 4'b1111;
        end else begin
            case (digit)
                4'b1110 : begin
                        display_num <= 7'b1111111;
                        digit <= 4'b1101;
                    end
                4'b1101 : begin
						display_num <= 7'b1111111;
						digit <= 4'b1011;
					end
                4'b1011 : begin
						display_num <= 7'b1111111;
						digit <= 4'b0111;
					end
                4'b0111 : begin
						display_num <= nums;
						digit <= 4'b1110;
					end
                default : begin
						display_num <= 7'b1111111;
						digit <= 4'b1110;
					end				
            endcase
        end
    end
    
    always @ (*) begin
        display = display_num;
    end
endmodule