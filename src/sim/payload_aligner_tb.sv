`timescale 1ns/100ps

import packet_pkg::*;

module payload_aligner_tests (
    input logic clk,
    packet_intf.source stim,
    payload_aligner_intf.sink monitor
);
    packet_ct randomiser = new();
    byte _data[];

    initial begin
        #10ns
        randomiser.randomise(.payload_length(5));
        $display("header A: %p, payload: %p", randomiser.header_a, randomiser.payload);

        stim.write(randomiser.packet);
    end 

    always begin
        automatic packet_ct expected;
        monitor.read(expected);
    end

endmodule

module payload_aligner_wrap (
    input logic clk,
    packet_intf.sink stim,
    payload_aligner_intf.source monitor
);
    logic tmp_payload_valid;
    logic [63:0] tmp_payload;

    logic tmp_header_a_valid;
    logic [47:0] tmp_header_a;

    logic tmp_header_b_valid;
    logic [47:0] tmp_header_b;

    logic tmp_header_c_valid;
    logic [15:0] tmp_header_c;

    logic tmp_sop;
    logic tmp_eop;

    always_comb begin
        monitor.header_a_valid <= tmp_header_a_valid;
        monitor.header_a <= tmp_header_a;

        monitor.header_b_valid <= tmp_header_b_valid;
        monitor.header_b <= tmp_header_b;

        monitor.header_c_valid <= tmp_header_c_valid;
        monitor.header_c <= tmp_header_c;

        monitor.payload_valid <= tmp_payload_valid;
        monitor.payload <= tmp_payload;

        monitor.sop <= tmp_sop;
        monitor.eop <= tmp_eop;
    end

    payload_aligner inner (
        .iClk(clk),
        .iReset(),

        .iValid(stim.valid),
        .iPacket(stim.data),

        .iSop(stim.sop),
        .iEop(stim.eop),
        .iByte_enable(stim.byte_enable),
        
        .oPayload(tmp_payload),
        .oPayload_valid(tmp_payload_valid),

        .oHeader_A(tmp_header_a),
        .oHeader_A_valid(tmp_header_a_valid),
        
        .oHeader_B(tmp_header_b),
        .oHeader_B_valid(tmp_header_b_valid),
        
        .oHeader_C(tmp_header_c),
        .oHeader_C_valid(tmp_header_c_valid),

        .oSop(tmp_sop),
        .oEop(tmp_eop),
        .oByte_enable()
    ); 
endmodule

module payload_aligner_tb;
    logic clk = 0;

    packet_intf stim (.*);

    payload_aligner_intf monitor (.*);

    payload_aligner_wrap dut (.*);

    payload_aligner_tests test (.*);

    always #0.5 clk = !clk;

    initial begin
        #1ms;
        $finish;
    end
endmodule