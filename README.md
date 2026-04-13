# FFT and IFFT — Fast Fourier Transform & Inverse Fast Fourier Transform

> Implementations of the **Cooley-Tukey FFT** algorithm and its inverse (**IFFT**) in both **C** and **MIPS Assembly**, covering the full pipeline from time-domain complex signals to frequency-domain spectra and back.

---

## Table of Contents
- [Overview](#overview)
- [What is the FFT?](#what-is-the-fft)
- [What is the IFFT?](#what-is-the-ifft)
- [Algorithm: Cooley-Tukey (Decimation-In-Time)](#algorithm-cooley-tukey-decimation-in-time)
- [Project Structure](#project-structure)
- [Implementations](#implementations)
  - [C Implementation](#c-implementation)
  - [MIPS Assembly Implementation](#mips-assembly-implementation)
- [Key Concepts & Terminology](#key-concepts--terminology)
- [How to Compile and Run (C)](#how-to-compile-and-run-c)
- [Input / Output Format](#input--output-format)
- [Example](#example)
- [Reports](#reports)

---

## Overview

This project demonstrates the **Fast Fourier Transform (FFT)** and its inverse (**IFFT**) implemented at two abstraction levels:

| Level | Language | Files |
|---|---|---|
| High-level | C (C99) | `FFT.c`, `IFFT.c` |
| Low-level | MIPS32 Assembly | `FFT.asm`, `IFFT.asm` |

Both levels implement the **recursive Cooley-Tukey Radix-2 DIT** (Decimation-In-Time) algorithm on arrays of **complex numbers**.

---

## What is the FFT?

The **Discrete Fourier Transform (DFT)** converts a sequence of N complex samples from the **time domain** into the **frequency domain**:

$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-j 2\pi k n / N}, \quad k = 0, 1, \ldots, N-1$$

A naïve DFT has **O(N²)** time complexity. The **FFT** is an efficient algorithm that computes the same result in **O(N log N)** by exploiting the **periodicity** and **symmetry** of the complex exponential **twiddle factors** `W_N^k = e^{-j2πk/N}`.

---

## What is the IFFT?

The **Inverse DFT (IDFT)** reconstructs the original time-domain signal from its frequency-domain representation:

$$x[n] = \frac{1}{N} \sum_{k=0}^{N-1} X[k] \cdot e^{+j 2\pi k n / N}, \quad n = 0, 1, \ldots, N-1$$

The key differences from the forward FFT are:
1. The **twiddle factors are conjugated** (exponent sign is **positive**).
2. The result is **scaled by 1/N** at each recursive stage (or once at the end).

The **IFFT** achieves the same **O(N log N)** complexity as the FFT.

---

## Algorithm: Cooley-Tukey (Decimation-In-Time)

The **Radix-2 DIT Cooley-Tukey** algorithm works by recursively splitting an N-point DFT into two N/2-point DFTs — one on the **even-indexed** samples and one on the **odd-indexed** samples — then combining the results using **butterfly operations**.

### Recursive Steps

1. **Base case**: If N = 1, the DFT of a single element is the element itself.
2. **Split**: Separate `x[n]` into:
   - Even sub-sequence: `x[0], x[2], x[4], ...`
   - Odd sub-sequence: `x[1], x[3], x[5], ...`
3. **Recurse**: Compute FFT on each half.
4. **Combine (Butterfly)**:
   ```
   X[k]       = E[k] + W_N^k · O[k]
   X[k + N/2] = E[k] - W_N^k · O[k]
   ```
   where `E[k]` and `O[k]` are the FFT outputs of the even and odd sub-sequences, and `W_N^k = e^{-j2πk/N}` is the **twiddle factor**.

### Complexity

| Algorithm | Time Complexity | Space Complexity |
|---|---|---|
| Naïve DFT | O(N²) | O(N) |
| FFT (Cooley-Tukey) | O(N log N) | O(N log N) recursive |

---

## Project Structure

```
FFT-AND-IFFT/
├── FFT.c            # Recursive FFT in C — arbitrary power-of-2 N
├── IFFT.c           # Recursive IFFT in C — arbitrary power-of-2 N
├── FFT.asm          # FFT in MIPS32 Assembly — supports N = 2 or N = 4
├── IFFT.asm         # IFFT in MIPS32 Assembly — supports N = 2 or N = 4
├── FFT_REPORT.pdf   # Detailed technical report on the FFT implementation
└── IFFT_REPORT.pdf  # Detailed technical report on the IFFT implementation
```

---

## Implementations

### C Implementation

**Files:** `FFT.c`, `IFFT.c`

#### FFT (`FFT.c`)
- Uses `<complex.h>` for native **complex double** arithmetic.
- Implements the recursive Cooley-Tukey algorithm for any **power-of-2** input size N.
- **Twiddle factor**: `cexp(-2.0 * I * π * k / n)` — complex exponential using Euler's formula.
- Dynamically allocates even/odd sub-arrays with `malloc`, recurses, then combines with the butterfly step.
- **Output**: Each frequency bin `X[k]` as `real + imag·i`.

#### IFFT (`IFFT.c`)
- Mirrors the FFT structure but with a **conjugated twiddle factor**: `cexp(+j * 2π * k / n)`.
- After each butterfly stage, **divides by 2** (equivalent to the 1/N normalization distributed across log₂N stages).
- Accepts arbitrary power-of-2 N.

---

### MIPS Assembly Implementation

**Files:** `FFT.asm`, `IFFT.asm`

#### Architecture
- Targets the **MIPS32 ISA**, designed to run in simulators such as **MARS** or **SPIM**.
- Supports **N = 2** and **N = 4** (hardcoded radix-2 butterfly stages).
- Complex numbers are stored interleaved in memory: `[real₀, imag₀, real₁, imag₁, ...]`, each word 4 bytes wide (total 8 bytes per complex number).

#### Key Register Conventions

| Register | Role |
|---|---|
| `$s0` | N (array size) |
| `$s1` | Base address of input array |
| `$s2` | Working base address |
| `$t0–$t9` | Temporaries (real/imag values, addresses) |
| `$s4–$s7` | Twiddle factor multiplication intermediates |
| `$ra` | Return address (saved/restored on stack) |

#### FFT.asm
- **N=2**: Computes a 2-point DFT directly — sums and differences of the two inputs.
- **N=4**: Splits into two N=2 FFTs (even and odd elements), then applies **twiddle factor multiplication** using pre-stored integer twiddle tables (`twiddle_n4`: `W4^0=(1,0)`, `W4^1=(0,-1)`).
- Uses the **stack** for saving/restoring `$s` registers and `$ra` across recursive `jal fft` calls.

#### IFFT.asm
- **N=2**: Butterfly with subtraction-first ordering and **arithmetic right-shift by 1** (`sra`) to implement ×½ scaling.
- **N=4**: Two recursive IFFT calls on even/odd halves, then combines with **conjugated twiddle factors** (`twiddle_n4_ifft`: `W4^1=(0,+1)` instead of `(0,-1)`), and scales each element by `÷N` using integer division (`div`/`mflo`).

---

## Key Concepts & Terminology

| Term | Definition |
|---|---|
| **DFT** | Discrete Fourier Transform — maps N time-domain samples to N frequency-domain coefficients |
| **FFT** | Fast Fourier Transform — O(N log N) algorithm to compute the DFT |
| **IFFT** | Inverse FFT — recovers the time-domain signal from frequency-domain coefficients |
| **Twiddle Factor** | Complex exponential `W_N^k = e^{±j2πk/N}` used to rotate vectors in the complex plane during butterfly operations |
| **Butterfly Operation** | Core FFT computation: `X[k] = E[k] + W·O[k]`, `X[k+N/2] = E[k] - W·O[k]` |
| **Radix-2** | Algorithm that splits the input into 2 sub-problems at each level |
| **DIT (Decimation-In-Time)** | Input is split by index parity (even/odd); butterflies run from smallest to largest FFT size |
| **Complex Number** | Number of the form `a + jb`; `a` is the real part, `b` is the imaginary part |
| **Frequency Bin** | Each output `X[k]` represents the amplitude and phase of a specific frequency component |
| **Normalization (1/N)** | Scaling applied in the IFFT so that IFFT(FFT(x)) = x |
| **Stack Frame** | Memory region on the call stack used to save registers and local variables across subroutine calls |
| **MIPS32 ISA** | 32-bit Reduced Instruction Set Computer (RISC) architecture with fixed-width 32-bit instructions |
| **Syscall** | MIPS system call used for I/O (print integers, strings; read integers) |
| **`sra` (Shift Right Arithmetic)** | MIPS instruction that right-shifts a value while preserving the sign bit — used here for fast division by 2 |
| **`jal` / `jr $ra`** | MIPS instructions for subroutine call (jump-and-link) and return (jump register) |

---

## How to Compile and Run (C)

### Prerequisites
- GCC (or any C99-compliant compiler)
- Standard math and complex libraries (`-lm`)

### FFT
```bash
gcc -o fft FFT.c -lm
./fft
```

### IFFT
```bash
gcc -o ifft IFFT.c -lm
./ifft
```

### Assembly (MIPS)
Open `FFT.asm` or `IFFT.asm` in the **MARS** MIPS simulator or **SPIM** and run it. Both tools provide a console for entering input values.

---

## Input / Output Format

### Input
```
N
real₀ imag₀
real₁ imag₁
...
realₙ₋₁ imagₙ₋₁
```
- `N` must be a **power of 2** for the C programs (2 or 4 for the Assembly programs).
- Each complex sample is entered as two space-separated floating-point numbers (real and imaginary parts).

### Output
```
X[0] = <real> + <imag>i
X[1] = <real> + <imag>i
...
```

---

## Example

**Input** (N=4, signal `[1, 1, 1, 1]`):
```
4
1 0
1 0
1 0
1 0
```

**FFT Output** (frequency-domain representation):
```
X[0] = 4.00 + 0.00i
X[1] = 0.00 + 0.00i
X[2] = 0.00 + 0.00i
X[3] = 0.00 + 0.00i
```
> A constant (DC) signal has all energy concentrated in the zeroth frequency bin.

**IFFT Output** (inverse transform recovers the original signal):
```
(1.000000, 0.000000)
(1.000000, 0.000000)
(1.000000, 0.000000)
(1.000000, 0.000000)
```

---

## Reports

Detailed technical reports covering derivations, algorithmic analysis, and implementation notes are included:

- 📄 [`FFT_REPORT.pdf`](FFT_REPORT.pdf) — FFT implementation report
- 📄 [`IFFT_REPORT.pdf`](IFFT_REPORT.pdf) — IFFT implementation report
