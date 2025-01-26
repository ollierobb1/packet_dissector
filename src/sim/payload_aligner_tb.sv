`timescale 1ns/100ps

import packet_pkg::*;

module payload_aligner_tests (
    input logic clk,
    packet_intf.source stim,
    payload_aligner_intf.sink monitor
);
    const bit debug_logs = 0;
    int num_tests_passed = 0;
    packet_ct randomiser = new();
    
    packet_ct expect_queue[$];

    initial begin
        #10ns
        
        test_random();
        teardown();

        $info("%d Successfull Tests", num_tests_passed);

        $finish;
    end 

    always begin
        automatic packet_ct dut_packet;
        monitor.read(dut_packet);
        check_result(dut_packet, expect_queue);
    end

    function automatic void check_result(packet_ct dut_packet, ref packet_ct expect_queue[$]);
        automatic packet_ct expected_packet = expect_queue.pop_front();

        if (debug_logs) $display($sformatf("Received Packet %p", dut_packet));
        
        if (expected_packet.header_a != dut_packet.header_a) begin
            $info("Mismatched Header A");
            $info("Header A {E, R}: {%d, %d}", expected_packet.header_a, dut_packet.header_a);
            $fatal;
        end

        if (expected_packet.header_b != dut_packet.header_b) begin
            $info("Mismatched Header B");
            $info("Header B {E, R}: {%d, %d}", expected_packet.header_c, dut_packet.header_c);
            $fatal;
        end

        if (expected_packet.header_c != dut_packet.header_c) begin
            $info("Mismatched Header C");
            $info("Header C {E, R}: {%d, %d}", expected_packet.header_c, dut_packet.header_c);
            $fatal;
        end

        num_tests_passed++;
    endfunction

    task automatic delay_cc(int cycles = 1);
        repeat (cycles) @(posedge(clk));
    endtask

    // Give DUT enough time to flush outputs
    task automatic teardown();
        delay_cc(256);
    endtask

    task automatic test_random(int num_tests = 100);
        repeat(num_tests) begin
            randomiser.randomise(.payload_length(5));

            if (debug_logs) $display($sformatf("Generated Packet %p", randomiser));

            expect_queue.push_back(randomiser);

            stim.write(randomiser.packet);
            delay_cc();
        end
    endtask

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