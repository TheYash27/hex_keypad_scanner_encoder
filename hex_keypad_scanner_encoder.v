/* Deencout the asserted Row and colsel
        Grayhill 072 Hex Keypad
                                    colsel[0] colsel[1] colsel[2] colsel[3]
        Row[0]                      0       1       2       3
        Row[1]                      4       5       6       7
        Row[2]                      8       9       A       B
        Row[3]                      C       D       E       F
*/

module hex_keypad(
    input clock, reset,
    input [3:0] row,
    input rowsel,
    output reg [3:0] encout,
    output valrowsel,
    output reg [3:0] colsel
);
    
    reg [5:0] exista, nexsta;
    
   // One-hot encoding
    parameter S0 = 6'b000001, 
              S1 = 6'b000010,
              S2 = 6'b000100, 
              S3 = 6'b001000, 
              S4 = 6'b010000, 
              S5 = 6'b100000;
    assign valrowsel = ((exista == S1) || (exista == S2) || (exista == S3) || (exista == S4)) && row;
    always @ (row or colsel)
        case ({row, colsel})
            8'b0001_0001: encout = 0; 
            8'b0001_0010: encout = 1;
            8'b0001_0100: encout = 2; 
            8'b0001_1000: encout = 3;
            8'b0010_0001: encout = 4; 
            8'b0010_0010: encout = 5;
            8'b0010_0100: encout = 6;
            8'b0010_1000: encout = 7;
            8'b0100_0001: encout = 8;
            8'b0100_0010: encout = 9;
            8'b0100_0100: encout = 10;        //A
            8'b0100_1000: encout = 11;        //B
            8'b1000_0001: encout = 12;        //C
            8'b1000_0010: encout = 13;        //D
            8'b1000_0100: encout = 14;        //E
            8'b1000_1000: encout = 15;        //F
            default: encout = 0;                     //Arbitrary choice
        endcase
    always @(posedge clock or posedge reset)
        if (reset) exista <= S0;
        else exista <= nexsta;
    always@ (exista or rowsel or row) begin
        nexsta = exista; colsel = 0;
        case (exista)
            //Assert all colselumns
            S0: begin colsel = 15; if (rowsel) nexsta =S1; end
            //Assert colselumn 0
            S1: begin colsel = 1; if (row) nexsta = S5; else nexsta = S2; end
            //Assert colselumn 1
            S2: begin colsel = 2; if (row) nexsta = S5; else nexsta = S3; end
            // Assert colselumn 2
            S3: begin colsel = 4; if (row) nexsta = S5; else nexsta= S4; end
        // Assert colselumn 3
            S4: begin colsel = 8; if (row) nexsta = S5; else nexsta = S0; end
            // Assert all rows
            S5: begin colsel = 15; if (row ==0) nexsta = S0; end
        endcase
    end
endmodule

module actrowsel(                                                //Scans for row of the asserted key
    input [15:0] key,
    input [3:0] colsel,
    output reg [3:0] row
);
    
    always @(key or colsel) begin                                  //Combinational logic for key assertion
        row[0] =  (key[0] && colsel[0]) || (key[1] && colsel[1]) || (key[2] && colsel[2]) || (key[3] && colsel[3]);
        row[1] =  (key[4] && colsel[0]) || (key[5] && colsel[1]) || (key[6] && colsel[2]) || (key[7] && colsel[3]);
        row[2] =  (key[8] && colsel[0]) || (key[9] && colsel[1]) || (key[10] && colsel[2]) || (key[11] && colsel[3]);
        row[3] =  (key[12] && colsel[0]) || (key[13] && colsel[1]) || (key[14] && colsel[2]) || (key[15] && colsel[3]);
    end
endmodule

module synchronizer(
    input clock,
    input reset,
    input [3:0] row,
    output reg rowsel
);
    
    reg actrowsig;
    
    always @(negedge clock or posedge reset) begin
        if (reset) begin 
            actrowsig <= 0;
            rowsel <= 0;
        end
        else begin 
            actrowsig <= (row[0] || row[1] || row[2] || row[3]);
            rowsel <= actrowsig;
        end 
    end    
endmodule

module Hex_Keypad_Scanner_Encoder_Test_Bench ();
    wire [3:0] encout;
    wire valrowsel;
    wire [3:0] colsel;
    wire [3:0] row;
    reg  clock, reset;
    reg  [15:0] key;
    reg  [39:0] pressed;
    parameter  [39:0] key_0 = "Key_0";
    parameter  [39:0] key_1 = "Key_1";
    parameter  [39:0] key_2 = "Key_2";
    parameter  [39:0] key_3 = "Key_3";
    parameter  [39:0] key_4 = "Key_4";
    parameter  [39:0] key_5 = "Key_5";
    parameter  [39:0] key_6 = "Key_6";
    parameter  [39:0] key_7 = "Key_7";
    parameter  [39:0] key_8 = "Key_8";
    parameter  [39:0] key_9 = "Key_9";
    parameter  [39:0] key_A = "Key_A"; 
    parameter  [39:0] key_B = "Key_B";
    parameter  [39:0] key_C = "Key_C"; 
    parameter  [39:0] key_D = "Key_D"; 
    parameter  [39:0] key_E = "Key_E";
    parameter  [39:0] key_F = "Key_F";
    parameter  [39:0] None = "None";
    integer j, k;
    always @(key) begin                                                   // "one-hot" encout for pressed key
        case (key)
            16'h0000: pressed = None;
            16'h0001: pressed = key_0;              //Key = 0000 0000 0000 0001
            16'h0002: pressed = key_1;              //Key = 0000 0000 0000 0010
            16'h0004: pressed = key_2;              //Key = 0000 0000 0000 0100
            16'h0008: pressed = key_3;              //Key = 0000 0000 0000 1000
            16'h0010: pressed = key_4;
            16'h0020: pressed = key_5;
            16'h0040: pressed = key_6;
            16'h0080: pressed = key_7;
            16'h0100: pressed = key_8;
            16'h0200: pressed = key_9;
            16'h0400: pressed = key_A;
            16'h0800: pressed = key_B;
            16'h1000: pressed = key_C;
            16'h2000: pressed = key_D;
            16'h4000: pressed = key_E;
            16'h8000: pressed = key_F;
            default: pressed = None;
        endcase
    end

    hex_keypad M1(clock, reset, row, rowsel, encout, valrowsel, colsel);
    actrowsel M2(key, colsel, row);
    synchronizer M3(clock, reset, row, rowsel);
    
    initial #2000 $finish;
    initial begin
        clock = 0; 
        forever #5 clock = ~clock; 
    end
    initial begin 
        reset = 1; 
        #10 reset = 0; 
    end
    initial begin 
        for (k = 0; k <= 1; k = (k + 1)) begin 
            key = 0;
            #20 for (j = 0; j <= 16; j = (j + 1)) begin
                #20 key[j] = 1; 
                #60 key = 0; 
            end 
        end 
    end
endmodule