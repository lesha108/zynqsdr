`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/22 19:18:41
// Design Name: 
// Module Name: DACx311_auto_set
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DACx311_auto_set(

    );
    
  reg clk=0;
  reg [16-1:0] daco;
  wire sclk;
  wire mosi;
  wire sync_n;
  
    
   DA_shiver DUT
  (
    .clk(clk),
    .dat(daco),
    .sclk(sclk),
    .mosi(mosi),
    .sync_n(sync_n)
  );
  
  initial
  begin
  clk=0;
  daco=16'h7eff;
  end
  
  always
  begin
  #5 clk=~clk;
  end
  
endmodule
