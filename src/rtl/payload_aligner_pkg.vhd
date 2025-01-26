library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package payload_aligner_pkg is 
    constant PACKET_WIDTH_BITS       : natural := 64;
    constant PACKET_WIDTH_BYTES      : natural := 8;
    constant HEADER_A_WIDTH_BITS     : natural := 48;
    constant HEADER_A_WIDTH_BYTES    : natural := 6;
    constant HEADER_B_WIDTH_BITS     : natural := 48;
    constant HEADER_B_WIDTH_BYTES    : natural := 6;
    constant HEADER_C_WIDTH_BITS     : natural := 16;
    constant HEADER_C_WIDTH_BYTES    : natural := 2;

    -- Header field positions are constant in packet
    subtype  HEADER_A_PACKET_RANGE is natural range 63 downto 16;
    subtype  HEADER_B_PACKET_RANGE_0 is natural range 15 downto 0;
    subtype  HEADER_B_PACKET_RANGE_1 is natural range 63 downto 32;
    subtype  HEADER_C_PACKET_RANGE is natural range 31 downto 16;

    type headers_t is record
        header_a        : std_logic_vector(HEADER_A_WIDTH_BITS - 1 downto 0);
        header_a_valid  : std_logic;
        header_b        : std_logic_vector(HEADER_B_WIDTH_BITS - 1 downto 0);
        header_b_valid  : std_logic;
        header_c        : std_logic_vector(HEADER_C_WIDTH_BITS - 1 downto 0);
        header_c_valid  : std_logic;
    end record;

end package payload_aligner_pkg;