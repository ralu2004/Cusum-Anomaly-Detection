library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    Port ( btn_inc : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           cat : out STD_LOGIC_VECTOR (6 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0));
end top;

architecture Behavioral of top is

component cusum is
    Generic(
        drift: std_logic_vector(31 downto 0) := x"00000032";
        threshold: std_logic_vector(31 downto 0) := x"000000C8"
    );
    Port ( 
        x_t_tdata : in std_logic_vector(31 downto 0);
        x_t_tvalid : in std_logic;
        x_t_tready : out std_logic;
        x_t_1_tdata: in std_logic_vector(31 downto 0);
        x_t_1_tvalid : in std_logic;
        x_t_1_tready : out std_logic;
        clk : in std_logic;
        aresetn : in std_logic;
        label_tdata: out std_logic;
        label_tvalid : out std_logic;   
        label_tready : in std_logic
    );
end component;

component debouncer is
  Port ( clk : in std_logic;
        btn : in std_logic;
        en : out std_logic );
end component;

component display_7seg is
    Port ( digit0 : in STD_LOGIC_VECTOR (3 downto 0);
           digit1 : in STD_LOGIC_VECTOR (3 downto 0);
           digit2 : in STD_LOGIC_VECTOR (3 downto 0);
           digit3 : in STD_LOGIC_VECTOR (3 downto 0);
           clk : in STD_LOGIC;
           cat : out STD_LOGIC_VECTOR (6 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component counter is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           count : out STD_LOGIC_VECTOR (10 downto 0));
end component;

component rom_memory is
    Port ( addr : in STD_LOGIC_VECTOR (10 downto 0);
           dout_curr : out STD_LOGIC_VECTOR (31 downto 0);
           dout_prev : out STD_LOGIC_VECTOR (31 downto 0));
end component;

signal debounce: std_logic := '0';
signal address: std_logic_vector(10 downto 0) := (others => '0');
signal curr, prev: std_logic_vector(31 downto 0) := (others => '0');
signal curr_valid, prev_valid: std_logic := '1';
signal curr_ready, prev_ready: std_logic := '0';
signal not_rst: std_logic := not rst;
signal label_data: std_logic := '0';
signal label_valid: std_logic := '0';
signal label_ready: std_logic := '1';
signal label_display, high_address: std_logic_vector(3 downto 0) := "0000";

begin

    debouncer_inst : debouncer
    port map (
        clk => clk,
        btn => btn_inc,
        en  => debounce
    );

    counter_inst : counter
    port map (
        clk   => clk,
        rst   => rst,
        en    => debounce,
        count => address
    );
    
    rom_inst : rom_memory
    port map (
        addr      => address,
        dout_curr => curr,
        dout_prev => prev
    );
    
    cusum_inst : cusum
    generic map (
        drift     => x"00000032",
        threshold => x"000000C8"
    )
    port map (
        x_t_tdata     => curr,
        x_t_tvalid    => curr_valid,
        x_t_tready    => curr_ready,
        x_t_1_tdata   => prev,
        x_t_1_tvalid  => prev_valid,
        x_t_1_tready  => prev_ready,
        clk           => clk,
        aresetn       => not_rst,  
        label_tdata   => label_data,
        label_tvalid  => label_valid,
        label_tready  => label_ready
    );
    
    label_display <= "000" & label_data;
    high_address <= '0' & address(10 downto 8);
    
    display_inst : display_7seg
    port map (
        digit0 => label_display,
        digit1 => address(3 downto 0),
        digit2 => address(7 downto 4),
        digit3 => high_address,
        clk    => clk,
        cat    => cat,
        an     => an
    );

end Behavioral;
