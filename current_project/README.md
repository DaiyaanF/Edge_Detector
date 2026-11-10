# OV7670 + Cmod A7-35T edge detector (camera initialization/debug revision)

This project **retains your working `lab_f.vhd`-derived VGA logic** (file `rtl/lab_vga.vhd`, 25.2 MHz MMCM clock, 640x480@60Hz, 2-bit RGB JA Pmod output). It replaces the incomplete OV7670 SCCB initialization and keeps the debug modes to diagnose the black screen.

## Hardware connections

| OV7670 header | Cmod DIP physical pin | FPGA package pin |
|---|---:|---|
| D0, D1, D2, D3 | 1, 2, 3, 4 | M3, L3, A16, K3 |
| D4, D5, D6, D7 | 5, 6, 7, 8 | C15, H1, A15, B15 |
| HREF | 9 | A14 |
| VSYNC | 10 | J3 |
| PCLK | 18 | N3 |
| XCLK | 19 | P3 |
| SCL / SIOC | 20 | M2 |
| SDA / SIOD | 21 | N1 |
| GND | 25 | power ground |
| RESET | no assigned FPGA GPIO | externally hold at **inactive** level |
| PWDN | no assigned FPGA GPIO | externally hold low (if active high) |
| VCC | **regulated camera-breakout-compatible supply**, not GPIO | N/A |

**Electrical safety:** Do not power a camera from the 5V->3.3V resistor divider, a normal FPGA GPIO, or unregulated 5V. The bare OV7670 sensor has lower-voltage IO than the Cmod's 3.3V GPIO; make sure the *particular breakout* supports FPGA 3.3V inputs on XCLK/SCCB, or insert suitable level shifting. SCCB requires a pullup to an IO-safe voltage. For this reason the XDC's PULLUP instructions are commented out. Add appropriate physical pullups if the breakout lacks them, and do not enable FPGA 3.3V pullups unless verified sensor-safe. Tie camera and Cmod grounds together.

**VGA:** Use the Pmod as in the successful course VGA lab. Red/green/blue 2 bits each plus HSYNC and VSYNC use the JA connector. No separate VGA DIP GPIO wires are required with *that exact lab VGA board*. DIP pin 11 remains free.

## Source organization

- `rtl/lab_vga.vhd`: the working lab VGA MMCM/counters/blanking.
- `rtl/sccb_init.vhd`: 100 ms camera power settling, `0x12=0x80` software reset, 100 ms delay after reset, QVGA/YUV422/scale configuration, slow `0x11=0x0A` prescaler, and a sampled 9th SCCB bit for diagnosis (`ack_missing`).
- `rtl/camera_capture.vhd`: samples parallel data on PCLK, Y byte of YUV422, image x/y.
- `rtl/sobel_stream.vhd`: 3x3 horizontal/vertical edge estimate.
- `rtl/framebuffer.vhd`: 320x240 1-bit dual-clock frame RAM; asynchronous capture and VGA domains.
- `rtl/edge_detector_top.vhd`: all integration and LED debug signals.
- `constraints/edge_detector.xdc`: lab VGA + existing camera DIP mapping; no reset GPIO.
- `sim/tb_sobel_stream.vhd`: original Sobel unit test.

## Screen modes

- **BTN0 held**: checkerboard test pattern (ignores camera).
- **BTN0 released**: live **raw binary luminance** (`Y` bits 7 or 6) by default, to verify a camera picture before worrying about Sobel.
- Once raw picture works, edit `constant SHOW_SOBEL : boolean := false` to `true` in `rtl/edge_detector_top.vhd`, rebuild, and the screen displays Sobel output. This is a compile-time switch, not another button.

## LEDs

- **LD1 / A17** blinks as long as VSYNC *edges* are observed from the camera by the PCLK domain. Goes off if no new edges for ~0.5s.
- **LD2 / C16** stays on if valid Y pixel capture events continue; goes off ~0.5s after the last activity.
- **LD0** is a separate RGB LED and is not controlled by this design.
- `ack_missing` is a diagnostic internal net available to probe with a Vivado ILA. **Do not interpret it as definitive success/failure**: the ninth SCCB cycle is a don't-care in some OV7670 implementations, and some camera modules do not drive a conventional I2C ACK. The controller continues to write all registers regardless of that signal. `done` means all writes attempted, not verified.

## Build and tests

1. Extract ZIP; in Vivado Tcl console set working directory to its extracted folder and `source create_project.tcl`. Or replace the existing project's RTL and XDC one-to-one. **Remove old duplicate VGA/camera files and verify `edge_detector_top` is the synthesis top.**
2. Run synthesis, implementation, generate bitstream, program FPGA. Vivado isn't available here, so this revision has **not** been synthesized or hardware validated.
3. Hold BTN0: checkerboard must still work.
4. Release BTN0 and point camera into a bright, high-contrast scene. Look for a binary camera picture.
5. Read LD1/LD2: both off => likely absent PCLK/VSYNC/capture. LD1 blinking but LD2 dark => VSYNC present, valid pixels absent. Both active but black => inspect camera data pins, YUV byte order, SCCB settings, and framebuffer.
6. Probe XCLK (DIP 19), PCLK (18), VSYNC (10), HREF (9) with oscilloscope if no image. Measure the camera's **actual supply under load**, confirm RESET is inactive and PWDN low.
7. Once raw image works, set SHOW_SOBEL=true and rebuild.

## Known limitations

The 320x240 RAM uses single buffering with unrelated camera PCLK and VGA pixel clock and can show tearing. Camera register values may need to be adjusted for a particular breakout/module revision, especially YUV byte order/scaling. Even successful SCCB write cycles do not guarantee received image pixels; the sensor must actually drive PCLK, HREF, and data. `ack_missing` is checked but there is no definitive sensor-ID register-read verification. The project implements a 1-bit binary display, not 8-bit grayscale VGA. Its 3x3 Sobel module is provided for later enabling and remains hardware-unverified.

References: OV7670 register definitions https://www.olimex.com/Products/Components/Camera/CAMERA-OV7670/resources/OV7670.pdf ; SCCB implementation guide https://www.haoyuelectronics.com/Attachment/OV7670%20%2B%20AL422B%28FIFO%29%20Camera%20Module%28V2.0%29/OV7670%20Implementation%20Guide%20%28V1.0%29.pdf ; example reset/delay https://circuitdigest.com/microcontroller-projects/how-to-use-ov7670-camera-module-with-arduino
