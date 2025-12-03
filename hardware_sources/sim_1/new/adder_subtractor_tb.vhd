library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_int_adder_subtractor is
end tb_int_adder_subtractor;

architecture Behavioral of tb_int_adder_subtractor is

    component int_adder_subtractor
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

    constant CLK_PERIOD : time := 10 ns;
    
    signal aclk : STD_LOGIC := '0';
    signal s_axis_a_tvalid, s_axis_b_tvalid, s_axis_operation_tvalid : STD_LOGIC := '0';
    signal s_axis_a_tready, s_axis_b_tready, s_axis_operation_tready : STD_LOGIC;
    signal s_axis_a_tdata, s_axis_b_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    signal s_axis_operation_tdata : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    signal m_axis_result_tvalid, m_axis_result_tready : STD_LOGIC := '0';
    signal m_axis_result_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    signal test_number : integer := 1;
    signal error_count : integer := 0;

begin

    aclk <= not aclk after CLK_PERIOD / 2;

    uut: int_adder_subtractor
        port map (
            aclk => aclk,
            s_axis_a_tvalid => s_axis_a_tvalid,
            s_axis_a_tready => s_axis_a_tready,
            s_axis_a_tdata => s_axis_a_tdata,
            s_axis_b_tvalid => s_axis_b_tvalid,
            s_axis_b_tready => s_axis_b_tready,
            s_axis_b_tdata => s_axis_b_tdata,
            s_axis_operation_tvalid => s_axis_operation_tvalid,
            s_axis_operation_tready => s_axis_operation_tready,
            s_axis_operation_tdata => s_axis_operation_tdata,
            m_axis_result_tvalid => m_axis_result_tvalid,
            m_axis_result_tready => m_axis_result_tready,
            m_axis_result_tdata => m_axis_result_tdata
        );

    stimulus_process : process
        variable expected : integer;
        variable temp : integer;
        
        procedure run_test(
            a_val : integer;
            b_val : integer; 
            operation : std_logic_vector(7 downto 0);
            result_ready_delay : integer;
            description : string
        ) is
        begin
            report "Test " & integer'image(test_number) & ": " & description;
  
            s_axis_a_tdata <= std_logic_vector(to_signed(a_val, 32));
            s_axis_b_tdata <= std_logic_vector(to_signed(b_val, 32));
            s_axis_operation_tdata <= operation;
            
            s_axis_a_tvalid <= '1';
            s_axis_b_tvalid <= '1';
            s_axis_operation_tvalid <= '1';

            wait until rising_edge(aclk) and s_axis_a_tready = '1' and s_axis_b_tready = '1' and s_axis_operation_tready = '1';

            s_axis_a_tvalid <= '0';
            s_axis_b_tvalid <= '0';
            s_axis_operation_tvalid <= '0';

            if result_ready_delay > 0 then
                m_axis_result_tready <= '0';
                for i in 1 to result_ready_delay loop
                    wait until rising_edge(aclk);
                end loop;
            end if;
            
            m_axis_result_tready <= '1';

            if operation = "00000000" then
                expected := a_val + b_val;
            else
                expected := a_val - b_val;
            end if;
            
            wait until rising_edge(aclk) and m_axis_result_tvalid = '1';
            
            temp := to_integer(signed(m_axis_result_tdata));
            if temp /= expected then
                report "ERROR: Expected " & integer'image(expected) & 
                       ", Got " & integer'image(temp)
                severity error;
                error_count <= error_count + 1;
            else
                report "PASS: Result = " & integer'image(expected);
            end if;
            
            m_axis_result_tready <= '0';
            test_number <= test_number + 1;
            wait for 2 * CLK_PERIOD;
        end procedure;

    begin
        wait for 100 ns;
        run_test(5, 3, "00000000", 0, "Basic Addition: 5 + 3");
        run_test(10, 4, "00000001", 0, "Basic Subtraction: 10 - 4");
        run_test(0, 0, "00000000", 0, "Zero Addition: 0 + 0");
        run_test(0, 0, "00000001", 0, "Zero Subtraction: 0 - 0");
        
        run_test(-5, 8, "00000000", 0, "Negative + Positive: -5 + 8");
        run_test(5, -3, "00000000", 0, "Positive + Negative: 5 + (-3)");
        run_test(-5, -3, "00000000", 0, "Negative + Negative: -5 + (-3)");
        run_test(5, -3, "00000001", 0, "Positive - Negative: 5 - (-3)");
        run_test(-5, 3, "00000001", 0, "Negative - Positive: -5 - 3");
        
        run_test(1000000, 0, "00000000", 0, "Large Positive + 0");
        run_test(-1000000, 0, "00000000", 0, "Large Negative + 0");
        run_test(1000000, 2000000, "00000000", 0, "Large Positive Addition");
        run_test(-1000000, -2000000, "00000000", 0, "Large Negative Addition");
       
        run_test(15, 7, "00000000", 2, "Backpressure: result_ready delayed by 2 cycles");
        run_test(20, 10, "00000001", 5, "Backpressure: result_ready delayed by 5 cycles");
        
        run_test(25, 5, "00000000", 0, "Operation 0x00 = Addition");
        run_test(25, 5, "00000001", 0, "Operation 0x01 = Subtraction");
        run_test(25, 5, "11111111", 0, "Operation 0xFF = Subtraction (any non-zero)");
        run_test(25, 5, "10101010", 0, "Operation 0xAA = Subtraction (any non-zero)");
        
        run_test(100, 50, "00000000", 0, "Seq Test 1: 100 + 50");
        run_test(200, 100, "00000001", 0, "Seq Test 2: 200 - 100");
        run_test(50, 25, "00000000", 0, "Seq Test 3: 50 + 25");
        run_test(75, 25, "00000001", 0, "Seq Test 4: 75 - 25");
        
        wait until rising_edge(aclk);
        s_axis_a_tdata <= std_logic_vector(to_signed(12, 32));
        s_axis_a_tvalid <= '1';
        s_axis_b_tvalid <= '0';
        s_axis_operation_tvalid <= '0';
        
        wait until rising_edge(aclk);
        s_axis_b_tdata <= std_logic_vector(to_signed(8, 32));
        s_axis_b_tvalid <= '1';
        
        wait until rising_edge(aclk);
        s_axis_operation_tdata <= "00000000";
        s_axis_operation_tvalid <= '1';
        
        wait until rising_edge(aclk) and s_axis_a_tready = '1' and s_axis_b_tready = '1' and s_axis_operation_tready = '1';
        s_axis_a_tvalid <= '0';
        s_axis_b_tvalid <= '0';
        s_axis_operation_tvalid <= '0';
        
        m_axis_result_tready <= '1';
        wait until rising_edge(aclk) and m_axis_result_tvalid = '1';
        
        temp := to_integer(signed(m_axis_result_tdata));
        if temp = 20 then
            report "PASS: Staggered valid signals test - 12 + 8 = 20";
        else
            report "ERROR: Staggered valid signals test failed";
            error_count <= error_count + 1;
        end if;
        m_axis_result_tready <= '0';
        test_number <= test_number + 1;
        wait for 2 * CLK_PERIOD;

        wait for 100 ns;
  
        report "Total Tests: " & integer'image(test_number - 1);
        report "Errors: " & integer'image(error_count);
        
        if error_count = 0 then
            report "ALL TESTS PASSED!";
        else
            report "SOME TESTS FAILED!";
        end if;
        
        wait;
    end process;

    monitor_process : process
    begin
        wait until rising_edge(aclk);
        
        if s_axis_a_tvalid = '1' and s_axis_a_tready = '1' then
            report "Input A accepted: " & integer'image(to_integer(signed(s_axis_a_tdata)));
        end if;
        
        if s_axis_b_tvalid = '1' and s_axis_b_tready = '1' then
            report "Input B accepted: " & integer'image(to_integer(signed(s_axis_b_tdata)));
        end if;
        
        if s_axis_operation_tvalid = '1' and s_axis_operation_tready = '1' then
            report "Operation accepted";
        end if;
        
        if m_axis_result_tvalid = '1' and m_axis_result_tready = '1' then
            report "Result produced: " & integer'image(to_integer(signed(m_axis_result_tdata)));
        end if;
    end process;

end Behavioral;