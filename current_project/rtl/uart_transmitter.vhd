library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity uart_transmitter is
  generic(CLKS_PER_BIT : positive := 13);
  port(clk:in std_logic; start:in std_logic; data:in std_logic_vector(7 downto 0);
       busy:out std_logic; txd:out std_logic);
end;
architecture rtl of uart_transmitter is
  signal shreg : std_logic_vector(9 downto 0) := (others=>'1');
  signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
  signal bit_count : integer range 0 to 9 := 0;
  signal active : std_logic := '0';
begin
  txd <= shreg(0);
  busy <= active;
  process(clk)
  begin
    if rising_edge(clk) then
      if active='0' then
        if start='1' then
          shreg <= '1' & data & '0';
          clk_count <= 0;
          bit_count <= 0;
          active <= '1';
        end if;
      elsif clk_count=CLKS_PER_BIT-1 then
        clk_count <= 0;
        shreg <= '1' & shreg(9 downto 1);
        if bit_count=9 then
          active <= '0';
        else
          bit_count <= bit_count+1;
        end if;
      else
        clk_count <= clk_count+1;
      end if;
    end if;
  end process;
end;
