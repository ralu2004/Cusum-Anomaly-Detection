library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;

entity testbench is
end testbench;

architecture Behavioral of testbench is
component cusum is
    Generic(
        drift: std_logic_vector(31 downto 0) := x"00000032";
        threshold: std_logic_vector(31 downto 0) := x"000000C8"
    );
    Port ( 
        -- Data inputs
        x_t_tdata : in std_logic_vector(31 downto 0);
        x_t_tvalid : in std_logic;
        x_t_tready : out std_logic;
        x_t_1_tdata: in std_logic_vector(31 downto 0);
        x_t_1_tvalid : in std_logic;
        x_t_1_tready : out std_logic;
        
        -- Control signals
        clk : in std_logic;
        aresetn : in std_logic;
        
        -- Output
        label_tdata: out std_logic;
        label_tvalid : out std_logic;   
        label_tready : in std_logic
    );
end component;

Signal s_axis_x_t_tdata, s_axis_x_t_1_tdata: std_logic_vector(31 downto 0) := (others => '0');
Signal s_axis_x_t_tvalid, s_axis_x_t_tready, s_axis_x_t_1_tvalid, s_axis_x_t_1_tready: std_logic := '0';
Signal s_axis_aclk: std_logic := '0';
Signal s_axis_aresetn: std_logic := '0';
Signal s_axis_detect_tdata, s_axis_detect_tvalid: std_logic := '0';
Signal s_axis_detect_tready: std_logic := '1';
signal end_of_reading : std_logic := '0';
signal rd_count, wr_count : integer := 0;

constant T: time := 20ns;

signal last_tdata: std_logic_vector(31 downto 0);

begin

    dut:
        cusum generic map (
            drift => x"00000032",
            threshold => x"000000C8"
        )
        port map(
            x_t_tdata => s_axis_x_t_tdata,
            x_t_tvalid => s_axis_x_t_tvalid,
            x_t_tready => s_axis_x_t_tready,
            x_t_1_tdata => s_axis_x_t_1_tdata,
            x_t_1_tvalid => s_axis_x_t_1_tvalid,
            x_t_1_tready => s_axis_x_t_1_tready,
            clk => s_axis_aclk,
            aresetn => s_axis_aresetn,
            label_tdata => s_axis_detect_tdata,
            label_tvalid => s_axis_detect_tvalid,
            label_tready => s_axis_detect_tready  
        );
        
    reset: process
    begin
        s_axis_aresetn <= '0';
        wait for 50ns;
        s_axis_aresetn <= '1';
        wait;
    end process;
    
    s_axis_detect_tready <= '1';
    s_axis_aclk <= not s_axis_aclk after T / 2;
    
    read_file: process(s_axis_aclk)
        file test_data : text open read_mode is "integer_values\LM35DZ_int.csv";
        variable in_line : line;
        variable val: integer;
        variable space : character;
        variable comma : character;
    begin
         if rising_edge(s_axis_aclk) then
            if end_of_reading = '0' then 
                if not endfile(test_data) then  
                    if rd_count = 0 then
                        readline(test_data, in_line);
                        read(in_line, val);
                        last_tdata <= std_logic_vector(to_signed(val, 32));
                        rd_count <= rd_count + 1;
                    else
                       if s_axis_x_t_tready = '1' and s_axis_x_t_1_tready = '1' then
                            readline(test_data, in_line);
                            read(in_line, val);
                            s_axis_x_t_1_tdata <= last_tdata;
                            s_axis_x_t_1_tvalid <= '1';
                            s_axis_x_t_tdata <= std_logic_vector(to_signed(val, 32));
                            s_axis_x_t_tvalid <= '1';
                            last_tdata <= std_logic_vector(to_signed(val, 32));
                            rd_count <= rd_count + 1;
                       end if;
                    end if;
                else
                    file_close(test_data);
                    end_of_reading <= '1';
                end if;   
            end if;
         end if;
    end process;
        
    write_file: process
        file results : text open write_mode is "hardware_detection_output\LM35DZ_labels.csv";
        variable out_line : line;
        variable header_written : boolean := false;
    begin
        wait until rising_edge(s_axis_aclk);
        
        if not header_written then
            write(out_line, string'("index, label"));
            writeline(results, out_line);
            header_written := true;
        end if;
    
        if wr_count <= rd_count then
            if s_axis_detect_tvalid = '1' then   
                write(out_line, wr_count + 1);
                write(out_line, string'(", "));
                write(out_line, s_axis_detect_tdata);
                writeline(results, out_line);
               
                wr_count <= wr_count + 1;
            end if;
        else
            file_close(results);
            report "execution finished...";
            wait;
        end if;

    end process;

end Behavioral;
