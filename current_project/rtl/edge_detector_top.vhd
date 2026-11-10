library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;
entity edge_detector_top is
 port(
   clk12:in std_logic;
   btn_test:in std_logic;  -- hold for VGA color/edge test pattern
   cam_data:in std_logic_vector(7 downto 0);
   cam_href:in std_logic; cam_vsync:in std_logic; cam_pclk:in std_logic;
   cam_xclk:out std_logic; cam_sioc:inout std_logic; cam_siod:inout std_logic;
   vga_r:out std_logic_vector(1 downto 0);
   vga_g:out std_logic_vector(1 downto 0);
   vga_b:out std_logic_vector(1 downto 0);
   vga_hsync:out std_logic; vga_vsync:out std_logic;
   led_ready:out std_logic; led_frame:out std_logic;
   uart_txd:out std_logic);
end;
architecture rtl of edge_detector_top is
 signal clk25, ready:std_logic;
 signal ack_missing : std_logic;
 signal config_start_n : std_logic := '0';
 signal reset_count : natural range 0 to 120000 := 0;
 signal cam_valid,edge_valid,edge_bit:std_logic;
 signal cx:unsigned(8 downto 0);
 signal cy:unsigned(7 downto 0);
 signal gray:std_logic_vector(7 downto 0);
 signal waddr,raddr:unsigned(16 downto 0);
 signal rbit:std_logic;
 signal vx,vy:unsigned(9 downto 0);
 signal test_q:std_logic:='0';
 signal pixel_out:std_logic:='0';
 signal checker_q:std_logic:='0';

 signal test_sync1,test_sync2:std_logic:='0';
 -- Set to true only after a recognizable raw camera image is confirmed.
 constant SHOW_SOBEL : boolean := false; -- change to true after raw picture works
 signal fb_write_enable, fb_write_bit : std_logic;
 signal fb_write_addr : unsigned(16 downto 0);
 -- Camera-clock-domain activity toggles; synchronized into clk12.
 signal cam_vsync_old : std_logic := '0';
 signal frame_toggle : std_logic := '0';
 signal pixel_toggle : std_logic := '0';
 signal pixel_divider : unsigned(9 downto 0) := (others=>'0');
 signal frame_sync_a,frame_sync_b,frame_sync_old : std_logic := '0';
 signal pixel_sync_a,pixel_sync_b,pixel_sync_old : std_logic := '0';
 signal frame_age : natural range 0 to 24000000 := 24000000;
 signal pixel_age : natural range 0 to 24000000 := 24000000;
 signal blink_counter : unsigned(21 downto 0) := (others=>'0');
 signal ready_pclk_a, ready_pclk_b : std_logic := '0';
 signal cam_addr : unsigned(16 downto 0);
 signal uart_addr : unsigned(16 downto 0);
 signal uart_pixel : std_logic_vector(7 downto 0);
begin
 -- Internal 10 ms power-up delay before starting SCCB configuration.
 -- No FPGA GPIO is connected to the camera hardware RESET pin.
 process(clk12)
 begin
   if rising_edge(clk12) then
     if reset_count < 120000 then
       reset_count <= reset_count + 1;
       config_start_n <= '0';
     else
       config_start_n <= '1';
     end if;
   end if;
 end process;

 xclk_forward: ODDR generic map(DDR_CLK_EDGE=>"SAME_EDGE", INIT=>'0', SRTYPE=>"SYNC")
   port map(Q=>cam_xclk,C=>clk12,CE=>'1',D1=>'1',D2=>'0',R=>'0',S=>'0');
 cfg: entity work.sccb_init port map(clk=>clk12,reset_n=>config_start_n,sio_c=>cam_sioc,sio_d=>cam_siod,done=>ready,ack_missing=>ack_missing);
 capture: entity work.camera_capture port map(
   pclk=>cam_pclk,enable=>ready_pclk_b,href=>cam_href,vsync=>cam_vsync,
   data=>cam_data,pix_valid=>cam_valid,pix_y=>gray,pix_x=>cx,pix_row=>cy);
 sobel: entity work.sobel_stream port map(
   clk=>cam_pclk,valid_in=>cam_valid,x_in=>cx,y_in=>cy,gray=>gray,
   wr_en=>edge_valid,wr_addr=>waddr,edge_out=>edge_bit);
 -- The timing/clock/blanking logic is taken from the original VGA lab.
 -- VGA lab RGB channels use 2 bits, and all VGA signals fit on JA.
 lab_display: entity work.lab_vga port map(
   clk=>clk12, pixel=>pixel_out, clk_pixel=>clk25,
   x=>vx, y=>vy, red=>vga_r, green=>vga_g, blue=>vga_b,
   hsync=>vga_hsync, vsync=>vga_vsync);
 raddr<=to_unsigned((to_integer(vy)/2)*320+(to_integer(vx)/2),17)
   when vx<640 and vy<480 else (others=>'0');
 -- Raw binary luminance mode (Y >= approx. 64) is the default diagnostic display.
 -- Sobel is selectable at compile time with SHOW_SOBEL above.
 cam_addr <= to_unsigned(to_integer(cy)*320+to_integer(cx),17);
 fb_write_enable <= edge_valid when SHOW_SOBEL else cam_valid;
 fb_write_addr <= waddr when SHOW_SOBEL else cam_addr;
 fb_write_bit <= edge_bit when SHOW_SOBEL else (gray(7) or gray(6));
 fb: entity work.framebuffer port map(
   wclk=>cam_pclk,wen=>fb_write_enable,waddr=>fb_write_addr,wbit=>fb_write_bit,
   rclk=>clk25,raddr=>raddr,rbit=>rbit);
 gray_fb: entity work.gray_framebuffer port map(
   wclk=>cam_pclk,wen=>cam_valid,waddr=>cam_addr,wdata=>gray,
   rclk=>clk12,raddr=>uart_addr,rdata=>uart_pixel);
 uart_out: entity work.camera_uart_sender
   generic map(CLKS_PER_BIT=>13, PIXELS=>76800)
   port map(clk=>clk12,rd_addr=>uart_addr,rd_data=>uart_pixel,txd=>uart_txd);
 -- Framebuffer data are read on the VGA clock. The lab's registered
 -- blank/sync signals correspond to the same pixel sampled for rbit.
 process(clk25)
 begin
   if rising_edge(clk25) then
     test_sync1<=btn_test;
     test_sync2<=test_sync1;
     test_q<=test_sync2;
     if ((to_integer(vx)/32 + to_integer(vy)/32) mod 2)=0 then
       checker_q<='1';
     else
       checker_q<='0';
     end if;
   end if;
 end process;
 pixel_out <= checker_q when test_q='1' else rbit;
 -- LED1 (A17): blinks if frame transitions continue arriving.
 -- LED2 (C16): remains ON while valid camera pixels arrive.
 -- Both use a 0.5 s activity timeout (12 MHz clock).
 -- LED0 is the separate RGB LED and is not controlled here.
 process(cam_pclk)
 begin
   if rising_edge(cam_pclk) then
     ready_pclk_a <= ready;
     ready_pclk_b <= ready_pclk_a;
     cam_vsync_old <= cam_vsync;
     if cam_vsync='1' and cam_vsync_old='0' then
       frame_toggle <= not frame_toggle;
     end if;
     if cam_valid='1' then
       if pixel_divider=to_unsigned(1023,10) then
         pixel_divider <= (others=>'0');
         pixel_toggle <= not pixel_toggle;
       else
         pixel_divider <= pixel_divider+1;
       end if;
     end if;
   end if;
 end process;
 process(clk12)
 begin
   if rising_edge(clk12) then
     frame_sync_a <= frame_toggle;
     frame_sync_b <= frame_sync_a;
     frame_sync_old <= frame_sync_b;
     pixel_sync_a <= pixel_toggle;
     pixel_sync_b <= pixel_sync_a;
     pixel_sync_old <= pixel_sync_b;
     if frame_sync_b /= frame_sync_old then
       frame_age <= 0;
     elsif frame_age < 24000000 then
       frame_age <= frame_age + 1;
     end if;
     if pixel_sync_b /= pixel_sync_old then
       pixel_age <= 0;
     elsif pixel_age < 24000000 then
       pixel_age <= pixel_age + 1;
     end if;
     blink_counter <= blink_counter + 1;
   end if;
 end process;
 led_ready <= blink_counter(21) when frame_age < 24000000 else '0';
 led_frame <= '1' when pixel_age < 24000000 else '0';
end;
