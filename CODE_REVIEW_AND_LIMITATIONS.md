# Source-code review / known limitations

This is a **snapshot of the latest supplied code**, not an assertion that all functions are correct.

- `sccb_init.vhd`: initialization sends a sequence of SCCB writes but does not perform **register readback**, so `done` only means writes were attempted. The ninth SCCB bit is not a conclusive acknowledgment on every OV7670 module; `ack_missing` is not shown on an LED and is intended for an ILA. Exact QVGA scaling/register settings may require sensor-specific adjustment.
- `edge_detector_top.vhd`: `ready` is generated in the 12 MHz clock domain and used directly as `enable` inside camera PCLK domain. **Synchronize or handshake this control** to PCLK for robust operation.
- `camera_capture.vhd`: assumes a particular YUV422/Y ordering (Y on even-byte phase); wrong camera mode/order can corrupt brightness. Check frame/line counters and HREF/VSYNC edge assumptions against measured camera signals. The camera may require the correct PCLK edge based on timing.
- `framebuffer.vhd`: 320x240 1-bit RAM with unrelated write/read clocks. The single buffer can show tearing; no full-frame handoff or double buffering. Confirm inferred block RAM implementation in Vivado and timing across domains.
- `sobel_stream.vhd`: 3x3 pixel-line buffering with threshold set to 140, currently compile-time disabled. Needs simulation with known pixel sequences and testing once raw acquisition is established.
- `lab_vga.vhd`: lab-derived 640x480 counters and sync output with 25.2 MHz MMCM, 2-bit monochrome repeated across RGB. Checkerboard **was reported working**. `frame` unused warning is harmless.
- LEDs: activity detectors use counters, are observational only; LD1 blink and LD2 steady statuses do not verify actual pixel intensity nor frame correctness.
- XDC: `LVCMOS33` applies to camera-connected FPGA pads. This does not establish that the camera module itself is 3.3 V tolerant; assess electrical safety first. Check PCLK generated-clock/timing and reset/CDC constraints.
- Existing testbench tests Sobel in isolation, not camera configuration/capture/video integration. No full-system verification or synthesis log included.

## To continue development

Safest path: resolve supply and I/O voltage, verify sensor clocks and SCCB communication, display the raw image, then enable the Sobel compile-time setting. Do not confuse the presence of a valid VGA test pattern with working camera capture.
