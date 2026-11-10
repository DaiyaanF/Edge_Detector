library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- OV7670 SCCB writer. 12 MHz clock, approximately 100 kHz SIOC.
-- Both lines are open-drain. External pull-ups to a sensor-safe voltage
-- are required. SCCB's ninth bit is a don't-care on some camera boards;
-- ack_missing is a diagnostic indication, NOT a guaranteed failure.
entity sccb_init is
  port (
    clk         : in std_logic;
    reset_n     : in std_logic;
    sio_c       : inout std_logic;
    sio_d       : inout std_logic;
    done        : out std_logic;
    ack_missing : out std_logic
  );
end entity;

architecture rtl of sccb_init is
  type pair_t is array (0 to 1) of std_logic_vector(7 downto 0);
  type rom_t is array (natural range <>) of pair_t;
  -- COM7 software reset must be followed by a 100 ms pause.
  -- Baseline QVGA + YUV422 setup based on OV7670 register definitions.
  constant rom : rom_t := (
    (x"12", x"80"), -- 0: reset all registers
    (x"11", x"0A"), -- 1: CLKRC (slow clock for bring-up)
    (x"12", x"10"), -- 2: COM7 QVGA, YUV
    (x"0C", x"04"), -- 3: COM3 enable scaling
    (x"3E", x"19"), -- 4: COM14 PCLK scaling
    (x"70", x"3A"), -- 5: SCALING_XSC
    (x"71", x"35"), -- 6: SCALING_YSC
    (x"72", x"11"), -- 7: SCALING_DCWCTR downsample x2
    (x"73", x"F1"), -- 8: SCALING_PCLK_DIV
    (x"A2", x"02"), -- 9: SCALING_PCLK_DELAY
    (x"3A", x"04"), -- 10: TSLB YUYV: Y is first byte
    (x"3D", x"88"), -- 11: COM13 color and ordering control
    (x"40", x"C0"), -- 12: COM15 full-range output
    (x"15", x"00"), -- 13: COM10 PCLK free-running
    (x"13", x"E7"), -- 14: COM8 enable AEC/AGC/AWB
    (x"3B", x"0A"), -- 15: COM11 exposure control
    (x"17", x"16"), -- 16: HSTART
    (x"18", x"04"), -- 17: HSTOP
    (x"32", x"80"), -- 18: HREF
    (x"19", x"02"), -- 19: VSTART
    (x"1A", x"7A"), -- 20: VSTOP
    (x"03", x"0A")  -- 21: VREF
  );
  type state_t is (
    WAIT_POWER, START_IDLE, START_SDA_LOW, START_SCL_LOW,
    BIT_SETUP, BIT_HIGH, BIT_FALL, ACK_LOW, ACK_HIGH, ACK_SAMPLE,
    STOP_LOW, STOP_SCL_HIGH, STOP_RELEASE,
    BETWEEN_REGS, WAIT_SOFT_RESET, FINISHED
  );
  signal st : state_t := WAIT_POWER;
  signal divider : integer range 0 to 59 := 0;
  signal delay_count : integer range 0 to 1199999 := 0;
  signal reg_idx : integer range 0 to rom'length-1 := 0;
  signal byte_idx : integer range 0 to 2 := 0;
  signal bit_idx : integer range 0 to 7 := 7;
  signal shift_data : std_logic_vector(7 downto 0) := (others => '0');
  signal scl_low, sda_low : std_logic := '0';
  signal ack_error_q : std_logic := '0';
begin
  sio_c <= '0' when scl_low='1' else 'Z';
  sio_d <= '0' when sda_low='1' else 'Z';
  done <= '1' when st=FINISHED else '0';
  ack_missing <= ack_error_q;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n='0' then
        st <= WAIT_POWER;
        divider <= 0;
        delay_count <= 0;
        reg_idx <= 0;
        byte_idx <= 0;
        bit_idx <= 7;
        scl_low <= '0';
        sda_low <= '0';
        ack_error_q <= '0';
      elsif st=WAIT_POWER or st=WAIT_SOFT_RESET then
        scl_low <= '0';
        sda_low <= '0';
        if delay_count=1199999 then -- 100 ms at 12 MHz
          delay_count <= 0;
          st <= START_IDLE;
        else
          delay_count <= delay_count+1;
        end if;
      elsif divider=59 then
        divider <= 0;
        case st is
          when START_IDLE =>
            scl_low <= '0'; sda_low <= '0';
            shift_data <= x"42"; byte_idx <= 0; bit_idx <= 7;
            st <= START_SDA_LOW;
          when START_SDA_LOW =>
            scl_low <= '0'; sda_low <= '1'; st <= START_SCL_LOW;
          when START_SCL_LOW =>
            scl_low <= '1'; st <= BIT_SETUP;
          when BIT_SETUP =>
            scl_low <= '1';
            if shift_data(bit_idx)='0' then sda_low <= '1';
            else sda_low <= '0'; end if;
            st <= BIT_HIGH;
          when BIT_HIGH =>
            scl_low <= '0'; st <= BIT_FALL;
          when BIT_FALL =>
            scl_low <= '1';
            if bit_idx=0 then st <= ACK_LOW;
            else bit_idx <= bit_idx-1; st <= BIT_SETUP; end if;
          when ACK_LOW =>
            scl_low <= '1'; sda_low <= '0'; st <= ACK_HIGH;
          when ACK_HIGH =>
            scl_low <= '0'; st <= ACK_SAMPLE;
          when ACK_SAMPLE =>
            -- Sample in the SCL-high portion of the 9th SCCB cycle.
            -- Some modules do not acknowledge SCCB writes.
            if sio_d/='0' and sio_d/='L' then ack_error_q<='1'; end if;
            scl_low <= '1';
            if byte_idx=0 then
              byte_idx <= 1; shift_data <= rom(reg_idx)(0);
              bit_idx <= 7; st <= BIT_SETUP;
            elsif byte_idx=1 then
              byte_idx <= 2; shift_data <= rom(reg_idx)(1);
              bit_idx <= 7; st <= BIT_SETUP;
            else
              st <= STOP_LOW;
            end if;
          when STOP_LOW =>
            scl_low <= '1'; sda_low <= '1'; st <= STOP_SCL_HIGH;
          when STOP_SCL_HIGH =>
            scl_low <= '0'; sda_low <= '1'; st <= STOP_RELEASE;
          when STOP_RELEASE =>
            scl_low <= '0'; sda_low <= '0'; st <= BETWEEN_REGS;
          when BETWEEN_REGS =>
            if reg_idx=rom'length-1 then st <= FINISHED;
            else
              reg_idx <= reg_idx+1;
              if reg_idx=0 then
                -- Wait 100 ms after writing COM7 software-reset.
                st <= WAIT_SOFT_RESET;
                delay_count <= 0;
              else
                st <= START_IDLE;
              end if;
            end if;
          when FINISHED =>
            scl_low <= '0'; sda_low <= '0';
          when others => st <= WAIT_POWER;
        end case;
      else
        divider <= divider+1;
      end if;
    end if;
  end process;
end architecture;
