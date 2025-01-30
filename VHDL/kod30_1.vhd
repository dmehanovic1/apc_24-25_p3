LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY gmii_transmitter IS
    PORT (
        clk                 : IN STD_LOGIC;  
        reset               : IN STD_LOGIC;
        avalon_clk          : OUT STD_LOGIC;  
        avalon_data         : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        avalon_valid        : IN STD_LOGIC;
        avalon_empty        : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        avalon_startofpacket: IN STD_LOGIC;
        avalon_endofpacket  : IN STD_LOGIC;
        gmii_txd            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        gmii_txen           : OUT STD_LOGIC;
        gmii_txer           : OUT STD_LOGIC
        --gmii_clk            : IN STD_LOGIC
    );
END ENTITY gmii_transmitter;

ARCHITECTURE behavioral OF gmii_transmitter IS
    TYPE STATE_TYPE IS (IDLE, SEND_HEAD, SEND_DATA, SEND_ERROR);
    SIGNAL current_state, next_state : STATE_TYPE;
    SIGNAL internal_counter          : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0'); 
    SIGNAL gmii_txd_internal         : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL gmii_txen_internal        : STD_LOGIC;
    SIGNAL gmii_txer_internal        : STD_LOGIC := '0';
    SIGNAL data_counter              : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL avalon_clk_internal       : STD_LOGIC := '0';

    -- Registracija Avalon signala
    SIGNAL avalon_data_reg           : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL avalon_valid_reg          : STD_LOGIC;
    SIGNAL avalon_startofpacket_reg  : STD_LOGIC;
    SIGNAL avalon_endofpacket_reg    : STD_LOGIC;
    SIGNAL avalon_empty_reg          : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN

    -- Generisanje avalon_clk signala kao clk/8
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            internal_counter <= (OTHERS => '0');
            avalon_clk_internal <= '0';
        ELSIF rising_edge(clk) THEN
            IF internal_counter >= "100" THEN  -- 4. ciklus
                avalon_clk_internal <= '1';
            ELSE  
                avalon_clk_internal <= '0';
                --internal_counter <= (OTHERS => '0');
                 END IF;
					  internal_counter <= std_logic_vector(unsigned(internal_counter) + 1);
        END IF;
    END PROCESS;
    
    avalon_clk <= avalon_clk_internal;

    -- Registracija Avalon signala na uzlaznu ivicu avalon_clk
    PROCESS(avalon_clk_internal, reset)
    BEGIN
        IF reset = '1' THEN
            avalon_data_reg <= (OTHERS => '0');
            avalon_valid_reg <= '0';
            avalon_startofpacket_reg <= '0';
            avalon_endofpacket_reg <= '0';
            avalon_empty_reg <= (OTHERS => '0');
        ELSIF RISING_EDGE(avalon_clk_internal) THEN
            avalon_data_reg <= avalon_data;
            avalon_valid_reg <= avalon_valid;
            avalon_startofpacket_reg <= avalon_startofpacket;
            avalon_endofpacket_reg <= avalon_endofpacket;
            avalon_empty_reg <= avalon_empty;
        END IF;
    END PROCESS;

    -- FSM logika koja prati glavni takt
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= IDLE;
        ELSIF RISING_EDGE(clk) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    -- FSM logika
    PROCESS(current_state, avalon_valid_reg, avalon_startofpacket_reg, avalon_endofpacket_reg, data_counter, reset, gmii_txer_internal)
    BEGIN
        next_state <= current_state;
        gmii_txd_internal <= (OTHERS => '0');
        gmii_txen_internal <= '0';
        gmii_txer_internal <= '0';

        CASE current_state IS
            WHEN IDLE =>
                IF reset = '1' THEN
                    next_state <= IDLE;  
                ELSIF avalon_startofpacket_reg = '1' AND avalon_valid_reg = '1' THEN
                    next_state <= SEND_HEAD;
                END IF;

            WHEN SEND_HEAD =>
                gmii_txd_internal <= x"55"; -- Preambula
                gmii_txen_internal <= '1';
                IF reset = '1' THEN
                    next_state <= IDLE;  
                ELSIF data_counter = 7 THEN
                    gmii_txd_internal <= x"D5"; -- SFD
                    next_state <= SEND_DATA;
                END IF;

            WHEN SEND_DATA =>
                gmii_txen_internal <= '1';
                IF avalon_valid_reg = '1' THEN
                    CASE data_counter IS
                        WHEN 0 => gmii_txd_internal <= avalon_data_reg(63 DOWNTO 56);
                        WHEN 1 => gmii_txd_internal <= avalon_data_reg(55 DOWNTO 48);
                        WHEN 2 => gmii_txd_internal <= avalon_data_reg(47 DOWNTO 40);
                        WHEN 3 => gmii_txd_internal <= avalon_data_reg(39 DOWNTO 32);
                        WHEN 4 => gmii_txd_internal <= avalon_data_reg(31 DOWNTO 24);
                        WHEN 5 => gmii_txd_internal <= avalon_data_reg(23 DOWNTO 16);
                        WHEN 6 => gmii_txd_internal <= avalon_data_reg(15 DOWNTO 8);
                        WHEN 7 => gmii_txd_internal <= avalon_data_reg(7 DOWNTO 0);
                        WHEN OTHERS => gmii_txd_internal <= (OTHERS => '0');
                    END CASE;

                    IF avalon_endofpacket_reg = '1' THEN
                        next_state <= IDLE;
                    END IF;
                ELSE
                    next_state <= SEND_ERROR;
                END IF;

            WHEN SEND_ERROR =>
                gmii_txer_internal <= '0';
                gmii_txen_internal <= '1';
                gmii_txd_internal <= x"0E"; 
                next_state <= SEND_DATA;

        END CASE;
    END PROCESS;

    -- Brojač podataka
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            data_counter <= 0;
        ELSIF rising_edge(clk) THEN
            IF current_state = SEND_HEAD OR current_state = SEND_DATA THEN
                data_counter <= (data_counter + 1) MOD 8;
            ELSE
                data_counter <= 0;
            END IF;
        END IF;
    END PROCESS;

    gmii_txd <= gmii_txd_internal;
    gmii_txen <= gmii_txen_internal;
    gmii_txer <= gmii_txer_internal;

END ARCHITECTURE behavioral;
