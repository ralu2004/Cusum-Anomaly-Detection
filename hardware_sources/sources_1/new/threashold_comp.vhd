library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  

entity threashold_comp is
    Port ( clk : in STD_LOGIC;
           threshold_tvalid : in STD_LOGIC;
           threshold_tready : out STD_LOGIC;
           threshold_tdata : in STD_LOGIC_VECTOR (31 downto 0);
           g_plus_tvalid : in STD_LOGIC;
           g_plus_tready : out STD_LOGIC;
           g_plus_tdata : in STD_LOGIC_VECTOR (31 downto 0);
           g_minus_tvalid : in STD_LOGIC;
           g_minus_tready : out STD_LOGIC;
           g_minus_tdata : in STD_LOGIC_VECTOR (31 downto 0);
           label_tvalid : out STD_LOGIC;
           label_tready : in STD_LOGIC;
           label_tdata : out STD_LOGIC;
           g_plus_out_tvalid : out STD_LOGIC;
           g_plus_out_tready : in STD_LOGIC;
           g_plus_out_tdata : out STD_LOGIC_VECTOR (31 downto 0);
           g_minus_out_tvalid : out STD_LOGIC;
           g_minus_out_tready : in STD_LOGIC;
           g_minus_out_tdata : out STD_LOGIC_VECTOR (31 downto 0));
end threashold_comp;

architecture Behavioral of threashold_comp is

    type state_type is (S_READ, S_WRITE);
    signal state : state_type := S_READ;
    
    signal internal_ready, external_ready, inputs_valid : STD_LOGIC := '0';
    
    signal label_result : STD_LOGIC := '0';
    signal g_plus_result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal g_minus_result : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

begin
    threshold_tready <= external_ready;
    g_plus_tready <= external_ready;
    g_minus_tready <= external_ready;
    
    internal_ready <= '1' when state = S_READ else '0';
    inputs_valid <= threshold_tvalid and g_plus_tvalid and g_minus_tvalid;
    external_ready <= internal_ready and inputs_valid;
    
    label_tvalid <= '1' when state = S_WRITE else '0';
    g_plus_out_tvalid <= '1' when state = S_WRITE else '0';
    g_minus_out_tvalid <= '1' when state = S_WRITE else '0';
    
    label_tdata <= label_result;
    g_plus_out_tdata <= g_plus_result;
    g_minus_out_tdata <= g_minus_result;
    
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when S_READ =>
                    if external_ready = '1' and inputs_valid = '1' then
                        
                        if (g_plus_tdata > threshold_tdata) or (g_minus_tdata > threshold_tdata) then
                            label_result <= '1';  
                            g_plus_result <= (others => '0');  
                            g_minus_result <= (others => '0');
                        else
                            label_result <= '0';  
                            g_plus_result <= g_plus_tdata;    
                            g_minus_result <= g_minus_tdata;  
                        end if;
                        
                        state <= S_WRITE;
                    end if;    
                
                when S_WRITE =>
                    if label_tready = '1' and g_plus_out_tready = '1' and g_minus_out_tready = '1' then
                        state <= S_READ;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;