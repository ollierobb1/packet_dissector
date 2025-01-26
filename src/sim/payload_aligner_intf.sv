import packet_pkg::*;

interface payload_aligner_intf (
    input logic clk
);

    logic header_a_valid;
    logic [47:0] header_a;

    logic header_b_valid;
    logic [47:0] header_b;

    logic header_c_valid;
    logic [47:0] header_c;

    logic payload_valid;
    logic [63:0] payload;
    logic [7:0] byte_enable;
    logic sop;
    logic eop;

    modport sink (
        input header_a_valid, 
        input header_a, 
        input header_b_valid, 
        input header_b, 
        input header_c_valid, 
        input header_c, 
        input payload_valid, 
        input payload, 
        input byte_enable, 
        input sop, 
        input eop,
        import task read()
    );

    modport source (
        output header_a_valid, 
        output header_a, 
        output header_b_valid, 
        output header_b, 
        output header_c_valid, 
        output header_c, 
        output payload_valid, 
        output payload, 
        output byte_enable, 
        output sop, 
        output eop
    );

    
    task automatic read (output packet_ct _data);
        _data = new();

        fork
            begin
                while (header_a_valid !== 1) delay_cc();

                // Need to convert DUT logic vectors back to unpacked byte array to match golden data format
                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_a_width_bytes; curr_byte++) begin
                    _data.header_a[curr_byte] = header_a[(curr_byte+1)*8-1 -: 8];
                end
            end
            begin
                while (header_b_valid !== 1) delay_cc();

                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_b_width_bytes; curr_byte++) begin
                    _data.header_b[curr_byte] = header_b[(curr_byte+1)*8-1 -: 8];
                end
            end
            begin
                while (header_c_valid !== 1) delay_cc();

                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_c_width_bytes; curr_byte++) begin
                    _data.header_c[curr_byte] = header_c[(curr_byte+1)*8-1 -: 8];
                end
            end
            begin
                while (sop !== 1) delay_cc();

                forever begin
                    for (int curr_byte = 0; curr_byte < payload_aligner_pkg::packet_width_bytes; curr_byte++) begin
                        _data.payload = {_data.payload, payload[(curr_byte+1)*8-1 -: 8]};
                    end

                    // Finish reading payload if eop is raised
                    if (eop) break;

                    delay_cc();
                end
            end
        join
    endtask

    task automatic delay_cc(int cycles = 1);
        repeat (cycles) @(posedge(clk));
    endtask

endinterface;