# Physical wiring and power

Camera **OV7670 → Cmod A7-35T** physical DIP pins (latest XDC):

| Signal | DIP | FPGA package pin |
|---|---:|---|
| D0 | 1 | M3 |
| D1 | 2 | L3 |
| D2 | 3 | A16 |
| D3 | 4 | K3 |
| D4 | 5 | C15 |
| D5 | 6 | H1 |
| D6 | 7 | A15 |
| D7 | 8 | B15 |
| HREF | 9 | A14 |
| VSYNC | 10 | J3 |
| PCLK | 18 | N3 |
| XCLK | 19 | P3 |
| SCL (SIOC, sometimes mistaken as SDL) | 20 | M2 |
| SDA (SIOD) | 21 | N1 |
| GND | 25 | ground |

**DIP pin 11 is deliberately unassigned**: hardware RESET GPIO was requested, then removed. Camera RESET must be tied externally to the appropriate *inactive* level for the actual module/revision, rather than left floating. PWDN should be held inactive (commonly LOW). Some sensor revisions may vary in RESET polarity—confirm module documentation. **No ordinary GPIO is assigned to camera VCC.**

VGA Pmod: Use original VGA lab JA connector wiring, **2 bits each of RGB**; `lab_f.xdc` is included for the exact map. The previous 4-bit-color/two-connector concept was superseded by the working lab configuration. `edge_detector.xdc` inherits these pin assignments.

## Supply safety

The user indicated use of a **5 V resistor divider** for camera power. A divider's 3.3 V nominal output holds only unloaded; it collapses under camera current. Disconnect that divider and use a correctly rated regulated supply with common ground, and verify camera VCC *under load*. DIP pin 24 is VU (~5 V), **not** 3.3 V and must not feed the camera directly unless a module's manufacturer specifically certifies a 5 V input. Plain FPGA GPIO HIGH is not a power supply. Bare OV7670 logic/IO may have lower voltage tolerance than FPGA 3.3 V I/O: verify XCLK, SCL/SDA pullups, and RESET compatibility, and add level shifting where needed. Do not assume all OV7670 camera breakout boards are equivalent.

## VGA pins from original lab

| Output | FPGA package pin |
|---|---|
| vga_r[0], vga_r[1] | G17, H17 |
| vga_g[0], vga_g[1] | G19, H19 |
| vga_b[0], vga_b[1] | N18, J19 |
| vga_hsync, vga_vsync | K18, L18 |

BTN0: A18; LD1: A17; LD2: C16. Separate LD0 is a multicolor RGB LED and is not driven by current RTL.
