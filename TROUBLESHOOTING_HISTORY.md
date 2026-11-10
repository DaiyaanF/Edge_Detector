# Troubleshooting chronology

1. Project goal: Real-time FPGA Sobel edge detection with an OV7670 parallel camera and VGA monitor on Cmod A7-35T.
2. Original hardware plan: OV7670 on physical DIP GPIOs; VGA Pmod on JA. A hardware camera RESET GPIO was briefly assigned to DIP 11 / J1, then explicitly removed. RESET now needs an external suitable inactive bias.
3. Initial Vivado synthesis: `[Synth 8-2757]` at `process(all)` on `edge_detector_top.vhd:77` because file was not compiled as VHDL-2008. Fixed by explicit sensitivity list / setting source standard to VHDL-2008 in newer project.
4. Additional synthesis: `[Synth 8-9112]` actual for formal input `rst` not a static name (`rst => not locked`). Older module fixed by introducing a named signal `vga_reset` before port map. This old module is superseded by the user's lab VGA logic.
5. Other Vivado messages: `[Synth 8-6014] frame_reg unused and removed`; `[Synth 8-7080] parallel synthesis criteria not met`; `[Synth 8-3332] unused framebuffer selection element removed`; `[Synth 8-3936] tx_q trimmed`. These are not automatically fatal and do not themselves confirm functional capture.
6. User supplied EN.520.424 VGA lab `lab_f.vhd` and `lab_f.xdc`. Newer project uses lab-based VGA timings, 25.2 MHz MMCM, 2-bit RGB. **Checkerboard confirmed working on actual board**.
7. With checkerboard released, VGA is **entirely black**. Camera/Sobel path not demonstrated.
8. User observed physical-board LD0 shows multiple colors, LD1 illuminates immediately, LD2 illuminates after roughly one second and stays on. These observations were made with an earlier build whose LEDs could simply mirror ready or VSYNC level; they do not prove pixel capture. Later builds implement LED activity counters; behavior of these newer builds has not been reported.
9. SCCB writer subsequently updated to include power-up delay, COM7 software reset (register 0x12 write 0x80), 100 ms reset pause, and QVGA/YUV422 setup; the nine-bit acknowledgment sample is **diagnostic, not reliable proof of configuration**. Newer build defaults to raw binary luminance and only uses Sobel when compile-time `SHOW_SOBEL` is true.
10. User identified powering camera from **a 5 V resistor divider**. This is a serious confirmed design problem. Fix supply before interpreting camera performance or programming results.

## Recommended diagnostic order

- Verify regulated camera voltage, common ground, RESET inactive, PWDN inactive, safe voltage levels on XCLK and SCCB.
- Probe DIP 19 XCLK, DIP 18 PCLK, DIP 10 VSYNC, DIP 9 HREF with oscilloscope or Vivado ILA; scope SCCB after configuration to establish activity.
- Use raw luminance mode with BTN0 released. If frame and pixel activity exists but display remains black, inspect byte ordering and framebuffer data.
- Add SCCB register readback / manufacturer product-ID verification before assuming init succeeded.
- Verify full raw image, then enable Sobel and inspect pixel pipeline and timing.
