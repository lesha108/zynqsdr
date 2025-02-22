// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  inout   [14:0]  ddr_addr,
  inout   [ 2:0]  ddr_ba,
  inout           ddr_cas_n,
  inout           ddr_ck_n,
  inout           ddr_ck_p,
  inout           ddr_cke,
  inout           ddr_cs_n,
  inout   [ 3:0]  ddr_dm,
  inout   [31:0]  ddr_dq,
  inout   [ 3:0]  ddr_dqs_n,
  inout   [ 3:0]  ddr_dqs_p,
  inout           ddr_odt,
  inout           ddr_ras_n,
  inout           ddr_reset_n,
  inout           ddr_we_n,

  inout           fixed_io_ddr_vrn,
  inout           fixed_io_ddr_vrp,
  inout   [53:0]  fixed_io_mio,
  inout           fixed_io_ps_clk,
  inout           fixed_io_ps_porb,
  inout           fixed_io_ps_srstb,

  inout           iic_scl,
  inout           iic_sda,

  inout   [10:0]  gpio_bd,

  input           rx_clk_in_p,
  input           rx_clk_in_n,
  input           rx_frame_in_p,
  input           rx_frame_in_n,
  input   [ 5:0]  rx_data_in_p,
  input   [ 5:0]  rx_data_in_n,
  output          tx_clk_out_p,
  output          tx_clk_out_n,
  output          tx_frame_out_p,
  output          tx_frame_out_n,
  output  [ 5:0]  tx_data_out_p,
  output  [ 5:0]  tx_data_out_n,

  output          enable,
  output          txnrx,
  input           clkout_in,
  output          clkout_out,
  
  // pps connections
  input         GPS_PPS,
  input         PPS_EXT_IN,

  // VTCXO and the DAC that feeds it
  output        TCXO_DAC_SYNC_N,
  output        TCXO_DAC_SCLK,
  output        TCXO_DAC_SDIN,
  input         TCXO_CLK,
  
  //LED to detact pll lock
  
  output        LED0,
  output        LED1,
  output        tx_0,
  output        ptt_0,
  

  inout           gpio_clksel,
  inout           gpio_resetb,
  inout           gpio_sync,
  inout           gpio_en_agc,
  inout   [ 3:0]  gpio_ctl,
  inout   [ 7:0]  gpio_status,

  output          spi_csn,
  output          spi_clk,
  output          spi_mosi,
  input           spi_miso

//  output  [27:0]  gp_out,
//  input   [27:0]  gp_in
);


  // internal signals

 // wire    [31:0]  gp_out_s;
 // wire    [31:0]  gp_in_s;
  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;
  
  wire  [27:0]  gp_out;
  wire  [27:0]  gp_in;
  
  wire pps;
  wire clk_tcxo = TCXO_CLK; // 40 MHz
  wire is_10meg, is_pps, reflck, plllck; // reference status bits
  reg [3:0] tcxo_status, st_rsync;
  reg [2:0] pps_reg;
  
  wire pps_select=2'b11;

  wire pps_ext = PPS_EXT_IN;
  wire gps_pps = GPS_PPS;
  
  assign gp_in=0;

  // assignments

  assign clkout_out = clkout_in;
  //assign gp_out[27:0] = gp_out_s[27:0];
  //assign gp_in_s[31:28] = gp_out_s[31:28];
  //assign gp_in_s[27: 0] = gp_in[27:0];

  // board gpio - 31-0

  assign gpio_i[31:11] = gpio_o[31:11];

  ad_iobuf #(.DATA_WIDTH(11)) i_iobuf_bd (
    .dio_t (gpio_t[10:0]),
    .dio_i (gpio_o[10:0]),
    .dio_o (gpio_i[10:0]),
    .dio_p (gpio_bd));

  // ad9361 gpio - 63-32

  //assign gpio_i[63:52] = gpio_o[63:52];
  assign gpio_i[63:54] = gpio_o[63:54];
  assign gpio_i[50:47] = gpio_o[50:47];

  /*ad_iobuf #(.DATA_WIDTH(16)) i_iobuf (
    .dio_t ({gpio_t[51], gpio_t[46:32]}),
    .dio_i ({gpio_o[51], gpio_o[46:32]}),
    .dio_o ({gpio_i[51], gpio_i[46:32]}),
    .dio_p ({ gpio_clksel,        // 51:51
              gpio_resetb,        // 46:46
              gpio_sync,          // 45:45
              gpio_en_agc,        // 44:44
              gpio_ctl,           // 43:40
              gpio_status}));     // 39:32
*/
  ad_iobuf #(.DATA_WIDTH(18)) i_iobuf (
    .dio_t ({gpio_t[53], gpio_t[52], gpio_t[51], gpio_t[46:32]}),
    .dio_i ({gpio_o[53], gpio_o[52], gpio_o[51], gpio_o[46:32]}),
    .dio_o ({gpio_i[53], gpio_i[52], gpio_i[51], gpio_i[46:32]}),
    .dio_p ({ ptt_0,             // 53:53 - gpio 107
              LED1,               // 52:52 - gpio 106
              gpio_clksel,        // 51:51
              gpio_resetb,        // 46:46
              gpio_sync,          // 45:45
              gpio_en_agc,        // 44:44
              gpio_ctl,           // 43:40
              gpio_status}));     // 39:32

  // instantiations

  system_wrapper i_system_wrapper (
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .enable (enable),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    //.gp_in_0 (gp_in_s[31:0]),
    //.gp_out_0 (gp_out_s[31:0]),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
    .gps_pps (1'b0),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .otg_vbusoc (1'b0),
    .rx_clk_in_n (rx_clk_in_n),
    .rx_clk_in_p (rx_clk_in_p),
    .rx_data_in_n (rx_data_in_n),
    .rx_data_in_p (rx_data_in_p),
    .rx_frame_in_n (rx_frame_in_n),
    .rx_frame_in_p (rx_frame_in_p),
    .spi0_clk_i (1'b0),
    .spi0_clk_o (spi_clk),
    .spi0_csn_0_o (spi_csn),
    .spi0_csn_1_o (),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi_miso),
    .spi0_sdo_i (1'b0),
    .spi0_sdo_o (spi_mosi),
    .spi1_clk_i (1'b0),
    .spi1_clk_o (),
    .spi1_csn_0_o (),
    .spi1_csn_1_o (),
    .spi1_csn_2_o (),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (1'b0),
    .spi1_sdo_i (1'b0),
    .spi1_sdo_o (),
    .tdd_sync_i (1'b0),
    .tdd_sync_o (),
    .tdd_sync_t (),
    .tx_clk_out_n (tx_clk_out_n),
    .tx_clk_out_p (tx_clk_out_p),
    .tx_data_out_n (tx_data_out_n),
    .tx_data_out_p (tx_data_out_p),
    .tx_frame_out_n (tx_frame_out_n),
    .tx_frame_out_p (tx_frame_out_p),
    .txnrx (txnrx),
    .tx_0 (tx_0),
    .up_enable (gpio_o[47]),
    .up_txnrx (gpio_o[48]));
    
        ///////////////////////////////////////////////////////////////////////
    // generate clocks from always on codec main clk
    ///////////////////////////////////////////////////////////////////////
    wire bus_clk, radio_clk;
    wire locked;
    wire int_40mhz;
    wire ref_pll_clk;
    
    
//    b205_clk_gen gen_clks
//    (
//        .CLK_IN1_40(TCXO_CLK), // No differential input!
//        .CLK_OUT1_40_int(int_40mhz), .CLK_OUT2_100_bus(bus_clk), .CLK_OUT3_200_ref_pll(ref_pll_clk),
//        //.RESET(reset_global), 
//        .locked(locked)
//    );

wire CLK_IN1_40_b205_clk_gen;
wire clk_in2_b205_clk_gen;
  IBUF clkin1_ibufg
   (.O (CLK_IN1_40_b205_clk_gen),
    .I (TCXO_CLK));




  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        CLK_OUT1_40_int_b205_clk_gen;
  wire        CLK_OUT2_100_bus_b205_clk_gen;
  wire        CLK_OUT3_200_ref_pll_b205_clk_gen;
  wire        clk_out4_b205_clk_gen;
  wire        clk_out5_b205_clk_gen;
  wire        clk_out6_b205_clk_gen;
  wire        clk_out7_b205_clk_gen;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_b205_clk_gen;
  wire        clkfbout_buf_b205_clk_gen;
  wire        clkfboutb_unused;
    wire clkout0b_unused;
   wire clkout1b_unused;
   wire clkout2b_unused;
   wire clkout3_unused;
   wire clkout3b_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (25.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (25.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKOUT1_DIVIDE       (10),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKOUT2_DIVIDE       (5),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (25.000))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_b205_clk_gen),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (CLK_OUT1_40_int_b205_clk_gen),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (CLK_OUT2_100_bus_b205_clk_gen),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (CLK_OUT3_200_ref_pll_b205_clk_gen),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_b205_clk_gen),
    .CLKIN1              (CLK_IN1_40_b205_clk_gen),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (1'b0));

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_b205_clk_gen),
    .I (clkfbout_b205_clk_gen));






  BUFG clkout1_buf
   (.O   (int_40mhz),
    .I   (CLK_OUT1_40_int_b205_clk_gen));


  BUFG clkout2_buf
   (.O   (bus_clk),
    .I   (CLK_OUT2_100_bus_b205_clk_gen));

  BUFG clkout3_buf
   (.O   (ref_pll_clk),
    .I   (CLK_OUT3_200_ref_pll_b205_clk_gen));



    //hold-off logic for clocks ready
    reg [15:0] clocks_ready_count;
    reg clocks_ready;
    always @(posedge bus_clk  or negedge locked) begin
        if (!locked) begin
            clocks_ready_count <= 16'b0;
            clocks_ready <= 1'b0;
        end
        else if (!clocks_ready) begin
            clocks_ready_count <= clocks_ready_count + 1'b1;
            clocks_ready <= (clocks_ready_count == 16'hffff);
        end
    end
    ///////////////////////////////////////////////////////////////////////
    // Create sync reset signals
    ///////////////////////////////////////////////////////////////////////
    wire ref_pll_rst;
    
    reset_sync ref_pll_sync(.clk(ref_pll_clk), .reset_in(!clocks_ready), .reset_out(ref_pll_rst));

    ///////////////////////////////////////////////////////////////////////
    // reference clock PLL
    ///////////////////////////////////////////////////////////////////////
    wire ext_ref_locked;
    wire ext_ref;
    
    
    
    b205_ref_pll ref_pll
    (
        .reset(ref_pll_rst),
        .clk(ref_pll_clk),
        .refclk(int_40mhz),
        .ref(ext_ref),
        .locked(ext_ref_locked),
        .sclk(TCXO_DAC_SCLK),
        .mosi(TCXO_DAC_SDIN),
        .sync_n(TCXO_DAC_SYNC_N)
    );
    
    assign ext_ref=PPS_EXT_IN;


//  ppsloop ppslp (
//    //.async_clk(async_clk),
//    .reset(1'b0),
//    .xoclk(clk_tcxo), .ppsgps(gps_pps), .ppsext(pps_ext),
//    .refsel(pps_select),
//    .lpps(pps),
//    .is10meg(is_10meg), .ispps(is_pps), .reflck(reflck), .plllck(plllck),
//    .sclk(TCXO_DAC_SCLK), .mosi(TCXO_DAC_SDIN), .sync_n(TCXO_DAC_SYNC_N),
//    .dac_dflt(16'h7fff)
//  );
  

    
  
  
  assign LED0 = ext_ref_locked;
  //assign LED1 = locked;  - moved to linux status led0


endmodule

// ***************************************************************************
// ***************************************************************************
