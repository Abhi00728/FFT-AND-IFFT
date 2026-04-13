# FFT-AND-IFFT

A compact Digital Signal Processing (DSP) project implementing **Fast Fourier Transform (FFT)** and **Inverse Fast Fourier Transform (IFFT)** in:

- **C (recursive Cooley–Tukey decomposition)**
- **MIPS Assembly (fixed-size butterfly pipelines for N = 2 and N = 4)**

This repository is useful for understanding both algorithmic and low-level architectural perspectives of spectral-domain transforms.

---

## Project Layout

- `FFT.c` — Recursive FFT in C using `complex double`
- `IFFT.c` — Recursive IFFT in C with normalization
- `FFT.asm` — MIPS FFT implementation (supports `N = 2` or `N = 4`)
- `IFFT.asm` — MIPS IFFT implementation (supports `N = 2` or `N = 4`)
- `FFT_REPORT.pdf` — FFT write-up/report
- `IFFT_REPORT.pdf` — IFFT write-up/report

---

## Software Requirements

### 1) For C Implementations (`FFT.c`, `IFFT.c`)

Use:
- **GCC** (or any C99-compliant compiler)
- **Math library (`libm`)**
- Standard headers: `stdio.h`, `stdlib.h`, `math.h`, `complex.h`

Recommended environments:
- Linux/macOS terminal
- Windows with **WSL** or MinGW

Check compiler:

```bash
gcc --version
```

### 2) For MIPS Assembly (`FFT.asm`, `IFFT.asm`)

Use one of the following simulators:
- **MARS (MIPS Assembler and Runtime Simulator)**
- **QtSPIM / SPIM**

These `.asm` files rely on MIPS syscalls for console I/O, so they should be executed inside a MIPS simulator (not directly by GCC).

---

## Build and Run (C)

From repository root:

```bash
gcc FFT.c -lm -o fft
gcc IFFT.c -lm -o ifft
```

Run:

```bash
./fft
./ifft
```

---

## Input Format (C Programs)

Both C executables expect stdin in this sequence:

1. First line: `N` (number of complex samples)
2. Next `N` lines: `real imag`

Example:

```text
4
1 0
2 0
3 0
4 0
```

Meaning:

- `x[0] = 1 + 0i`
- `x[1] = 2 + 0i`
- `x[2] = 3 + 0i`
- `x[3] = 4 + 0i`

---

## Example Run (C FFT)

```bash
./fft
```

Input:

```text
4
1 0
2 0
3 0
4 0
```

Typical output spectrum:

```text
X[0] = 10.00 + 0.00i
X[1] = -2.00 + 2.00i
X[2] = -2.00 + 0.00i
X[3] = -2.00 + -2.00i
```

---

## Running Assembly Versions

### Using MARS

1. Open MARS
2. Load `FFT.asm` or `IFFT.asm`
3. Assemble
4. Run
5. Enter values when prompted

### Using QtSPIM/SPIM

1. Open QtSPIM/SPIM
2. Load assembly file
3. Run program
4. Provide console input as requested

### Assembly Input Constraints

- Assembly implementations are designed for **`N = 2` or `N = 4`**.
- Input is entered interactively for each element’s real and imaginary component.

---

## Technical Notes

- C implementation uses divide-and-conquer recursion with even/odd index decimation.
- Twiddle factors are generated via complex exponentials (`cexp`).
- IFFT applies scaling/normalization to recover time-domain samples.
- MIPS version demonstrates butterfly arithmetic, register-level data movement, and syscall-based I/O handling.

---

## Validation Workflow (Recommended)

1. Run `FFT.c` on an input vector.
2. Feed resulting frequency-domain samples into `IFFT.c`.
3. Verify reconstructed sequence matches original samples (within floating-point tolerance).

This round-trip check confirms transform pair consistency.

---

## Known Limitations

- `FFT.c`/`IFFT.c` are recursive and assume practical FFT sizing behavior (best with power-of-two `N`).
- Assembly versions are currently constrained to `N = 2` and `N = 4`.
- Floating-point formatting and rounding can introduce tiny numerical differences.

---

## Author

Developed as an educational FFT/IFFT implementation project spanning high-level and low-level execution models.
