LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY gmii_transmitter IS
PORT (
	clk : IN STD_LOGIC;
	reset : IN STD_LOGIC;
	avalon_clk : OUT STD_LOGIC;
	internal_counter : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
	avalon_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
	avalon_empty : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
	avalon_startofpacket : IN STD_LOGIC;
	avalon_endofpacket : OUT STD_LOGIC;
	avalon_valid : OUT STD_LOGIC;
	gmii_clk : OUT STD_LOGIC;
	gmii_txd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	gmii_txen : OUT STD_LOGIC;
	gmii_txer : OUT STD_LOGIC
);
END ENTITY gmi_transmitter;

ARCHITECTURE arch OF gmii_transmitter IS 
	TYPE STATE_TYPE IS (IDLE,SEND_HEAD,SEND_DATA,SEND_ERROR);
	SIGNAL current_state: STATE_TYPE;
BEGIN
	internal_counter <= (OTHERS => '0');
	counter: PROCESS(reset, clk)
	BEGIN
		IF reset = '1' THEN
			internal_counter <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			internal_counter <= std_logic_vector(unsigned(internal_counter)+1);
	END PROCESS;

	avalon_clock: PROCESS(internal_counter)
	BEGIN
		avalon_clk <= internal_counter(2);
	END PROCESS;
	
	
	fsm: PROCESS(ALL)
	BEGIN
		IF reset = '1' THEN
			current_state <= IDLE;
		ELSIF avalon_startofpacket = '1' and avalon_valid = '1' THEN
			IF current_state = IDLE THEN
				current_state <= SEND_HEAD;
		ELSIF avalon_startofpacket = '0' and avalon_valid = '1' THEN
			IF current_state = SEND_HEAD THEN
				current_state <= SEND_DATA;
		ELSIF gmii_txer = '1' THEN
			IF current_state = SEND_DATA THEN
				current_state <= SEND_ERROR;
		ELSIF gmii_txer = '0' THEN
			IF current_state = SEND_ERROR THEN
				current_state <= SEND_DATA;
	END PROCESS;
	
	output_signals: PROCESS(ALL)
	BEGIN
		CASE current_state IS
			WHEN IDLE =>
				
			WHEN SEND_HEAD =>
			WHEN SEND_DATA =>
			WHEN SEND_ERROR 
		END CASE;
	END PROCESS;
	
END ARCHITECTURE arch;
