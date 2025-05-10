module UART_RX //recieves 8bits + 1 start bit +  1 stop bit (no parity bit)
  #(parameter CLKS_PER_BIT = 217)
  // CLKS_PER_BIT = (freq. of i_Clk / freq. of UART)
  //eg: 25 MHz Clk, Baud rate of UART 115200 , CLKS_PER_BIT = (25000000/115200) = 217 clock cycles for 1 bit
  (
   input        i_Clock,
   input        i_RX_Serial, //serial data stream from computer
   output       o_RX_DV, //driven high for one clock cycle when recieve complete 
   output [7:0] o_RX_Byte //byte received form computer
   );
   
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [7:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]     r_RX_Byte     = 0;
  reg           r_RX_DV       = 0;
  reg [2:0]     r_SM_Main     = 0;
  
  
  always @(posedge i_Clock)
  begin
      
    case (r_SM_Main)//State Machine
      IDLE :
        begin
          r_RX_DV       <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_RX_Serial == 1'b0) // Start bit detected
            r_SM_Main <= RX_START_BIT;
          else
            r_SM_Main <= IDLE;
        end
      
      
      RX_START_BIT :
        begin
		
          if (r_Clock_Count == (CLKS_PER_BIT-1)/2) // Check middle of start bit to make sure it's still low
          begin
            if (i_RX_Serial == 1'b0)
            begin
              r_Clock_Count <= 0;  // reset counter, middle bit is low
              r_SM_Main     <= RX_DATA_BITS;
            end
            else
              r_SM_Main <= IDLE; 
          end
		  
          else
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_START_BIT;
          end
		  
        end // case: RX_START_BIT
      
      //we count from middle of start bit
      RX_DATA_BITS :
        begin
		
          if (r_Clock_Count < CLKS_PER_BIT-1) // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_DATA_BITS;
          end
		  
          else //r_Clock_Count = CLKS_PER_BIT - 1
          begin
            r_Clock_Count          <= 0;
            r_RX_Byte[r_Bit_Index] <= i_RX_Serial; //sample 
            // r_bit_Index goes from 0 to 7
           
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= RX_DATA_BITS;
            end
            else // received all bits, r_Bit_Index = 7
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= RX_STOP_BIT;
            end
          end
		  
        end // case: RX_DATA_BITS
      
      
      // Receive Stop bit.  Stop bit (always) = 1
      RX_STOP_BIT :
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    r_SM_Main     <= RX_STOP_BIT;
          end
		  
          else
          begin
       	    r_RX_DV       <= 1'b1; //tells main module that data is valid to be read
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
          end
        end // case: RX_STOP_BIT
      
      
      // Stay here 1 clock cycle
      CLEANUP :
        begin
          r_SM_Main <= IDLE;
          r_RX_DV   <= 1'b0;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end    
  
  assign o_RX_DV   = r_RX_DV;
  assign o_RX_Byte = r_RX_Byte;
  
endmodule // UART_RX
