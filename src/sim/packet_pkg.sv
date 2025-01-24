import payload_aligner_pkg::*;

package packet_pkg;
    class packet_randomiser_ct;
        logic [payload_aligner_pkg::header_a_width_bits - 1:0] header_A;
        logic [payload_aligner_pkg::header_b_width_bits - 1:0] header_B;
        logic [payload_aligner_pkg::header_c_width_bits - 1:0] header_C;
        logic payload[];
    endclass

endpackage