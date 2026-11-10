library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity camera_capture is
  port(pclk:in std_logic; enable:in std_logic; href:in std_logic;
    vsync:in std_logic; data:in std_logic_vector(7 downto 0);
    pix_valid:out std_logic; pix_y:out std_logic_vector(7 downto 0);
    pix_x:out unsigned(8 downto 0); pix_row:out unsigned(7 downto 0));
end;
architecture rtl of camera_capture is
  signal href_old, vs_old : std_logic := '0';
  signal phase : std_logic := '0';
  signal first_line : std_logic := '1';
  signal xx : integer range 0 to 320 := 0;
  signal yy : integer range 0 to 255 := 0;
begin
 process(pclk)
   variable x_v : integer range 0 to 320;
   variable y_v : integer range 0 to 255;
   variable ph_v : std_logic;
 begin
 if rising_edge(pclk) then
   href_old<=href; vs_old<=vsync;
   pix_valid<='0';
   if enable='0' or (vsync='1' and vs_old='0') then
     xx<=0; yy<=0; phase<='0'; first_line<='1';
   elsif href='1' then
     if href_old='0' then
       x_v:=0; ph_v:='0';
       if first_line='1' then
         y_v:=0; first_line<='0';
       elsif yy<255 then
         y_v:=yy+1;
       else
         y_v:=yy;
       end if;
     else
       x_v:=xx; ph_v:=phase; y_v:=yy;
     end if;
     -- TSLB=0x04, COM13=0x88 select Y,U,Y,V: Y on even bytes.
     if ph_v='0' and x_v<320 and y_v<240 then
       pix_y<=data; pix_x<=to_unsigned(x_v,9);
       pix_row<=to_unsigned(y_v,8); pix_valid<='1';
       x_v:=x_v+1;
     end if;
     xx<=x_v; yy<=y_v; phase<=not ph_v;
   end if;
 end if;
 end process;
end;
