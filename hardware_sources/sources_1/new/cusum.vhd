library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity cusum is
    Generic(
        drift: std_logic_vector(31 downto 0) := x"00000032";
        threshold: std_logic_vector(31 downto 0) := x"000000C8"
    );
    Port ( 
        -- xt
        x_t_tdata : in std_logic_vector(31 downto 0);
        x_t_tvalid : in std_logic;
        x_t_tready : out std_logic;
        -- xt-1
        x_t_1_tdata: in std_logic_vector(31 downto 0);
        x_t_1_tvalid : in std_logic;
        x_t_1_tready : out std_logic;
        --control signals
        clk : in std_logic;
        aresetn : in std_logic;
        --output label
        label_tdata: out std_logic;
        label_tvalid : out std_logic;   
        label_tready : in std_logic
    );
end cusum;

architecture Behavioral of cusum is

    COMPONENT fifo
        PORT (
            s_axis_aresetn : IN STD_LOGIC;
            s_axis_aclk : IN STD_LOGIC;
            s_axis_tvalid : IN STD_LOGIC;
            s_axis_tready : OUT STD_LOGIC;
            s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_tvalid : OUT STD_LOGIC;
            m_axis_tready : IN STD_LOGIC;
            m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
        );
    END COMPONENT;

    COMPONENT broadcaster
        PORT (
            aclk : IN STD_LOGIC;
            aresetn : IN STD_LOGIC;
            s_axis_tvalid : IN STD_LOGIC;
            s_axis_tready : OUT STD_LOGIC;
            s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_tvalid : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axis_tready : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0) 
        );
    END COMPONENT;

    component int_adder_subtractor is
        Port ( 
            aclk : IN STD_LOGIC;
            s_axis_a_tvalid : IN STD_LOGIC;
            s_axis_a_tready : OUT STD_LOGIC;
            s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_b_tvalid : IN STD_LOGIC;
            s_axis_b_tready : OUT STD_LOGIC;
            s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_operation_tvalid : IN STD_LOGIC;
            s_axis_operation_tready : OUT STD_LOGIC;
            s_axis_operation_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC;
            m_axis_result_tready : IN STD_LOGIC;
            m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    component max is
        Port ( 
            aclk : IN STD_LOGIC;
            s_axis_a_tvalid : IN STD_LOGIC;
            s_axis_a_tready : OUT STD_LOGIC;
            s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axis_result_tvalid : OUT STD_LOGIC;
            m_axis_result_tready : IN STD_LOGIC;
            m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;
    
    component threashold_comp is
        Port ( 
            clk : in STD_LOGIC;
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
            g_minus_out_tdata : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;

    signal x_t_out_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal x_t_out_tvalid : std_logic := '0';
    signal x_t_out_tready : std_logic := '0';
    
    signal x_t_1_out_tdata: std_logic_vector(31 downto 0) := (others => '0');
    signal x_t_1_out_tvalid : std_logic := '0';
    signal x_t_1_out_tready : std_logic := '0';
    
    signal fifo_sub_out_tdata: std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_sub_out_tvalid : std_logic := '0';
    signal fifo_sub_out_tready : std_logic := '0'; 
    
    signal fifo_add_out_tdata: std_logic_vector(31 downto 0) := (others => '0');
    signal fifo_add_out_tvalid : std_logic := '0';
    signal fifo_add_out_tready : std_logic := '0'; 
    
    signal g_plus_in_tdata, g_minus_in_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_plus_in_tvalid, g_minus_in_tvalid : std_logic := '0';
    signal g_plus_in_tready, g_minus_in_tready : std_logic := '0';
    
    signal g_plus_bout_tdata, g_minus_bout_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_plus_bout_tvalid, g_minus_bout_tvalid : std_logic := '0';
    signal g_plus_bout_tready, g_minus_bout_tready : std_logic := '0';
    
    signal x_t_sub_x_t_1_tdata, sub_drift_up_tdata, sub_drift_down_tdata, drift_down_tdata, drift_up_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal x_t_sub_x_t_1_tvalid, sub_drift_up_tvalid, sub_drift_down_tvalid, drift_down_tvalid, drift_up_tvalid : std_logic := '0'; 
    signal x_t_sub_x_t_1_tready, sub_drift_up_tready, sub_drift_down_tready, drift_down_tready, drift_up_tready : std_logic := '0';
    signal op_ready_1, op_ready_2, op_ready_3, op_ready_4, op_ready_5, drift_ready, threshold_ready : std_logic := '0';
    
    signal x_t_sub_x_t_1_tdata_brd, drift_tdata : std_logic_vector(63 downto 0) := (others => '0');
    signal x_t_sub_x_t_1_tvalid_brd,  drift_tvalid : std_logic_vector(1 downto 0) := (others => '0');
    signal x_t_sub_x_t_1_tready_brd,  drift_tready : std_logic_vector(1 downto 0) := (others => '0');
    
    signal out_add_tdata: std_logic_vector(31 downto 0) := (others => '0');
    signal out_add_tvalid : std_logic := '0';  
    signal out_add_tready : std_logic := '0';  
     
    signal out_sub_tdata: std_logic_vector(31 downto 0) := (others => '0'); 
    signal out_sub_tvalid : std_logic := '0'; 
    signal out_sub_tready : std_logic := '0'; 
    
    signal g_plus_t_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_plus_t_tvalid : std_logic := '0';
    signal g_plus_t_tready : std_logic := '0';
    
    signal g_minus_t_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_minus_t_tvalid : std_logic := '0';
    signal g_minus_t_tready : std_logic := '0';
    
    signal g_plus_t_1_out_tdata, x_t_1_fifo_out_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_plus_t_1_out_tvalid, x_t_1_fifo_out_tvalid : std_logic := '0';
    signal g_plus_t_1_out_tready, x_t_1_fifo_out_tready : std_logic := '0';
    
    signal g_minus_t_1_out_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal g_minus_t_1_out_tvalid : std_logic := '0';
    signal g_minus_t_1_out_tready : std_logic := '0';
    
    signal inject_zero_up : std_logic := '1';
    signal inject_zero_down : std_logic := '1';
    
    signal temp_g_plus_t_tvalid : std_logic := '0';
    signal temp_g_plus_t_tdata: std_logic_vector(31 downto 0) := (others => '0');
    signal temp_g_minus_t_tvalid : std_logic := '0';
    signal temp_g_minus_t_tdata: std_logic_vector(31 downto 0) := (others => '0');
 
begin

    -- input FIFOs for x_t and x_t_1
    fifo_x_t : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => x_t_tvalid,  
            s_axis_tready => x_t_tready,  
            s_axis_tdata => x_t_tdata,  
            m_axis_tvalid => x_t_out_tvalid,     
            m_axis_tready => x_t_out_tready,      
            m_axis_tdata => x_t_out_tdata     
        );
    
    fifo_x_t_1 : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => x_t_1_tvalid,  
            s_axis_tready => x_t_1_tready,  
            s_axis_tdata => x_t_1_tdata,  
            m_axis_tvalid => x_t_1_out_tvalid,     
            m_axis_tready => x_t_1_out_tready,      
            m_axis_tdata => x_t_1_out_tdata  
        );
    
    -- x_t - x_t_1
    x_t_sub_x_t_1 : int_adder_subtractor
        Port map ( 
            aclk => clk,
            s_axis_a_tvalid => x_t_out_tvalid,      
            s_axis_a_tready => x_t_out_tready,      
            s_axis_a_tdata => x_t_out_tdata,        
            s_axis_b_tvalid => x_t_1_out_tvalid,      
            s_axis_b_tready => x_t_1_out_tready,      
            s_axis_b_tdata => x_t_1_out_tdata,        
            s_axis_operation_tvalid => '1',
            s_axis_operation_tready => op_ready_1,
            s_axis_operation_tdata => "00000001",  -- (-)
            m_axis_result_tvalid => x_t_sub_x_t_1_tvalid, 
            m_axis_result_tready => x_t_sub_x_t_1_tready, 
            m_axis_result_tdata => x_t_sub_x_t_1_tdata
        );
    
    fifo_x_t_minus_x_t_1 : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => x_t_sub_x_t_1_tvalid,  
            s_axis_tready => x_t_sub_x_t_1_tready,  
            s_axis_tdata => x_t_sub_x_t_1_tdata,  
            m_axis_tvalid => x_t_1_fifo_out_tvalid,     
            m_axis_tready => x_t_1_fifo_out_tready,      
            m_axis_tdata => x_t_1_fifo_out_tdata  
        );
        
    -- broadcast (x_t - x_t_1) 
    broadcaster_x : broadcaster
        PORT MAP (
            aclk => clk,
            aresetn => aresetn,
            s_axis_tvalid => x_t_1_fifo_out_tvalid,           
            s_axis_tready => x_t_1_fifo_out_tready,
            s_axis_tdata => x_t_1_fifo_out_tdata,
            m_axis_tvalid => x_t_sub_x_t_1_tvalid_brd,
            m_axis_tready => x_t_sub_x_t_1_tready_brd,
            m_axis_tdata => x_t_sub_x_t_1_tdata_brd
        );
    
    -- compute g_plus_t_1 + (x_t - x_t_1)
    g_plus_t_1_add : int_adder_subtractor
        Port map ( 
            aclk => clk,
            s_axis_a_tvalid => g_plus_t_1_out_tvalid,      
            s_axis_a_tready => g_plus_t_1_out_tready,      
            s_axis_a_tdata => g_plus_t_1_out_tdata,        
            s_axis_b_tvalid => x_t_sub_x_t_1_tvalid_brd(1),      
            s_axis_b_tready => x_t_sub_x_t_1_tready_brd(1),      
            s_axis_b_tdata => x_t_sub_x_t_1_tdata_brd(63 downto 32),        
            s_axis_operation_tvalid => '1',
            s_axis_operation_tready => op_ready_2,
            s_axis_operation_tdata => "00000000",  -- (+)
            m_axis_result_tvalid => out_add_tvalid, 
            m_axis_result_tready => out_add_tready, 
            m_axis_result_tdata => out_add_tdata
        );
    
    -- compute g_minus_t_1 - (x_t - x_t_1)
    g_minus_t_1_sub : int_adder_subtractor
        Port map ( 
            aclk => clk,
            s_axis_a_tvalid => g_minus_t_1_out_tvalid,      
            s_axis_a_tready => g_minus_t_1_out_tready,      
            s_axis_a_tdata => g_minus_t_1_out_tdata,        
            s_axis_b_tvalid => x_t_sub_x_t_1_tvalid_brd(0),      
            s_axis_b_tready => x_t_sub_x_t_1_tready_brd(0),      
            s_axis_b_tdata => x_t_sub_x_t_1_tdata_brd(31 downto 0),        
            s_axis_operation_tvalid => '1',
            s_axis_operation_tready => op_ready_3,
            s_axis_operation_tdata => "00000001",  -- (-)
            m_axis_result_tvalid => out_sub_tvalid, 
            m_axis_result_tready => out_sub_tready, 
            m_axis_result_tdata => out_sub_tdata
        );
    
    fifo_out_add : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => out_add_tvalid,  
            s_axis_tready => out_add_tready,  
            s_axis_tdata => out_add_tdata,  
            m_axis_tvalid => fifo_add_out_tvalid,     
            m_axis_tready => fifo_add_out_tready,      
            m_axis_tdata => fifo_add_out_tdata     
        );
    
    fifo_out_sub : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => out_sub_tvalid,  
            s_axis_tready => out_sub_tready,  
            s_axis_tdata => out_sub_tdata,  
            m_axis_tvalid => fifo_sub_out_tvalid,     
            m_axis_tready => fifo_sub_out_tready,      
            m_axis_tdata => fifo_sub_out_tdata     
        );
    
    -- broadcast drift 
    broadcaster_drift : broadcaster
        PORT MAP (
            aclk => clk,
            aresetn => aresetn,
            s_axis_tvalid => '1',
            s_axis_tready => drift_ready,
            s_axis_tdata => drift,
            m_axis_tvalid => drift_tvalid,
            m_axis_tready => drift_tready,
            m_axis_tdata => drift_tdata
        );
    
    -- subtract drift from first sum
    sum_drift_sub : int_adder_subtractor
        Port map ( 
            aclk => clk,
            s_axis_a_tvalid => fifo_add_out_tvalid,      
            s_axis_a_tready => fifo_add_out_tready,      
            s_axis_a_tdata => fifo_add_out_tdata,        
            s_axis_b_tvalid => drift_tvalid(1),      
            s_axis_b_tready => drift_tready(1),      
            s_axis_b_tdata => drift_tdata(63 downto 32),        
            s_axis_operation_tvalid => '1',
            s_axis_operation_tready => op_ready_4,
            s_axis_operation_tdata => "00000001",  -- (-)
            m_axis_result_tvalid => sub_drift_up_tvalid, 
            m_axis_result_tready => sub_drift_up_tready, 
            m_axis_result_tdata => sub_drift_up_tdata
        );
    
    -- subtract drift from second difference
    diff_drift_sub : int_adder_subtractor
        Port map ( 
            aclk => clk,
            s_axis_a_tvalid => fifo_sub_out_tvalid,      
            s_axis_a_tready => fifo_sub_out_tready,      
            s_axis_a_tdata => fifo_sub_out_tdata,        
            s_axis_b_tvalid => drift_tvalid(0),      
            s_axis_b_tready => drift_tready(0),      
            s_axis_b_tdata => drift_tdata(31 downto 0),        
            s_axis_operation_tvalid => '1',
            s_axis_operation_tready => op_ready_5,
            s_axis_operation_tdata => "00000001",  -- (-)
            m_axis_result_tvalid => sub_drift_down_tvalid, 
            m_axis_result_tready => sub_drift_down_tready, 
            m_axis_result_tdata => sub_drift_down_tdata
        );
    
    fifo_drift_up : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => sub_drift_up_tvalid,  
            s_axis_tready => sub_drift_up_tready,  
            s_axis_tdata => sub_drift_up_tdata,  
            m_axis_tvalid => drift_up_tvalid,     
            m_axis_tready => drift_up_tready,      
            m_axis_tdata => drift_up_tdata     
        );
    
    fifo_drift_down : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => sub_drift_down_tvalid,  
            s_axis_tready => sub_drift_down_tready,  
            s_axis_tdata => sub_drift_down_tdata,  
            m_axis_tvalid => drift_down_tvalid,     
            m_axis_tready => drift_down_tready,      
            m_axis_tdata => drift_down_tdata     
        );
    
    -- max(0, g_plus)
    max_up : max
        port map(
            aclk => clk,
            s_axis_a_tvalid => drift_up_tvalid,
            s_axis_a_tready => drift_up_tready,
            s_axis_a_tdata => drift_up_tdata,
            m_axis_result_tvalid => g_plus_in_tvalid,
            m_axis_result_tready => g_plus_in_tready, 
            m_axis_result_tdata => g_plus_in_tdata
        );
    
    -- max(0, g_minus)
    max_down : max
        port map(
            aclk => clk,
            s_axis_a_tvalid => drift_down_tvalid,
            s_axis_a_tready => drift_down_tready,
            s_axis_a_tdata => drift_down_tdata,
            m_axis_result_tvalid => g_minus_in_tvalid,
            m_axis_result_tready => g_minus_in_tready, 
            m_axis_result_tdata => g_minus_in_tdata
        );
    
    -- max values FIFOs
    fifo_g_plus : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => g_plus_in_tvalid,  
            s_axis_tready => g_plus_in_tready,  
            s_axis_tdata => g_plus_in_tdata,  
            m_axis_tvalid => g_plus_bout_tvalid,     
            m_axis_tready => g_plus_bout_tready,      
            m_axis_tdata => g_plus_bout_tdata     
        );
    
    fifo_g_minus : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => g_minus_in_tvalid,  
            s_axis_tready => g_minus_in_tready,  
            s_axis_tdata => g_minus_in_tdata,  
            m_axis_tvalid => g_minus_bout_tvalid,     
            m_axis_tready => g_minus_bout_tready,      
            m_axis_tdata => g_minus_bout_tdata     
        );
    
    -- threshold comparison and output generation
    threshold_comparator : threashold_comp
        port map (
            clk => clk,
            threshold_tvalid => '1',
            threshold_tready => threshold_ready,
            threshold_tdata => threshold,
            g_plus_tvalid => g_plus_bout_tvalid,
            g_plus_tready => g_plus_bout_tready,
            g_plus_tdata => g_plus_bout_tdata,
            g_minus_tvalid => g_minus_bout_tvalid,
            g_minus_tready => g_minus_bout_tready,
            g_minus_tdata => g_minus_bout_tdata,
            label_tvalid => label_tvalid,
            label_tready => label_tready,
            label_tdata => label_tdata,
            g_plus_out_tvalid => g_plus_t_tvalid,
            g_plus_out_tready => g_plus_t_tready,
            g_plus_out_tdata => g_plus_t_tdata,
            g_minus_out_tvalid => g_minus_t_tvalid,
            g_minus_out_tready => g_minus_t_tready,
            g_minus_out_tdata => g_minus_t_tdata
        );
    
    -- zero injection for g_plus feedback
    process(clk)
    begin
        if rising_edge(clk) then
            if aresetn = '0' then
                inject_zero_up <= '1';
            else
                if g_plus_t_tready = '1' then
                    if inject_zero_up = '1' then
                        inject_zero_up <= '0';
                        temp_g_plus_t_tdata  <= (others => '0');
                        temp_g_plus_t_tvalid <= '1';
                    else
                        temp_g_plus_t_tdata <= g_plus_t_tdata;
                        temp_g_plus_t_tvalid <= g_plus_t_tvalid;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- zero injection for g_minus feedback
    process(clk)
    begin
        if rising_edge(clk) then
            if aresetn = '0' then
                inject_zero_down <= '1';
            else
                if g_minus_t_tready = '1' then
                    if inject_zero_down = '1' then
                        inject_zero_down <= '0';
                        temp_g_minus_t_tdata  <= (others => '0');
                        temp_g_minus_t_tvalid <= '1';
                    else
                        temp_g_minus_t_tdata <= g_minus_t_tdata;
                        temp_g_minus_t_tvalid <= g_minus_t_tvalid;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- feedback FIFOs
    fifo_g_plus_t_1 : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => temp_g_plus_t_tvalid,  
            s_axis_tready => g_plus_t_tready,  
            s_axis_tdata => temp_g_plus_t_tdata,  
            m_axis_tvalid => g_plus_t_1_out_tvalid,     
            m_axis_tready => g_plus_t_1_out_tready,      
            m_axis_tdata => g_plus_t_1_out_tdata     
        );
    
    fifo_g_minus_t_1 : fifo
        PORT MAP (
            s_axis_aresetn => aresetn,  
            s_axis_aclk => clk,
            s_axis_tvalid => temp_g_minus_t_tvalid,  
            s_axis_tready => g_minus_t_tready,  
            s_axis_tdata => temp_g_minus_t_tdata,  
            m_axis_tvalid => g_minus_t_1_out_tvalid,     
            m_axis_tready => g_minus_t_1_out_tready,      
            m_axis_tdata => g_minus_t_1_out_tdata     
        );

end Behavioral;