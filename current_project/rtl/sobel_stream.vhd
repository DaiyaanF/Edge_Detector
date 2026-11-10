library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity sobel_stream is
 port(clk:in std_logic; valid_in:in std_logic;
      x_in:in unsigned(8 downto 0); y_in:in unsigned(7 downto 0);
      gray:in std_logic_vector(7 downto 0);
      wr_en:out std_logic; wr_addr:out unsigned(16 downto 0);
      edge_out:out std_logic);
end;
architecture rtl of sobel_stream is
  type row_t is array(0 to 319) of std_logic_vector(7 downto 0);
  signal row_even,row_odd : row_t := (others=>(others=>'0'));
  signal a0,a1,b0,b1,c0,c1:integer range 0 to 255:=0;
  signal threshold:integer:=140;
begin
 process(clk)
 variable x,y : integer;
 variable vtop,vmid,vbottom : integer;
 variable gx,gy,g : integer;
 begin
 if rising_edge(clk) then
   wr_en<='0';
   if valid_in='1' then
     x:=to_integer(x_in); y:=to_integer(y_in);
     if x<320 and y<240 then
       -- Before overwriting the current parity bank it contains row y-2.
       if (y mod 2)=0 then
         vtop:=to_integer(unsigned(row_even(x)));
         vmid:=to_integer(unsigned(row_odd(x)));
         row_even(x)<=gray;
       else
         vtop:=to_integer(unsigned(row_odd(x)));
         vmid:=to_integer(unsigned(row_even(x)));
         row_odd(x)<=gray;
       end if;
       vbottom:=to_integer(unsigned(gray));
       if x>=2 and y>=2 then
         -- 3x3 neighborhood centered at (x-1,y-1).
         gx := (vtop-a0) + 2*(vmid-b0) + (vbottom-c0);
         gy := (c0+2*c1+vbottom) - (a0+2*a1+vtop);
         g:=abs(gx)+abs(gy);
         if g>threshold then edge_out<='1'; else edge_out<='0'; end if;
         wr_addr<=to_unsigned((y-1)*320+(x-1),17);
         wr_en<='1';
       end if;
       if x=0 then
         a0<=0; a1<=vtop; b0<=0; b1<=vmid; c0<=0; c1<=vbottom;
       else
         a0<=a1; a1<=vtop;
         b0<=b1; b1<=vmid;
         c0<=c1; c1<=vbottom;
       end if;
     end if;
   end if;
 end if;
 end process;
end;
