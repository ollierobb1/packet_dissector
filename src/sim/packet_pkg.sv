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
            foreach(header_a[i]) header_a[i] = $urandom_range(0, 8'hff);
            foreach(header_b[i]) header_b[i] = $urandom_range(0, 8'hff);
            foreach(header_c[i]) header_c[i] = $urandom_range(0, 8'hff);

            payload = new[payload_length];
            foreach(payload[i]) payload[i] = $urandom_range(0, 8'hff);
            
            packet = {header_a, header_b, header_c, payload};
        endfunction

        function packet_ct clone();
            packet_ct new_obj = new();

            new_obj.header_a = this.header_a;
            new_obj.header_b = this.header_b;
            new_obj.header_c = this.header_c;

            new_obj.payload = new[this.payload.size()];
            foreach (this.payload[i]) new_obj.payload[i] = this.payload[i];

            new_obj.packet = new[this.packet.size()];
            foreach (this.packet[i]) new_obj.packet[i] = this.packet[i];

            return new_obj;
        endfunction

    endclass

endpackage