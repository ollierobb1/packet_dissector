library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.payload_aligner_pkg.all;

entity payload_aligner is
    port(
        iClk            : in  std_logic;
        iReset          : in  std_logic;
    
        iValid          : in  std_logic;
        iPacket         : in  std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);

        iSop            : in  std_logic;
        iEop            : in  std_logic;
        iByte_enable    : in  std_logic_vector(7 downto 0);

        -- Header fields A, B and C arrive at different words in packet 
        -- Therefore, each header field needs it's own valid flag to achieve lowest latency
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
        oByte_enable    : out std_logic_vector(7 downto 0)
    );
end entity payload_aligner;

architecture rtl of payload_aligner is 
    type state_t is (
        IDLE,
        HEADER,
        PAYLOAD
    );

    signal current_state    : state_t;
    signal next_state       : state_t;

    signal word_count       : natural := 0;

    signal packet_d1        : std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);
    signal payload_valid_d1 : std_logic;

    signal header_A_latched : std_logic_vector(HEADER_A_WIDTH_BITS - 1 downto 0);
    signal header_B_latched : std_logic_vector(HEADER_B_WIDTH_BITS - 1 downto 0);
    signal header_C_latched : std_logic_vector(HEADER_C_WIDTH_BITS - 1 downto 0);
begin

    p_sync_state : process(iClk)
    begin
        if rising_edge(iClk) then
            if iReset then
                current_state <= IDLE;
            else 
                current_state <= next_state;
            end if;
        end if;
    end process;

    p_async_state : process(all)
    begin
        oSop <= '0';
        oEop <= '0';

        next_state <= current_state;
        case current_state is
            when IDLE =>
                oHeader_A_valid <= '0';
                oHeader_B_valid <= '0';
                oHeader_C_valid <= '0';
                oPayload_valid  <= '0';

                -- First word of packet contains header A
                if iValid then
                    oHeader_A_valid <= '1';
                    
                    next_state <= HEADER;
                end if;

            when HEADER =>
                -- Second word of packet contains headers B and C
                oHeader_B_valid <= '1';
                oHeader_C_valid <= '1';

                next_state <= PAYLOAD;

            when PAYLOAD =>
                -- Second and third word of packet contain first payload word
                oPayload_valid <= '1';

                -- Pulse sop when entering PAYLOAD for the first cycle
                if not payload_valid_d1 then
                    oSop <= '1';
                end if;
                
                if iEop then
                    oEop <= '1';
                    next_state <= IDLE;
                end if;
        end case;
    end process;

    packet_d1 <= iPacket when rising_edge(iClk);
    payload_valid_d1 <= oPayload_valid when rising_edge(iClk);
  
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
                header_A_latched <= iPacket(HEADER_A_PACKET_RANGE);
            elsif word_count = 1 then
                header_B_latched <= packet_d1(HEADER_B_PACKET_RANGE_0) & iPacket(HEADER_B_PACKET_RANGE_1);
                header_C_latched <= iPacket(HEADER_C_PACKET_RANGE);
            end if;
        end if;
    end process;

    oHeader_A <= iPacket(HEADER_A_PACKET_RANGE) when word_count = 0 else header_A_latched;
    oHeader_B <= packet_d1(HEADER_B_PACKET_RANGE_0) & iPacket(HEADER_B_PACKET_RANGE_1) when word_count = 1 else header_B_latched;
    oHeader_C <= iPacket(HEADER_C_PACKET_RANGE) when word_count = 1 else header_C_latched;

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
    
    oByte_enable <= "11" & iByte_enable(7 downto 2);

end architecture rtl;