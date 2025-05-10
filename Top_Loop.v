module Top_Loop
  (
   input  i_Clk,        // System clock input
   input  i_UART_RX,    // UART receive line input
   output o_UART_TX,    // UART transmit line output

   // Outputs to the upper digit 7-segment display
   output o_Segment1_A,
   output o_Segment1_B,
   output o_Segment1_C,
   output o_Segment1_D,
   output o_Segment1_E,
   output o_Segment1_F,
   output o_Segment1_G,

   // Outputs to the lower digit 7-segment display
   output o_Segment2_A,
   output o_Segment2_B,
   output o_Segment2_C,
   output o_Segment2_D,
   output o_Segment2_E,
   output o_Segment2_F,
   output o_Segment2_G   
   ); 

  // Internal wires for UART communication
  wire w_RX_DV;            // RX data valid signal
  wire [7:0] w_RX_Byte;    // Received byte
  wire w_TX_Active;        // TX module active signal
  wire w_TX_Serial;        // TX serial data output

  // Internal wires for each segment of both displays
  wire w_Segment1_A, w_Segment2_A;
  wire w_Segment1_B, w_Segment2_B;
  wire w_Segment1_C, w_Segment2_C;
  wire w_Segment1_D, w_Segment2_D;
  wire w_Segment1_E, w_Segment2_E;
  wire w_Segment1_F, w_Segment2_F;
  wire w_Segment1_G, w_Segment2_G;
   
  // UART receiver instantiation with CLKS_PER_BIT = 217 (for 115200 baud @ 25 MHz)
  UART_RX #(.CLKS_PER_BIT(217)) UART_RX_Inst
  (
    .i_Clock(i_Clk),
    .i_RX_Serial(i_UART_RX),
    .o_RX_DV(w_RX_DV),
    .o_RX_Byte(w_RX_Byte)
  );
    
  // UART transmitter instantiation with loopback configuration
  // Transmit received byte immediately after reception
  UART_TX #(.CLKS_PER_BIT(217)) UART_TX_Inst
  (
	.i_Rst_L(1'b1),
    .i_Clock(i_Clk),
    .i_TX_DV(w_RX_DV),
    .i_TX_Byte(w_RX_Byte),
    .o_TX_Active(w_TX_Active),
    .o_TX_Serial(w_TX_Serial),
    .o_TX_Done()
  );
   
  // Output UART line: drive w_TX_Serial when active, else keep line high (idle)
  assign o_UART_TX = w_TX_Active ? w_TX_Serial : 1'b1; 
   
  // Convert upper nibble of received byte to 7-segment format (hex digit)
  Binary_To_7Segment SevenSeg1_Inst
  (
    .i_Clk(i_Clk),
    .i_Binary_Num(w_RX_Byte[7:4]), // Upper 4 bits
    .o_Segment_A(w_Segment1_A),
    .o_Segment_B(w_Segment1_B),
    .o_Segment_C(w_Segment1_C),
    .o_Segment_D(w_Segment1_D),
    .o_Segment_E(w_Segment1_E),
    .o_Segment_F(w_Segment1_F),
    .o_Segment_G(w_Segment1_G)
  );

  // Invert output bits for active-low 7-segment displays
  assign o_Segment1_A = ~w_Segment1_A;
  assign o_Segment1_B = ~w_Segment1_B;
  assign o_Segment1_C = ~w_Segment1_C;
  assign o_Segment1_D = ~w_Segment1_D;
  assign o_Segment1_E = ~w_Segment1_E;
  assign o_Segment1_F = ~w_Segment1_F;
  assign o_Segment1_G = ~w_Segment1_G;
   
  // Convert lower nibble of received byte to 7-segment format (hex digit)
  Binary_To_7Segment SevenSeg2_Inst
  (
    .i_Clk(i_Clk),
    .i_Binary_Num(w_RX_Byte[3:0]), // Lower 4 bits
    .o_Segment_A(w_Segment2_A),
    .o_Segment_B(w_Segment2_B),
    .o_Segment_C(w_Segment2_C),
    .o_Segment_D(w_Segment2_D),
    .o_Segment_E(w_Segment2_E),
    .o_Segment_F(w_Segment2_F),
    .o_Segment_G(w_Segment2_G)
  );
   
  // Invert output bits for active-low 7-segment displays
  assign o_Segment2_A = ~w_Segment2_A;
  assign o_Segment2_B = ~w_Segment2_B;
  assign o_Segment2_C = ~w_Segment2_C;
  assign o_Segment2_D = ~w_Segment2_D;
  assign o_Segment2_E = ~w_Segment2_E;
  assign o_Segment2_F = ~w_Segment2_F;
  assign o_Segment2_G = ~w_Segment2_G;
   
endmodule
