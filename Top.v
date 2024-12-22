module Top(
    input wire clk,
    input wire rst,
    input wire start,//btn r
    input wire ennd,//btn l
    input wire up,//btn u
    input wire down,//btn d
    input wire [11:0] sw,//month
    inout wire PS2_CLK,
    inout wire PS2_DATA,
    //output wire [15:0] led,//test
    output reg [6:0] DISPLAY,
	output reg [3:0] DIGIT,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    );
    reg [2:0] state, next_state;
    parameter INITIAL=0, SETTING=1, TYPING=2, CHECKING=3, FINISH=4;
    
    /*INITIAL:在螢幕上顯示如何操作等介紹，按下start進入SETTING
    SETTING:控制年份月份，按下start進入TYPING
    TYPING:輸入發票號碼，按下ENTER進入CHECKING，按下start進入SETTING
    CHECKING:比對完將結果顯示在螢幕並撥放音樂，撥放完進入TYPING。按下ennd進入FNISH。
    FINISH:顯示所有的結果並統計。按下start進入INITIAL。*/

    //debounce and onepulse btn
    wire start_de, ennd_de, up_de, down_de;
    wire start_op, ennd_op, up_op, down_op;
    debounce inst1(.clk(clk), .pb(start), .pb_debounced(start_de));
    debounce inst2(.clk(clk), .pb(ennd), .pb_debounced(ennd_de));
    debounce inst3(.clk(clk), .pb(up), .pb_debounced(up_de));
    debounce inst4(.clk(clk), .pb(down), .pb_debounced(down_de));
    one_pulse inst5(.clk(clk), .pb_in(start_de), .pb_out(start_op));
    one_pulse inst6(.clk(clk), .pb_in(ennd_de), .pb_out(ennd_op));
    one_pulse inst7(.clk(clk), .pb_in(up_de), .pb_out(up_op));
    one_pulse inst8(.clk(clk), .pb_in(down_de), .pb_out(down_op));
    //keyboard decoder instance
    parameter [8:0] ENTER_CODES = 9'b0_0101_1010;//5A
    parameter [8:0] BACKSPACE_CODES = 9'b0_0110_0110;//66
    parameter [8:0] NUMBER_KEY_CODES [0:19] = {
		9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
		9'b0_0111_0000, // right_0 => 70
		9'b0_0110_1001, // right_1 => 69
		9'b0_0111_0010, // right_2 => 72
		9'b0_0111_1010, // right_3 => 7A
		9'b0_0110_1011, // right_4 => 6B
		9'b0_0111_0011, // right_5 => 73
		9'b0_0111_0100, // right_6 => 74
		9'b0_0110_1100, // right_7 => 6C
		9'b0_0111_0101, // right_8 => 75
		9'b0_0111_1101  // right_9 => 7D
	};
	parameter [8:0] CHAR_KEY_CODES [0:25] = {
		9'b0_0001_1100,//A => 1C
		9'b0_0011_0010,//B => 32
		9'b0_0010_0001,//C => 21
		9'b0_0010_0011,//D => 23
		9'b0_0010_0100,//E => 24
		9'b0_0010_1011,//F => 2B
		9'b0_0011_0100,//G => 34
		9'b0_0011_0011,//H => 33
		9'b0_0100_0011,//I => 43
		9'b0_0011_1011,//J => 3B
		9'b0_0100_0010,//K => 42
		9'b0_0100_1011,//L => 4B
		9'b0_0011_1010,//M => 3A
		9'b0_0011_0001,//N => 31
		9'b0_0100_0100,//O => 44
		9'b0_0100_1101,//P => 4D
		9'b0_0001_1001,//Q => 15
		9'b0_0010_1101,//R => 2D
		9'b0_0001_1011,//S => 1B
		9'b0_0010_1100,//T => 2C
		9'b0_0011_1100,//U => 3C
		9'b0_0010_1010,//V => 2A
		9'b0_0001_1101,//W => 1D
		9'b0_0010_0010,//X => 22
		9'b0_0011_1001,//Y => 35
		9'b0_0001_1010//Z => 1A
	};
    //is one key
    integer i;
	reg [8:0] count_keys;
	reg is_one_key;
	always@(*)begin
		count_keys=0;
		for(i=0;i<512;i=i+1)begin 
			count_keys=count_keys+key_down[i];
		end
		is_one_key=(count_keys==1);
	end

	reg [5:0] key;
	reg [5:0] last_key;

    wire enter_down;
    wire backspace_down;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
    wire been_break;
    assign enter_down = (key_down[ENTER_CODES] == 1'b1) ? 1'b1 : 1'b0;
    assign backspace_down = (key_down[BACKSPACE_CODES] == 1'b1) ? 1'b1 : 1'b0;

    KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
        .wire_been_break(been_break),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
    // 9  8  -  7  6  5  4  3  2  1  0
    // X  X  -  
    reg [3:0] text_buffer [0:5];//0~9 are numbers, 10~35 are chars
    reg [3:0] cursor_pos = 9;//show cursor
    always @(posedge clk, posedge rst)begin 
        if(rst)begin 
            text_buffer[0] <= 6'b00_0000;
            text_buffer[1] <= 6'b00_0000;
            text_buffer[2] <= 6'b00_0000;
            text_buffer[3] <= 6'b00_0000;
            text_buffer[4] <= 6'b00_0000;
            text_buffer[5] <= 6'b00_0000;
            text_buffer[6] <= 6'b00_0000;
            text_buffer[7] <= 6'b00_0000;
            text_buffer[8] <= 6'b00_0000;
            text_buffer[9] <= 6'b00_0000;
            cursor_pos <= 4'b1001;
            last_key <= 6'b11_1111;
        end else if(state == TYPING) begin 
            text_buffer[0] <= text_buffer[0];
            text_buffer[1] <= text_buffer[1];
            text_buffer[2] <= text_buffer[2];
            text_buffer[3] <= text_buffer[3];
            text_buffer[4] <= text_buffer[4];
            text_buffer[5] <= text_buffer[5];
            text_buffer[6] <= text_buffer[6];
            text_buffer[7] <= text_buffer[7];
            text_buffer[8] <= text_buffer[8];
            text_buffer[9] <= text_buffer[9];

            if(been_break) last_key <= 6'b11_1111;

            if(been_ready && key_down[last_change] == 1'b1)begin 
                if(key != 6'b11_1111 && is_one_key)begin 
                    if(key != last_key && cursor_pos > 0)begin
                        last_key <= key;
                        text_buffer[cursor_pos - 1] <= key;
                        cursor_pos <= cursor_pos - 1;
                    end
                end
            end else if(been_ready && backspace_down && cursor_pos < 10)begin 
                text_buffer[cursor_pos] <= 6'b00_0000;
                cursor_pos <= cursor_pos + 1;
            end
        end
    end
    always @ (*) begin
        case (last_change)
            NUMBER_KEY_CODES[00] : key = 6'b00_0000;
            NUMBER_KEY_CODES[01] : key = 6'b00_0001;
            NUMBER_KEY_CODES[02] : key = 6'b00_0010;
            NUMBER_KEY_CODES[03] : key = 6'b00_0011;
            NUMBER_KEY_CODES[04] : key = 6'b00_0100;
            NUMBER_KEY_CODES[05] : key = 6'b00_0101;
            NUMBER_KEY_CODES[06] : key = 6'b00_0110;
            NUMBER_KEY_CODES[07] : key = 6'b00_0111;
            NUMBER_KEY_CODES[08] : key = 6'b00_1000;
            NUMBER_KEY_CODES[09] : key = 6'b00_1001;
            NUMBER_KEY_CODES[10] : key = 6'b00_0000;
            NUMBER_KEY_CODES[11] : key = 6'b00_0001;
            NUMBER_KEY_CODES[12] : key = 6'b00_0010;
            NUMBER_KEY_CODES[13] : key = 6'b00_0011;
            NUMBER_KEY_CODES[14] : key = 6'b00_0100;
            NUMBER_KEY_CODES[15] : key = 6'b00_0101;
            NUMBER_KEY_CODES[16] : key = 6'b00_0110;
            NUMBER_KEY_CODES[17] : key = 6'b00_0111;
            NUMBER_KEY_CODES[18] : key = 6'b00_1000;
            NUMBER_KEY_CODES[19] : key = 6'b00_1001;
            CHAR_KEY_CODES[00] : key = 6'b00_1010;
            CHAR_KEY_CODES[01] : key = 6'b00_1011;
            CHAR_KEY_CODES[02] : key = 6'b00_1100;
            CHAR_KEY_CODES[03] : key = 6'b00_1101;
            CHAR_KEY_CODES[04] : key = 6'b00_1110;
            CHAR_KEY_CODES[05] : key = 6'b00_1111;
            CHAR_KEY_CODES[06] : key = 6'b01_0000;
            CHAR_KEY_CODES[07] : key = 6'b01_0001;
            CHAR_KEY_CODES[08] : key = 6'b01_0010;
            CHAR_KEY_CODES[09] : key = 6'b01_0011;
            CHAR_KEY_CODES[10] : key = 6'b01_0100;
            CHAR_KEY_CODES[11] : key = 6'b01_0101;
            CHAR_KEY_CODES[12] : key = 6'b01_0110;
            CHAR_KEY_CODES[13] : key = 6'b01_0111;
            CHAR_KEY_CODES[14] : key = 6'b01_1000;
            CHAR_KEY_CODES[15] : key = 6'b01_1001;
            CHAR_KEY_CODES[16] : key = 6'b01_1010;
            CHAR_KEY_CODES[17] : key = 6'b01_1011;
            CHAR_KEY_CODES[18] : key = 6'b01_1100;
            CHAR_KEY_CODES[19] : key = 6'b01_1101;
            CHAR_KEY_CODES[20] : key = 6'b01_1110;
            CHAR_KEY_CODES[21] : key = 6'b01_1111;
            CHAR_KEY_CODES[22] : key = 6'b10_0000;
            CHAR_KEY_CODES[23] : key = 6'b10_0001;
            CHAR_KEY_CODES[24] : key = 6'b10_0010;
            CHAR_KEY_CODES[25] : key = 6'b10_0011;
            default : key = 6'b11_1111;
        endcase
    end
    //Monitor output
    reg [59:0] text_buffer_in_line;
    always@(*)begin 
        text_buffer_in_line[5:0] = text_buffer[0];
        text_buffer_in_line[11:6] = text_buffer[1];
        text_buffer_in_line[17:12] = text_buffer[2];
        text_buffer_in_line[23:18] = text_buffer[3];
        text_buffer_in_line[29:24] = text_buffer[4];
        text_buffer_in_line[35:30] = text_buffer[5];
        text_buffer_in_line[41:36] = text_buffer[6];
        text_buffer_in_line[47:42] = text_buffer[7];
        text_buffer_in_line[53:48] = text_buffer[8];
        text_buffer_in_line[59:54] = text_buffer[9];
    end
    monitor inst9(.clk(clk), .rst(rst), .text_buffer_in_line(text_buffer_in_line), .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),  .hsync(hsync), .vsync(vsync));
    //TODO:output 7-seg
    //TODO:output music
    //FSM
    always@(posedge clk)begin 
        if(rst)state<=INITIAL;
        else state<=next_state;
    end
    always@(*)begin 
        next_state=state;
        case(state)
            INITIAL:begin 
                if(start_op) next_state = SETTING;
            end
            SETTING:begin 
                if(start_op) next_state = TYPING;
                if(ennd_op) next_state = FINISH;
            end
            TYPING:begin 
                if(enter_down) next_state = CHECKING;
                if(start_op) next_state = SETTING;
                if(ennd_op) next_state = FINISH;
            end
            CHECKING:begin 
                //if(/*showing results ends*/) next_state = TYPING;
                if(ennd_op) next_state = FINISH;
            end
            FINISH:begin 
                if(start_op) next_state = INITIAL;
            end
        endcase
    end
    //assign led = state;
endmodule
