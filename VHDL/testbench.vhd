LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY gmii_transmitter_tb IS
END ENTITY gmii_transmitter_tb;

ARCHITECTURE behavior OF gmii_transmitter_tb IS
    COMPONENT gmii_transmitter
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
    END COMPONENT;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL avalon_clk : STD_LOGIC;
    SIGNAL reset : STD_LOGIC := '1';
    SIGNAL avalon_data : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
    SIGNAL avalon_valid, avalon_startofpacket, avalon_endofpacket : STD_LOGIC := '0';
    SIGNAL avalon_empty : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL gmii_txd : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL gmii_txen, gmii_txer : STD_LOGIC;

    CONSTANT CLK_PERIOD : TIME := 10 ns;
    --CONSTANT GMII_CLK_PERIOD : TIME := 10 ns;

BEGIN
    uut: gmii_transmitter
        PORT MAP (
            clk => clk,
            reset => reset,
            avalon_clk => avalon_clk,
            avalon_data => avalon_data,
            avalon_valid => avalon_valid,
            avalon_empty => avalon_empty,
            avalon_startofpacket => avalon_startofpacket,
            avalon_endofpacket => avalon_endofpacket,
            gmii_txd => gmii_txd,
            gmii_txen => gmii_txen,
            gmii_txer => gmii_txer
            --gmii_clk => gmii_clk
        );

    clk_process : PROCESS
    BEGIN
            clk <= '1';
            WAIT FOR CLK_PERIOD / 2;
            clk <= '0';
            WAIT FOR CLK_PERIOD / 2;
    END PROCESS;

    --gmii_clk_process : PROCESS
    --BEGIN
            --gmii_clk <= '1';
            --WAIT FOR GMII_CLK_PERIOD / 2;
            --gmii_clk <= '0';
            --WAIT FOR GMII_CLK_PERIOD / 2;
    --END PROCESS;

    --avalon_clk_process : PROCESS
    --BEGIN
            --avalon_clk <= '1';
           -- WAIT FOR CLK_PERIOD;
            --avalon_clk <= '0';
            --WAIT FOR CLK_PERIOD;
    --END PROCESS;

    stim_proc: PROCESS
    BEGIN
        reset <= '1';
        avalon_startofpacket <= '0';
        avalon_endofpacket <= '0';
        avalon_valid <= '0';
        gmii_txen <= '0';
        gmii_txer <= '0';
        WAIT FOR 10 ns;

        reset <= '0';
	WAIT FOR 40 ns;

	avalon_startofpacket <= '1';
        avalon_valid <= '1';
        avalon_data <= x"D0D1D2D3D4D5D6D7"; 
        WAIT FOR 10 ns;

        gmii_txen <= '1';
        --gmii_txd <= x"55";
        WAIT FOR 70 ns;

        avalon_startofpacket <= '0';
        avalon_data <= x"D8D9DADBDCDDDEDF";
        --gmii_txd <= x"D5";
        WAIT FOR 80 ns;


	avalon_data <= x"E0E1E2E3E4E5E6E7";
	--gmii_txd <= x"D7";
        WAIT FOR 80 ns;
 
	avalon_data <= x"E8E9EAEBECEDEEEF";
	--gmii_txd <= x"DF";
        WAIT FOR 80 ns;

	

	avalon_data <= x"F0F1F2F3F4F5F6F7";
	--gmii_txd <= x"E7"; 
	WAIT FOR 80 ns;
	
	avalon_data <= x"F8F9FAFBFCFDFEFF";
        --gmii_txd <= x"EF"; 
 	WAIT FOR 80 ns;

	avalon_data <= x"0001020304050607";
        --gmii_txd <= x"F7"; 
 	WAIT FOR 80 ns;

	avalon_data <= x"08090A0B0C0D0E0F";
        --gmii_txd <= x"FF"; 
	avalon_endofpacket <= '1';
 	WAIT FOR 10 ns;


	--gmii_txd <= x"06"; 
	avalon_endofpacket <= '0';
	avalon_valid <= '0';
 	WAIT FOR 10 ns;

	gmii_txen <= '0';
	
    END PROCESS;

END ARCHITECTURE behavior;
