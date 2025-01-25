import payload_aligner_pkg::*;

package packet_pkg;
    class packet_ct;
        byte header_a [payload_aligner_pkg::header_a_width_bytes - 1:0];
        byte header_b [payload_aligner_pkg::header_b_width_bytes - 1:0];
        byte header_c [payload_aligner_pkg::header_c_width_bytes - 1:0];
        byte payload[];

        byte packet[];

        // SystemVerilog rand and randomise() functionallity isn't available without full license.
        function void randomise(int payload_length = $urandom_range(1, 100));
            int total_packet_length = payload_aligner_pkg::header_a_width_bytes + payload_aligner_pkg::header_b_width_bytes + payload_aligner_pkg::header_c_width_bytes + payload_length;
            packet = new[total_packet_length];

            // Randomise each packet field individually before packing into a packet for easier comparison with DUT
            foreach (header_a[i]) begin
                header_a[i] = $urandom_range(0, 8'hFF);
            end
            foreach (header_a[i]) begin
                header_b[i] = $urandom_range(0, 8'hFF);
            end
            foreach (header_a[i]) begin
                header_c[i] = $urandom_range(0, 8'hFF);
            end

            payload = new[payload_length];
            foreach(payload[i]) begin
                payload[i] = $urandom_range(0, 8'hFF);
            end
            
            packet = {header_a, header_b, header_c, payload};
        endfunction

    endclass

endpackage