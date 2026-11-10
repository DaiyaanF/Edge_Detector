-- Pure VHDL testbench: 320x3 pixels, horizontal black/white boundary.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_sobel_stream is end;
architecture tb of tb_sobel_stream is
 signal clk:std_logic:='0';
 signal vin:std_logic:='0';
 signal ix:unsigned(8 downto 0):=(others=>'0');
 signal iy:unsigned(7 downto 0):=(others=>'0');
 signal gray:std_logic_vector(7 downto 0):=(others=>'0');
 signal wen:std_logic; signal addr:unsigned(16 downto 0); signal edge:std_logic;
 signal checked:boolean:=false;
begin
 clk<=not clk after 10 ns;
 dut:entity work.sobel_stream port map(clk=>clk,valid_in=>vin,x_in=>ix,
     y_in=>iy,gray=>gray,wr_en=>wen,wr_addr=>addr,edge_out=>edge);
 driver:process
 begin
  for r in 0 to 2 loop
   for c in 0 to 319 loop
     wait until falling_edge(clk);
     iy<=to_unsigned(r,8); ix<=to_unsigned(c,9);
     if r=2 then gray<=x"FF"; else gray<=x"00"; end if;
     vin<='1';
   end loop;
  end loop;
  wait until falling_edge(clk); vin<='0';
  wait for 200 ns;
  assert checked report "Expected Sobel edge at center pixel (1,1) not found" severity failure;
  report "Sobel stream basic horizontal-edge test passed" severity note;
  wait;
 end process;
 checker:process(clk)
 begin
 if rising_edge(clk) then
   if wen='1' and to_integer(addr)=321 then
     assert edge='1' report "Expected Sobel high edge at (1,1)" severity failure;
     checked<=true;
   end if;
 end if;
 end process;
end;
