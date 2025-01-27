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
        iByte_enable    : in  std_logic_vector(BYTE_ENABLE_WIDTH_BITS - 1 downto 0);

        -- Header fields A, B and C arrive at different words in packet 
        -- Therefore, each header field needs it's own valid flag to achieve lowest latency
        oHeaders        : out headers_t;

        oPayload        : out std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);
        oPayload_valid  : out std_logic;

        oSop            : out std_logic;
        oEop            : out std_logic;
        oByte_enable    : out std_logic_vector(BYTE_ENABLE_WIDTH_BITS - 1 downto 0)
    );
end entity payload_aligner;

architecture rtl of payload_aligner is 
    type state_t is (
        IDLE,
        HEADER,
        PAYLOAD,
        PAYLOAD_OVERFLOW
    );

    signal current_state    : state_t;
    signal next_state       : state_t;

    signal word_count       : natural := 0;

    signal packet_d1        : std_logic_vector(PACKET_WIDTH_BITS - 1 downto 0);
    signal byte_enable_d1   : std_logic_vector(BYTE_ENABLE_WIDTH_BITS - 1 downto 0);
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
                oHeaders.header_a_valid <= '0';
                oHeaders.header_b_valid <= '0';
                oHeaders.header_c_valid <= '0';
                oPayload_valid          <= '0';

                -- First word of packet contains header A
                if iValid then
                    oHeaders.header_a_valid <= '1';
                    
                    next_state <= HEADER;
                end if;

            when HEADER =>
                -- Second word of packet contains headers B and C
                oHeaders.header_b_valid <= '1';
                oHeaders.header_c_valid <= '1';
                
                -- Check for corner case where payload is at most 2 bytes (same word as headers)
                if iEop /= '1' then
                    next_state <= PAYLOAD;
                else 
                    oPayload_valid <= '1';
                    oSop <= '1';
                    oEop <= '1';
                    next_state <= IDLE;
                end if;

            when PAYLOAD =>
                -- Second and third word of packet contain first payload word
                oPayload_valid <= '1';
                
                -- Pulse sop when first word of payload is sent
                if not payload_valid_d1 then
                    oSop <= '1';
                end if;
                
                if iEop = '1' then
                    -- If the last two bytes of the payload are valid then we will need an extra cycle to send them
                    if iByte_enable(1) = '1' then
                        next_state <= PAYLOAD_OVERFLOW;
                    else 
                        oEop <= '1';
                        next_state <= IDLE;
                    end if;
                end if;
                
            when PAYLOAD_OVERFLOW =>
                oEop <= '1';
                next_state <= IDLE;

        end case;
    end process;

    packet_d1        <= iPacket when rising_edge(iClk);
    payload_valid_d1 <= oPayload_valid when rising_edge(iClk);
    byte_enable_d1   <= iByte_enable when rising_edge(iClk);
  
    p_word_counter : process(iClK)
    begin
        if rising_edge(iClk) then
            if iReset or oEop then
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

    oHeaders.header_a <= iPacket(HEADER_A_PACKET_RANGE) when word_count = 0 else header_A_latched;
    oHeaders.header_b <= packet_d1(HEADER_B_PACKET_RANGE_0) & iPacket(HEADER_B_PACKET_RANGE_1) when word_count = 1 else header_B_latched;
    oHeaders.header_c <= iPacket(HEADER_C_PACKET_RANGE) when word_count = 1 else header_C_latched;

    p_align_payload : process(all)
    begin
        case word_count is
            when 0 =>
                -- No payload present in first word of packet
            when 1 =>
                -- Second word of packet containts payload in last two bytes
                oPayload(oPayload'left downto oPayload'left - 15) <= iPacket(15 downto 0);
            when others =>
                -- Realigned payload is made up of bottom two bytes of previous packet and top 6 bytes of current packet
                oPayload <= packet_d1(15 downto 0) & iPacket(63 downto 16);
        end case;
    end process;

    p_byte_enable : process(all) 
    begin
        oByte_enable <= (others => '0');
        if current_state = PAYLOAD then
            oByte_enable <= "11" & iByte_enable(iByte_enable'left downto 2);
        elsif current_state = PAYLOAD_OVERFLOW then
            oByte_enable(oByte_enable'left downto oByte_enable'left - 1) <= byte_enable_d1(1 downto 0);
        elsif current_state = HEADER and oEop = '1'then
            oByte_enable(oByte_enable'left downto oByte_enable'left - 1) <= iByte_enable(1 downto 0);
        end if;
    end process;
    
end architecture rtl;