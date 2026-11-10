library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity camera_uart_sender is
  generic(CLKS_PER_BIT : positive := 13; PIXELS : positive := 76800);
  port(clk:in std_logic; rd_addr:out unsigned(16 downto 0);
       rd_data:in std_logic_vector(7 downto 0); txd:out std_logic);
end;
architecture rtl of camera_uart_sender is
  type state_t is (SEND_HEADER, HEADER_GAP, HEADER_WAIT, READ_PIXEL,
                   LOAD_PIXEL, PIXEL_GAP, PIXEL_WAIT);
  signal st : state_t := SEND_HEADER;
  signal addr : unsigned(16 downto 0) := (others=>'0');
  signal tx_start : std_logic := '0';
  signal tx_data : std_logic_vector(7 downto 0) := (others=>'0');
  signal tx_busy : std_logic;
begin
  rd_addr <= addr;
  tx: entity work.uart_transmitter
    generic map(CLKS_PER_BIT=>CLKS_PER_BIT)
    port map(clk=>clk, start=>tx_start, data=>tx_data, busy=>tx_busy, txd=>txd);
  process(clk)
  begin
    if rising_edge(clk) then
      tx_start <= '0';
      case st is
        when SEND_HEADER =>
          if tx_busy='0' then
            tx_data <= x"FF";
            tx_start <= '1';
            addr <= (others=>'0');
            st <= HEADER_GAP;
          end if;
        when HEADER_GAP =>
          st <= HEADER_WAIT;
        when HEADER_WAIT =>
          if tx_busy='0' then st <= READ_PIXEL; end if;
        when READ_PIXEL =>
          st <= LOAD_PIXEL;
        when LOAD_PIXEL =>
          if rd_data=x"FF" then tx_data <= x"FE";
          else tx_data <= rd_data; end if;
          tx_start <= '1';
          st <= PIXEL_GAP;
        when PIXEL_GAP =>
          st <= PIXEL_WAIT;
        when PIXEL_WAIT =>
          if tx_busy='0' then
            if addr=to_unsigned(PIXELS-1,17) then
              st <= SEND_HEADER;
            else
              addr <= addr+1;
              st <= READ_PIXEL;
            end if;
          end if;
      end case;
    end if;
  end process;
end;
