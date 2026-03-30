A document is a model or material that I have created during my own learning process
========================================================================
MASH111_RECENT_BASELINE_RECORD 20260330
Version   : Baseline summary from recent conversation history
Purpose   : Freeze-line record for subsequent DWA / DAC / AMS co-design
Scope     : MASH 1-1-1 digital modulator only; no Verilog source included
Status    : RTL architecture regarded as frozen by current workflow
========================================================================


[0] WHAT IS TREATED AS "KEY DETAIL" IN THIS RECORD
--------------------------------------------------
For future work continuity, the following items are treated as key details:

1. Architecture definition
2. Final numerical/data-path settings
3. Digital cancellation and output mapping
4. Low-power implementation rules already chosen
5. Verification coverage and current pass status
6. Interface assumptions toward HB / DWA / DAC
7. Frozen boundaries and items NOT to change casually
8. Open points that still require system-level validation


[1] FINAL ARCHITECTURE POSITIONING
----------------------------------
Project context:
- This MASH111 block is the digital modulator part inside the Delta-Sigma DAC chain.
- Upstream is the 5-stage HB interpolation chain.
- Downstream is DWA, then current-steering DAC, then analog output path.

Final modulator architecture:
- Order: 3rd-order
- Structure: MASH 1-1-1
- Per-stage quantizer: 1-bit
- Overall digital output after cancellation: equivalent multi-level output
- This is NOT a monolithic true 3-bit internal quantizer.
- It is a cascade of three 1-bit stages plus digital error cancellation.

Practical interpretation:
- Stage 1 generates first carry/bitstream
- Stage 2 shapes Stage-1 residue
- Stage 3 shapes Stage-2 residue
- Digital recombination produces the final multi-level code for DWA interface


[2] FINAL NUMERICAL / DATA-PATH SETTINGS RECOVERED FROM RECENT DIALOGUE
------------------------------------------------------------------------
Confirmed / repeatedly used settings:

A. Input word length to MASH:
- W = 14 bits

B. System-level sampling assumption used in recent discussions:
- Baseband Fs = 48 kHz
- OSR = 32
- Therefore modulator-side effective sample rate example:
  Fout = 48 kHz x 32 = 1.536 MHz

C. Important clarification already settled in discussion:
- After interpolation / upsampling, the signal rate changes
- But the MASH input word length is still treated as 14 bits in the current design convention
- In other words:
  "sample rate changes" != "input word width automatically changes"

D. Output code space:
- Raw combined MASH output range: [-3, 4]
- Mapped output range for DWA interfacing: [0, 7]

E. DWA relevance:
- The mapped code [0..7] corresponds to the number of active unit elements
- Downstream physical control bus discussed as DWA<6:0> for 7 unit elements

Important note:
- The range [-3,4] and remap to [0,7] is one of the most critical frozen interface facts
- This must remain consistent with DWA, thermometer/rotation logic, and DAC element activation


[3] FINAL SIGNAL / FUNCTIONAL LOGIC THAT WAS EFFECTIVELY LOCKED
---------------------------------------------------------------
Top-level conceptual flow:

input(14b) 
  -> Stage1 accumulator + 1b quantizer
  -> residue1
  -> Stage2 accumulator + 1b quantizer
  -> residue2
  -> Stage3 accumulator + 1b quantizer
  -> digital cancellation
  -> raw multi-level output y_raw in [-3,4]
  -> mapped output y_map in [0,7]
  -> DWA

The digital cancellation path was discussed in modular form using:

1. delay_1
2. diff1_1b
3. diff2_1b

Recovered cancellation meaning:
- First-difference path used for second stage carry stream
- Second-difference path used for third stage carry stream

Recovered formulas consistent with recent discussion:
- d1[n] = c2[n] - c2[n-1]
- d2[n] = c3[n] - 2*c3[n-1] + c3[n-2]
- raw recombination conceptually follows:
  y_raw = P0 + d1 + d2

Why this matters:
- This explains why the raw output range becomes [-3,4]
- This also explains why remapping by a constant offset can yield [0,7]

Mapped output:
- y_map = y_raw + 3
- Therefore:
  [-3,4] -> [0,7]

This mapping is a core frozen interface rule for subsequent DWA work.


[4] FINAL SUBMODULE PARTITION THAT WAS USED
-------------------------------------------
The MASH111 work was split into small modules and individually testbenched.

Recovered module partition:
1. mash_acc_ce
2. delay_1
3. diff1_1b
4. diff2_1b
5. mash111_top

Recovered testbench partition:
1. tb_mash_acc_ce
2. tb_delay_1
3. tb_diff1_1b
4. tb_diff2_1b
5. tb_mash111_top

Reason this partition is important:
- It isolates arithmetic correctness from top-level recombination errors
- It makes later debug easier if AMS co-sim shows mismatch
- It preserves modular traceability for academic/report use
- It helps identify whether an issue is in:
  accumulator / delay / difference path / final mapping

This modular partition should be preserved unless there is a very strong reason to refactor.


[5] MASH_ACC_CE BLOCK: FINAL ENGINEERING INTENTION
--------------------------------------------------
The accumulator block was not treated as a naive always-active accumulator.
It was explicitly shaped toward low-power practical RTL.

Recovered design intent:
- Parameterized width: W = 14
- Clock input: clk
- Reset: rst_n
- Clock enable: ce
- Quantizer/carry output: p_out
- Residue/state-related outputs exposed for chaining/debug

Most important frozen implementation philosophy:
- CE-based low-power control was intentionally adopted
- No hand-written gated clock was preferred
- Synthesis-friendly clock-enable style was favored over risky manual clock gating

Recovered low-power tactic inside accumulator discussion:
- When ce = 0:
  - state registers hold
  - unnecessary toggling should be reduced
  - combinational adder excitation was intentionally suppressed by input isolation logic

This point is important:
- The design did not just "pause registers"
- It also tried to reduce useless internal switching activity
- This was a deliberate low-power choice, not an accidental coding style


[6] LOW-POWER RULES THAT WERE EFFECTIVELY CHOSEN FOR MASH111
------------------------------------------------------------
The recent discussion strongly converged to the following low-power rules:

1. Use CE-based control, not handwritten gated clock trees
2. Hold state when ce = 0
3. Reduce unnecessary combinational toggling when ce = 0
4. Keep the structure simple and synthesis-safe
5. Prefer engineering robustness over overly aggressive micro-optimization

What this means for future work:
- Do NOT casually replace CE logic with custom clock gating
- Do NOT destroy the frozen power-saving behavior by rewriting modules into always-toggling datapaths
- If later synthesis adds integrated clock gating automatically, that is a downstream backend decision
- But RTL intent at this stage is CE-based low-power control

This is one of the key frozen design philosophies.


[7] DIGITAL OUTPUT INTERFACE TOWARD DWA: FINAL BASELINE
-------------------------------------------------------
The most important interface facts toward DWA are:

1. Raw MASH output:
   y_raw in [-3,4]

2. Mapped output:
   y_map in [0,7]

3. Physical interpretation for DWA:
   - 0 means zero active unit elements
   - 7 means all seven unit elements active
   - Intermediate values correspond to 1..6 active elements

4. DWA bus context:
   - DWA<6:0> was repeatedly discussed as the 7-element control output

5. Practical implication:
   - The modulator does NOT directly drive analog unit elements
   - It first produces a mapped digital code suitable for element selection/rotation

6. Record-level warning:
   - Any future mismatch between MASH and DWA should first check:
     a) y_raw sign/range
     b) y_map offset
     c) whether [0..7] is interpreted as count or direct one-hot pattern
     d) whether rotation index is mod-7 consistent

This interface boundary is critical and must stay consistent.


[8] VERIFICATION STATUS RECOVERED FROM RECENT DIALOGUE
------------------------------------------------------
Recent verification position can be summarized as follows:

A. Verification strategy used:
- Small-module testbenches first
- Then top-level testbench for the complete MASH111 chain

B. Confirmed top-level simulation result recovered from dialogue:
- ModelSim command:
  vsim tb_mash111_top
  run -all
- Observed result:
  [PASS] tb_mash111_top passed.
- Recorded finish around:
  Time: 1125 ns

C. Interpretation:
- Functional RTL-level correctness was considered achieved at the current verification depth
- The frozen statement should be:
  "Top-level functional testbench passed"

D. Important limitation:
- This PASS indicates logic/path consistency under the designed TB
- It is NOT yet a full proof of:
  - final in-band noise target
  - final PSD superiority
  - final silicon power
  - final mixed-signal behavior after DAC non-idealities

E. Recommended record wording:
- "The MASH111 Verilog model is functionally frozen after submodule-level and top-level TB validation."
- That wording is safe and consistent with recent history


[9] WHAT WAS ALREADY RESOLVED CONCEPTUALLY
------------------------------------------
The following conceptual points were already settled enough to be treated as baseline assumptions:

1. The MASH block should remain modular, not monolithic
2. Each stage uses a 1-bit quantizer/carry output
3. The overall multi-level output is created by digital cancellation, not by replacing the internal stages with a 3-bit quantizer
4. The modulator input width remains 14 bits in the present design convention
5. The output range for DWA interfacing is [0,7] after remapping
6. CE-based low-power strategy is part of the design intent
7. The current RTL model is frozen; future work should move to integration and system validation rather than re-editing the modulator architecture


[10] WHAT SHOULD BE TREATED AS FROZEN BOUNDARIES
------------------------------------------------
The following items should not be casually changed in subsequent work:

FROZEN-1:
- MASH order = 1-1-1 cascade (3rd order overall)

FROZEN-2:
- Per-stage quantizer = 1-bit

FROZEN-3:
- Input word width convention = 14 bits

FROZEN-4:
- Raw output range = [-3,4]

FROZEN-5:
- Mapped output range = [0,7]

FROZEN-6:
- Modular sub-block partition:
  mash_acc_ce / delay_1 / diff1_1b / diff2_1b / mash111_top

FROZEN-7:
- CE-based low-power strategy remains the RTL-level power method

FROZEN-8:
- Current modulator RTL is not the place for further structural experimentation unless a hard bug appears

Practical meaning:
- Subsequent effort should move to integration, measurement, export, and system proof
- Not back into endless MASH micro-refactoring


[11] ITEMS THAT ARE IMPORTANT BUT SHOULD BE MARKED "CHECK SOURCE IF NEEDED"
---------------------------------------------------------------------------
These items are very likely consistent with the frozen code, but if a later report requires
strict code-level exactness, they should be checked once against the source files:

1. Exact reset style of every submodule
   - Very likely active-low reset convention is used consistently
   - At least mash_acc_ce discussion clearly used rst_n

2. Exact signed/unsigned declaration on every internal bus
   - The arithmetic meaning is clear
   - But if writing a formal report, the exact Verilog declarations should be copied from source

3. Exact naming of P0/P1/P2 versus p0/p1/p2 versus c1/c2/c3
   - Functional meaning is clear
   - Case/style may differ by final file version

4. Exact bit width of diff2_1b output bus
   - Functionally second-difference behavior is clear
   - Bus declaration should be checked in code if later included in a thesis appendix

These are not conceptual uncertainties.
They are only "do not misquote the final source text" warnings.


[12] WHAT IS EXPLICITLY NOT PART OF THIS FROZEN MASH RECORD
-----------------------------------------------------------
The following items are related, but should NOT be confused with the frozen MASH111 settings:

1. HB coefficient optimization details
2. CSD coefficient synthesis for the interpolation filters
3. Full-chain PSD after HB + MASH + DWA + DAC + analog LPF
4. Final SNDR / SFDR claim
5. Analog mismatch and DWA noise-shaping measured result
6. Post-synthesis / post-layout timing and power numbers
7. AMS waveform proof in Virtuoso

Reason:
- These belong to the next-stage validation/integration work
- They are not intrinsic frozen parameters of the MASH111 RTL architecture itself


[13] MOST IMPORTANT ENGINEERING INTERPRETATION FOR FUTURE WORK
--------------------------------------------------------------
If downstream integration later shows a problem, the debug priority should be:

Priority-1:
- Check y_raw range really stays in [-3,4]

Priority-2:
- Check y_map offset and numeric remapping to [0,7]

Priority-3:
- Check P0 / d1 / d2 alignment and delay consistency

Priority-4:
- Check DWA interpretation of the mapped code:
  count-based vs pattern-based misunderstanding

Priority-5:
- Check CE behavior when sample-valid timing is not continuous

This is likely the most efficient future debug path.


[14] RECOMMENDED ONE-PARAGRAPH BASELINE DESCRIPTION
---------------------------------------------------
The recent MASH111 work has converged to a frozen third-order MASH 1-1-1 digital modulator,
implemented as a cascade of three 1-bit stages with modular digital error cancellation.
The modulator input width is maintained at 14 bits under the current system convention,
while the raw recombined digital output spans [-3,4] and is remapped to [0,7] for the
7-element DWA interface. The RTL implementation was intentionally structured with small
verifiable submodules and a CE-based low-power strategy rather than handwritten clock gating.
Submodule-level and top-level testbenches were completed, and the top-level ModelSim run
reported PASS, so the present MASH111 model should be treated as functionally frozen and
used as the baseline for subsequent DWA, DAC, and mixed-signal integration work.


[15] ULTRA-CONDENSED FREEZE SNAPSHOT
------------------------------------
Architecture : 3rd-order MASH 1-1-1
Stage bits   : 1-bit quantizer per stage
Input width  : 14 bits
OSR context  : 32
Rate example : 1.536 MHz for 48 kHz baseband
Recombine    : P0 + d1 + d2
Raw output   : [-3,4]
Mapped code  : [0,7]
DWA target   : 7 unit elements, DWA<6:0>
Low power    : CE-based, no handwritten gated clock
Verification : submodule TBs + top TB completed
Top result   : tb_mash111_top PASS
Workflow     : RTL frozen, move to integration/measurement

========================================================================
END OF RECORD
========================================================================
