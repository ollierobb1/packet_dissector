library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity payload_aligner is
    generic(
        PACKET_WIDTH_BITS   : natural := 64;
        HEADER_A_WIDTH_BITS : natural := 48;
        HEADER_B_WIDTH_BITS : natural := 48;
        HEADER_C_WIDTH_BITS : natural := 16
    );
    port(
        iClk            : in  std_logic;
        iReset          : in  std_logic;
    
        iValid          : in  std_logic;
        iPacket         : in  std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);

        iSop            : in  std_logic;
        iEop            : in  std_logic;
        iByte_enable    : in  std_logic_vector(7 downto 0);

        -- Header fields A, B and C arrive at different words in packet 
        -- Therefore, each header field needs it's own valid flag for lowest latency
        oHeader_A       : out std_logic_vector(HEADER_A_WIDTH_BITS - 1 downto 0);
        oHeader_A_valid : out std_logic;

        oHeader_B       : out std_logic_vector(HEADER_B_WIDTH_BITS - 1 downto 0);
        oHeader_B_valid : out std_logic;
        
        oHeader_C       : out std_logic_vector(HEADER_C_WIDTH_BITS - 1 downto 0);
        oHeader_C_valid : out std_logic;

        oPayload        : out std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);
        oPayload_valid  : out std_logic;

        oSop            : out std_logic;
        oEop            : out std_logic;
        oByte_enable    : out std_logic
    );
end entity payload_aligner;

architecture rtl of payload_aligner is 
    signal word_count : natural := 0;

    signal packet_d1  : std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);
    signal valid_d1   : std_logic;
    signal valid_d2   : std_logic;

    signal header_A_latched : std_logic_vector(HEADER_A_WIDTH_BITS - 1 downto 0);
    signal header_B_latched : std_logic_vector(HEADER_B_WIDTH_BITS - 1 downto 0);
    signal header_C_latched : std_logic_vector(HEADER_C_WIDTH_BITS - 1 downto 0);
begin

    packet_d1 <= iPacket when rising_edge(iClk);
    valid_d1  <= iValid when rising_edge(iClk);
    valid_d2  <= valid_d1 when rising_edge(iClk);
  
    p_word_counter : process(iClK)
    begin
        if rising_edge(iClk) then
            if iReset or iEop then
                word_count <= 0;
            elsif iValid then
                word_count <= word_count + 1;
            end if;
        end if;
    end process;

    p_latch_headers : process(iClk)
    begin
        if rising_edge(iClk) then
            if iReset then
                header_A_latched <= (others => '0');
                header_B_latched <= (others => '0');
                header_C_latched <= (others => '0');
            elsif word_count = 0 then
                header_A_latched <= iPacket(63 downto 16); -- TODO: Create range constants in signal declaration
            elsif word_count = 1 then
                header_B_latched <= packet_d1(15 downto 0) & iPacket(63 downto 32);
                header_C_latched <= iPacket(31 downto 16);
            end if;
        end if;
    end process;

    oHeader_A       <= iPacket(iPacket'left downto iPacket'left - HEADER_A_WIDTH_BITS + 1) when word_count = 0 else header_A_latched;
    oHeader_A_valid <= iValid or valid_d1;

    oHeader_B       <= packet_d1(15 downto 0) & iPacket(63 downto 32) when word_count = 1 else header_B_latched;
    oHeader_B_valid <= valid_d1;

    oHeader_C       <= iPacket(31 downto 16) when word_count = 1 else header_C_latched;
    oHeader_C_valid <= valid_d1;

    p_align_payload : process(all)
    begin
        case word_count is
            when 0 =>
                -- No payload present in first word of packet
            when 1 =>
                -- Only partial payload present in second word of packet
            when others =>
                oPayload <= packet_d1(15 downto 0) & iPacket(63 downto 16);
        end case;
    end process;

    oPayload_valid <= valid_d2;

end architecture rtl;