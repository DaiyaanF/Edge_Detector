# OV7670 FPGA Edge Detector — Consolidated Handoff

**Hardware:** Digilent Cmod A7-35T, OV7670 (Amazon ASIN B0F5QCBT75 reported for the camera), Digilent VGA Pmod used with the Johns Hopkins EN.520.424 VGA lab wiring, VGA monitor.

**Current status as reported by user (Nov 9, 2026):** FPGA programs; the VGA checkerboard test works. With BTN0 released the intended camera image remains completely black. LD0 RGB shows multiple colors; LD1 turns on early; LD2 turns on after about one second and stays lit **in the earlier build**. This LED behavior was observed **before** the last camera debug changes, so it is not evidence that the newer activity indicators work. Camera was powered through a **5 V resistor divider**, which is not suitable as a supply and must be replaced by a camera-compatible regulated supply before further testing.

## Folder contents

- `current_project/`: latest delivered version (OV7670 camera debug, extended SCCB initialization, original VGA lab-derived logic). It is the **active starting point**, not confirmed functional hardware code.
- `original_vga_lab/`: exact source and constraint files `lab_f.vhd` and `lab_f.xdc` obtained from user's prior VGA lab.
- `historical_versions/`: previous delivered ZIPs for rollback and provenance; avoid mixing their RTL into current_project.
- `WIRING_AND_POWER.md`: mapping and electrical safety.
- `TROUBLESHOOTING_HISTORY.md`: symptoms, fixes, reported warnings, planned next tests.
- `CODE_REVIEW_AND_LIMITATIONS.md`: issues remaining, including timing and SCCB verification.
- `REFERENCES.md`: source/tutorial/manual URLs.

## Quick build

1. **Fix camera power first.** Do not power the camera with a 5 V resistor divider or an FPGA GPIO; determine the breakout's allowed supply voltage and signal-high voltage. Measure VCC at the camera under load.
2. Extract `current_project` and run `source create_project.tcl` from that folder in Vivado Tcl Console (or run Vivado with the script). This creates a new project for `xc7a35tcpg236-1` and marks sources as VHDL-2008. Do not leave older duplicate top-level/VGA sources in the project.
3. Check `.xdc` pin assignments against your specific board connections. Use BTN0 for the checkerboard. With BTN0 released, the current project is compiled to show **binary luminance**, *not* the Sobel result.
4. Watch LD1 (frame-activity blink) and LD2 (pixel-activity present). Both are driven by sampled activity logic but are not a substitute for measuring PCLK/VSYNC/HREF with a scope or ILA.
5. Only after a recognizable camera image is visible, edit `constant SHOW_SOBEL : boolean := false` to `true` in `rtl/edge_detector_top.vhd` and rebuild.

**Verification status:** Consolidated archive contents and integrity checked only. No Vivado synthesis, simulation, timing closure, or physical testing performed during this consolidation. The previous project itself has not been validated on the OV7670.
