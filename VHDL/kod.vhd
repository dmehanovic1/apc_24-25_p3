LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY GMII_tx IS
PORT (
	part0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part3 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part4 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part5 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part6 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	part7 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	data_counter : OUT integer range 0 to 255 := 0;
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
	gmii_txer : OUT STD_LOGIC;
	dummy : OUT STD_LOGIC
);
END ENTITY GMII_tx;

ARCHITECTURE arch OF GMII_tx IS 
	TYPE STATE_TYPE IS (IDLE,SEND_HEAD,SEND_DATA,SEND_ERROR);
	SIGNAL current_state: STATE_TYPE;
BEGIN

	internal_counter <= (OTHERS => '0');
	counter: PROCESS(reset, clk)
	BEGIN
		IF reset = '1' THEN
			internal_counter <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			internal_counter <= std_logic_vector(to_unsigned(internal_counter)+1);
		ELSE dummy <= '1';
		END IF;
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
			END IF;
		ELSIF avalon_startofpacket = '0' and avalon_valid = '1' THEN
			IF current_state = SEND_HEAD THEN
				current_state <= SEND_DATA;
			END IF;
		ELSIF gmii_txer = '1' THEN
			IF current_state = SEND_DATA THEN
				current_state <= SEND_ERROR;
			END IF;
		ELSIF gmii_txer = '0' THEN
			IF current_state = SEND_ERROR THEN
				current_state <= SEND_DATA;
			END IF;
		END IF;
	END PROCESS;
	
	output_signals: PROCESS(ALL)
	BEGIN
		IF rising_edge (avalon_clk ) THEN 
			part7 <= avalon_data(7 downto 0);       
			part6 <= avalon_data(15 downto 8);      
			part5 <= avalon_data(23 downto 16);     
			part4<= avalon_data(31 downto 24);  
			part3<= avalon_data(39 downto 32);     
			part2 <= avalon_data(47 downto 40);     
			part1 <= avalon_data(55 downto 48);     
			part0 <= avalon_data(63 downto 56); 
			END IF;
		CASE current_state IS
			WHEN IDLE =>
				gmii_txen <= '0';
				gmii_txer <='0';
				avalon_endofpacket <= '0';
				avalon_valid <= '0';
			WHEN SEND_HEAD =>
				IF internal_counter = b"111" THEN 
						gmii_txd <= x"d5";
				ELSE	
						gmii_txd <= x"55";
				END IF;
				gmii_txen <= '1';
				avalon_endofpacket <= '0';
				avalon_valid <= '1';
				gmii_txer <='0';
				
			WHEN SEND_DATA =>
					IF rising_edge (gmii_clk) THEN 
						IF data_counter = 0 THEN 
							gmii_txd <= part0;
						ELSIF data_counter = 1 THEN 
							gmii_txd <= part1;
						ELSIF data_counter = 2 THEN 
							gmii_txd <= part2;
						ELSIF data_counter = 3 THEN 
							gmii_txd <= part3;
						ELSIF data_counter = 4 THEN 
							gmii_txd <= part4;
						ELSIF data_counter = 5 THEN 
							gmii_txd <= part5;
						ELSIF data_counter = 6 THEN 
							gmii_txd <= part6;
						ELSIF data_counter = 7 THEN 
							gmii_txd <= part7;
						ELSE   
							data_counter <= 0;
						END IF;
					END IF;
				gmii_txer <= '0';
				gmii_txen <= '1';
				avalon_endofpacket <= '0';
				avalon_valid <= '1';
			WHEN SEND_ERROR =>
				gmii_txd <= x"0e";
				gmii_txer <='1';
				gmii_txen <='1';
				avlaon_valid <='0';
				avalon_endofpacket <= '0';
				
		END CASE;
	END PROCESS;
	
END ARCHITECTURE arch;
