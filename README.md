# 4-Bit Fixed-Priority Arbiter – SystemVerilog/UVM Verification

## Overview

This project implements and verifies a **4-bit fixed-priority arbiter** using **SystemVerilog and UVM**.

The arbiter receives four request signals and generates a one-hot grant based on a fixed-priority scheme. `req[0]` has the highest priority, followed by `req[1]`, `req[2]`, and `req[3]`.

The verification environment uses **constrained-random stimulus, UVM components, a reference-model-based scoreboard, functional coverage, and SystemVerilog assertions** to verify the design behavior.

## Design Behavior

The arbiter supports four request inputs:

```text
req[3:0]
```

and produces four grant outputs:

```text
gnt[3:0]
```

Priority order:

```text
req[0] > req[1] > req[2] > req[3]
```

For example:

| Request | Grant  | Description                    |
| ------- | ------ | ------------------------------ |
| `0000`  | `0000` | No request                     |
| `0001`  | `0001` | Grant request 0                |
| `0010`  | `0010` | Grant request 1                |
| `0100`  | `0100` | Grant request 2                |
| `1000`  | `1000` | Grant request 3                |
| `0011`  | `0001` | Request 0 has priority         |
| `1010`  | `0010` | Request 1 has priority         |
| `1100`  | `0100` | Request 2 has priority         |
| `1111`  | `0001` | Request 0 has highest priority |

## Verification Environment

The testbench follows a standard UVM architecture:

```text
                    +----------------+
                    |    Sequence    |
                    +-------+--------+
                            |
                            v
                    +---------------+
                    |   Sequencer   |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    |    Driver     |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    |      DUT      |
                    | Fixed Priority|
                    |    Arbiter    |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    |    Monitor    |
                    +-------+-------+
                            |
                 +----------+----------+
                 |                     |
                 v                     v
          +-------------+       +-------------+
          |  Scoreboard |       |  Functional |
          |             |       |   Coverage  |
          +-------------+       +-------------+
```

### UVM Components

* **Sequence Item** – Represents randomized request transactions.
* **Sequence** – Generates multiple randomized request transactions.
* **Sequencer** – Provides transactions to the driver.
* **Driver** – Drives request transactions onto the DUT interface.
* **Monitor** – Samples request and grant signals and publishes transactions through an analysis port.
* **Scoreboard** – Calculates the expected grant using an independent priority model and compares it against the DUT output.
* **Coverage Subscriber** – Collects functional coverage for request and grant values.
* **Environment** – Instantiates and connects the agent, scoreboard, and coverage components.
* **Test** – Starts the sequence and controls the UVM test phase.

## Verification Features

### 1. Constrained-Random Verification

Randomized request patterns are generated to exercise different arbitration scenarios.

The testbench can generate:

* No active requests
* Single active request
* Multiple simultaneous requests
* All requests active
* Different priority combinations

### 2. Scoreboard Checking

The scoreboard contains an independent reference model for the fixed-priority arbitration behavior.

The expected grant is calculated according to:

```text
req[0] > req[1] > req[2] > req[3]
```

The expected grant is then compared with the actual DUT grant.

Example:

```text
req      = 1011
expected = 0001
actual   = 0001

PASS
```

### 3. Functional Coverage

Functional coverage is collected for:

* Request combinations
* Grant values
* No-grant condition
* Individual grant conditions

The testbench reports overall, request, and grant coverage at the end of simulation.

### 4. SystemVerilog Assertions

SystemVerilog assertions are included to check arbitration behavior and grant properties.

The assertion checker is bound to the DUT using SystemVerilog `bind`.

Example checks include:

* One-hot grant behavior
* Request/grant relationship
* Reset behavior

## Reset Verification

The DUT includes synchronous reset behavior.

During reset:

```text
gnt = 4'b0000
```

After reset is released, the arbiter responds to incoming requests according to the fixed-priority scheme.

## Simulation

The testbench generates a VCD waveform:

![Fixed Priority Arbiter Waveform](waveform/priority_arbiter_waveform.png)

## Functional Coverage
The coverage report below shows the functional coverage achieved for the randomized request and grant scenarios.
![Fixed Priority Arbiter Waveform](waveform/coverage.png)

## Technologies

* SystemVerilog
* UVM
* Constrained-Random Verification
* Functional Coverage
* SystemVerilog Assertions (SVA)
* Reference Model / Scoreboard
* VCD Waveform Analysis

## Project Structure

```text
fixed-priority-arbiter-uvm/
│
├── rtl/
│   └── fixed_priority_arb.sv
│
├── tb/
│   └── tb.sv
│
├── waveform/
│   └── priority_arbiter_waveform.png
│
├── README.md
└── .gitignore
```

## Key Verification Concepts Demonstrated

* UVM testbench architecture
* Sequence/Sequencer/Driver communication
* Virtual interface
* UVM configuration database
* Monitor and analysis ports
* Scoreboard-based checking
* Constrained-random stimulus
* Functional coverage
* SystemVerilog assertions
* `bind` construct
* Reset verification
* Fixed-priority arbitration
* Waveform-based debug
* Regression-oriented verification

## Author

**Yeswanthi Gandham**

IP/SoC Design Verification Engineer

[GitHub](https://github.com/yeswanthigandham)
