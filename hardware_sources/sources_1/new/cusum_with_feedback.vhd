--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity cusum_with_feedback is
--    Port ( 
--        -- Data inputs (streaming interface)
--        x_t_tdata : in std_logic_vector(31 downto 0);
--        x_t_tvalid : in std_logic;
--        x_t_tready : out std_logic;
--        x_t_1_tdata : in std_logic_vector(31 downto 0);  -- x_{t-1} as input
--        x_t_1_tvalid : in std_logic;
--        x_t_1_tready : out std_logic;
        
--        -- Parameters
--        clk : in std_logic;
--        aresetn : in std_logic;
--        drift : in std_logic_vector(31 downto 0);
--        threshold : in std_logic_vector(31 downto 0); 
        
--        -- Outputs
--        label_tdata: out std_logic;
--        label_tvalid : out std_logic;   
--        label_tready : in std_logic
--    );
--end cusum_with_feedback;

--architecture Behavioral of cusum_with_feedback is

--    signal g_plus_t_1_tdata : std_logic_vector(31 downto 0) := (others => '0');
--    signal g_plus_t_1_tvalid : std_logic := '0';
--    signal g_plus_t_1_tready : std_logic := '0';
    
--    signal g_minus_t_1_tdata : std_logic_vector(31 downto 0) := (others => '0');
--    signal g_minus_t_1_tvalid : std_logic := '0';
--    signal g_minus_t_1_tready : std_logic := '0';
    
--    signal g_plus_t_tdata : std_logic_vector(31 downto 0);
--    signal g_plus_t_tvalid : std_logic := '0';
--    signal g_plus_t_tready : std_logic := '1';
    
--    signal g_minus_t_tdata : std_logic_vector(31 downto 0);
--    signal g_minus_t_tvalid : std_logic := '0';
--    signal g_minus_t_tready : std_logic := '1';
    
--    signal g_plus_feedback_reg, g_minus_feedback_reg : std_logic_vector(31 downto 0) := (others => '0');
    
--    component cusum is
--        Port ( 
--            x_t_tdata : in std_logic_vector(31 downto 0);
--            x_t_tvalid : in std_logic;
--            x_t_tready : out std_logic;
--            x_t_1_tdata: in std_logic_vector(31 downto 0);
--            x_t_1_tvalid : in std_logic;
--            x_t_1_tready : out std_logic;
--            g_plus_t_1_tdata : in std_logic_vector(31 downto 0);
--            g_plus_t_1_tvalid : in std_logic;
--            g_plus_t_1_tready : out std_logic;
--            g_minus_t_1_tdata : in std_logic_vector(31 downto 0);
--            g_minus_t_1_tvalid : in std_logic;
--            g_minus_t_1_tready : out std_logic;
--            clk : in std_logic;
--            aresetn : in std_logic;
--            drift : in std_logic_vector(31 downto 0);
--            threshold : in std_logic_vector(31 downto 0); 
--            label_tdata: out std_logic;
--            label_tvalid : out std_logic;   
--            label_tready : in std_logic;
--            g_plus_t_tdata : out std_logic_vector(31 downto 0);
--            g_plus_t_tvalid : out std_logic;
--            g_plus_t_tready : in std_logic;
--            g_minus_t_tdata : out std_logic_vector(31 downto 0);
--            g_minus_t_tvalid : out std_logic;
--            g_minus_t_tready : in std_logic
--        );
--    end component;

--begin

--    cusum_core: cusum
--        port map (
--            x_t_tdata => x_t_tdata,
--            x_t_tvalid => x_t_tvalid,
--            x_t_tready => x_t_tready,
--            x_t_1_tdata => x_t_1_tdata,  
--            x_t_1_tvalid => x_t_1_tvalid,
--            x_t_1_tready => x_t_1_tready,
--            g_plus_t_1_tdata => g_plus_t_1_tdata,
--            g_plus_t_1_tvalid => g_plus_t_1_tvalid,
--            g_plus_t_1_tready => g_plus_t_1_tready,
--            g_minus_t_1_tdata => g_minus_t_1_tdata,
--            g_minus_t_1_tvalid => g_minus_t_1_tvalid,
--            g_minus_t_1_tready => g_minus_t_1_tready,
--            clk => clk,
--            aresetn => aresetn,
--            drift => drift,
--            threshold => threshold,
--            label_tdata => label_tdata,
--            label_tvalid => label_tvalid,
--            label_tready => label_tready,
--            g_plus_t_tdata => g_plus_t_tdata,
--            g_plus_t_tvalid => g_plus_t_tvalid,
--            g_plus_t_tready => g_plus_t_tready,
--            g_minus_t_tdata => g_minus_t_tdata,
--            g_minus_t_tvalid => g_minus_t_tvalid,
--            g_minus_t_tready => g_minus_t_tready
--        );
    
--    process(clk)
--    begin
--        if rising_edge(clk) then
--            if aresetn = '0' then
--                g_plus_feedback_reg <= (others => '0');
--                g_minus_feedback_reg <= (others => '0');
--            else
--                if g_plus_t_tvalid = '1' and g_plus_t_tready = '1' then
--                    g_plus_feedback_reg <= g_plus_t_tdata;
--                end if;
                
--                if g_minus_t_tvalid = '1' and g_minus_t_tready = '1' then
--                    g_minus_feedback_reg <= g_minus_t_tdata;
--                end if;
--            end if;
--        end if;
--    end process;
    
--    -- Feedback connections
--    g_plus_t_1_tdata <= (others => '0') when aresetn = '0' else g_plus_feedback_reg;
--    g_minus_t_1_tdata <= (others => '0') when aresetn = '0' else g_minus_feedback_reg;
    
--    g_plus_t_1_tvalid <= '1';
--    g_minus_t_1_tvalid <= '1';

--end Behavioral;


