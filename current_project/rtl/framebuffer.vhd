library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity framebuffer is
 port(wclk:in std_logic; wen:in std_logic; waddr:in unsigned(16 downto 0);
      wbit:in std_logic; rclk:in std_logic; raddr:in unsigned(16 downto 0);
      rbit:out std_logic);
end;
architecture rtl of framebuffer is
 type memory_t is array(0 to 76799) of std_logic;
 signal mem : memory_t := (others=>'0');
 attribute ram_style : string;
 attribute ram_style of mem : signal is "block";
begin
 process(wclk)
 begin
   if rising_edge(wclk) then
     if wen='1' and to_integer(waddr)<76800 then
       mem(to_integer(waddr))<=wbit;
     end if;
   end if;
 end process;
 process(rclk)
 begin
   if rising_edge(rclk) then
     if to_integer(raddr)<76800 then rbit<=mem(to_integer(raddr));
     else rbit<='0'; end if;
   end if;
 end process;
end;
