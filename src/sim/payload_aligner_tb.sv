`timescale 1ns/100ps

import packet_pkg::*;

module payload_aligner_tests (
    input logic clk,
    packet_intf.source stim
);
    byte _data[];

    initial begin
        #10ns
        _data = new[26];

        foreach (_data[i]) begin
            _data[i] = $urandom_range(0, 255);
        end

        stim.write(_data);
    end 

endmodule

module payload_aligner_wrap (
    input logic clk,
    packet_intf.sink stim
);

    payload_aligner inner (
        .iClk(clk),
        .iReset(),

        .iValid(stim.valid),
        .iPacket(stim.data),

        .iSop(stim.sop),
        .iEop(stim.eop),
        .iByte_enable(stim.byte_enable),
        
        .oPayload(),
        .oPayload_valid(),

        .oHeader_A(),
        .oHeader_A_valid(),
        
        .oHeader_B(),
        .oHeader_B_valid(),
        
        .oHeader_C(),
        .oHeader_C_valid(),

        .oSop(),
        .oEop(),
        .oByte_enable()
    ); 
endmodule

module payload_aligner_tb;
    logic clk = 0;

    packet_intf stim (.*);

    payload_aligner_wrap dut (.*);

    payload_aligner_tests test (.*);

    always #0.5 clk = !clk;

    initial begin
        #1ms;
        $finish;
    end
endmodule