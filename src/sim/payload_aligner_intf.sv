import packet_pkg::*;
import payload_aligner_pkg::*;

interface payload_aligner_intf (
    input logic clk
);

    headers_t headers;
    logic payload_valid;
    logic [packet_width_bits - 1:0] payload;
    logic [byte_enable_width_bits - 1:0] byte_enable;
    logic sop;
    logic eop;

    modport sink (
        input headers,
        input payload_valid, 
        input payload, 
        input byte_enable, 
        input sop, 
        input eop,
        import task read()
    );

    modport source (
        output headers,
        output payload_valid, 
        output payload, 
        output byte_enable, 
        output sop, 
        output eop
    );

    task automatic read (output packet_ct _data);
        _data = new();
        
        // Avoid picking up previous inputs combinatorially
        delay_cc();

        fork
            begin
                while (headers.header_a_valid !== 1) delay_cc();

                // Need to convert DUT logic vectors back to unpacked byte array to match golden data format
                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_a_width_bytes; curr_byte++) begin
                    _data.header_a[curr_byte] = headers.header_a[(curr_byte + 1)*byte_width_bits - 1 -: byte_width_bits];
                end
            end
            begin
                while (headers.header_b_valid !== 1) delay_cc();

                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_b_width_bytes; curr_byte++) begin
                    _data.header_b[curr_byte] = headers.header_b[(curr_byte + 1)*byte_width_bits - 1 -: byte_width_bits];
                end
            end
            begin
                while (headers.header_c_valid !== 1) delay_cc();

                for (int curr_byte = 0; curr_byte < payload_aligner_pkg::header_c_width_bytes; curr_byte++) begin
                    _data.header_c[curr_byte] = headers.header_c[(curr_byte + 1)*byte_width_bits - 1 -: byte_width_bits];
                end
            end
            begin
                while (sop !== 1) delay_cc();

                forever begin
                    // Finish reading payload if eop is raised
                    if (eop) begin
                        for (int curr_byte = byte_enable_width_bits - 1; byte_enable[curr_byte] == 1; curr_byte--) begin
                            _data.payload = {_data.payload, payload[(curr_byte + 1)*byte_width_bits - 1 -: byte_width_bits]};
                        end
                    
                        break;
                    end

                    for (int curr_byte = payload_aligner_pkg::packet_width_bytes - 1; curr_byte >= 0; curr_byte--) begin
                        _data.payload = {_data.payload, payload[(curr_byte + 1)*byte_width_bits - 1 -: byte_width_bits]};
                    end

                    delay_cc();
                end
            end
        join
    endtask

    task automatic delay_cc(int cycles = 1);
        repeat (cycles) @(posedge(clk));
    endtask

endinterface;