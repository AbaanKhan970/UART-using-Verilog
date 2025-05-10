module UART_TX 
  #(parameter CLKS_PER_BIT = 217) // Clock cycles per bit
  (
   input       i_Rst_L,       // Active-low asynchronous reset
   input       i_Clock,       // System clock
   input       i_TX_DV,       // Data Valid signal: start transmission when high
   input [7:0] i_TX_Byte,     // 8-bit data byte to transmit
   output reg  o_TX_Active,   // High when transmission is in progress
   output reg  o_TX_Serial,   // UART serial output line
   output reg  o_TX_Done      // Pulses high for 1 clock cycle after transmission
   );

  // UART transmission states
  localparam IDLE         = 2'b00;
  localparam TX_START_BIT = 2'b01;
  localparam TX_DATA_BITS = 2'b10;
  localparam TX_STOP_BIT  = 2'b11;
  
  reg [2:0] r_SM_Main;  // Main state machine register
  reg [$clog2(CLKS_PER_BIT):0] r_Clock_Count; // Counts clock cycles for timing
  reg [2:0] r_Bit_Index; // Tracks which bit of the byte is being transmitted
  reg [7:0] r_TX_Data;   // Stores byte to be transmitted

  // Main state machine: triggered on clock edge or asynchronous reset
  always @(posedge i_Clock or negedge i_Rst_L)
  begin
    if (~i_Rst_L) // Reset condition
    begin
      r_SM_Main <= 3'b000; // Set to IDLE
    end
    else
    begin
      o_TX_Done <= 1'b0; // Default: transmission not done

      case (r_SM_Main)
      
      // IDLE: Wait for data valid signal
      IDLE :
        begin
          o_TX_Serial   <= 1'b1;         // UART idle line is high
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_TX_DV == 1'b1) // If data valid signal received
          begin
            o_TX_Active <= 1'b1;         // Mark transmission as active
            r_TX_Data   <= i_TX_Byte;    // Store byte to transmit
            r_SM_Main   <= TX_START_BIT; // Go to start bit state
          end
          else
            r_SM_Main <= IDLE;           // Stay in IDLE
        end // case: IDLE
      
      // TX_START_BIT: Transmit start bit (logic 0)
      TX_START_BIT :
        begin
          o_TX_Serial <= 1'b0; // Start bit is low
          
          // Wait for 1 bit time (CLKS_PER_BIT cycles)
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT; // Stay in start bit state
          end
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= TX_DATA_BITS; // Move to data bit transmission
          end
        end // case: TX_START_BIT
      
      // TX_DATA_BITS: Transmit 8 data bits (LSB first)
      TX_DATA_BITS :
        begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index]; // Output current bit
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS; // Stay in current bit cycle
          end
          else
          begin
            r_Clock_Count <= 0;
            
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1; // Move to next bit
              r_SM_Main   <= TX_DATA_BITS;
            end
            else
            begin //8 bits done
              r_Bit_Index <= 0;
              r_SM_Main   <= TX_STOP_BIT; // All bits sent, move to stop bit
            end
          end 
        end // case: TX_DATA_BITS
      
      // TX_STOP_BIT: Transmit stop bit (logic 1)
      TX_STOP_BIT :
        begin
          o_TX_Serial <= 1'b1; // Stop bit is high
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_STOP_BIT; // Wait full bit duration
          end
          else
          begin
            o_TX_Done     <= 1'b1;  // Signal that transmission is done
            r_Clock_Count <= 0;
            r_SM_Main     <= IDLE; // Return to IDLE state
            o_TX_Active   <= 1'b0; // Mark transmission as inactive
          end 
        end // case: TX_STOP_BIT      
      
      default :
        r_SM_Main <= IDLE;
      
      endcase
    end // else: not in reset
  end // always block
  
endmodule
