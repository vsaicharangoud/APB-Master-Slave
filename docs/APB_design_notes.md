# APB Master–Slave Project  
## Design Working Notes & Concept Summary

---

## 1. Overview
This project implements a simple APB (Advanced Peripheral Bus) Master–Slave system in Verilog, including a system-side request interface.  
The design models how a CPU or system logic communicates with an APB peripheral through an APB master.

The system consists of three main entities:

1. **SYSTEM**  
   - Represented by the testbench  
   - Acts as CPU-side logic generating requests  

2. **MASTER**  
   - FSM-based APB master  
   - Converts system requests into APB bus transactions  

3. **SLAVE**  
   - APB peripheral  
   - Implements memory-mapped registers  

---

## 2. APB Protocol Basics
APB operates using two bus phases:

- **SETUP Phase**  
  Address and control signals are driven and stabilized.

- **ACCESS Phase**  
  The actual data transfer (read or write) occurs.

In this design, the APB master FSM uses **three states**:
- `IDLE`
- `SETUP`
- `ACCESS`

There is **no separate COMPLETE state**.  
Transaction completion and response generation happen **inside the ACCESS state** when `PREADY` is asserted.

---

## 3. Master Has Two Sides (Very Important)

### 3.1 System Side Interface (Left Interface)

**Inputs from System / CPU / Testbench**
- `req_valid`  : Indicates a valid system request
- `req_addr`   : Address to access
- `req_write`  : 1 = write, 0 = read
- `req_wdata`  : Write data (for write operations)

**Outputs to System**
- `req_ready`  : Master is ready to accept a new request
- `resp_valid` : Transaction complete
- `resp_rdata` : Read data (for read operations)
- `resp_error` : Error response (propagated from `PSLAVERR`)

---

### 3.2 APB Bus Side Interface (Right Interface)

**Outputs to APB Bus**
- `PADDR`
- `PSELx`
- `PWRITE`
- `PWDATA`
- `PENABLE`

**Inputs from APB Bus**
- `PREADY`
- `PRDATA`
- `PSLAVERR`

---

## 4. Stage-by-Stage Operation

This section explains what the **System**, **Master**, and **Slave** do in each FSM stage.

---

## 4.1 IDLE Stage

### SYSTEM
- Observes `req_ready = 1`
- When ready, asserts `req_valid` on a clock edge
- Drives:
  - `req_addr`
  - `req_write`
  - `req_wdata` (for write transactions)

### MASTER
- FSM state = `IDLE`
- Drives:
  - `PSEL    = 0`
  - `PENABLE = 0`
  - `req_ready = 1`
- On rising clock edge, when `req_valid = 1`:
  - Latches request into internal registers:
    - `addr_reg`
    - `write_reg`
    - `wdata_reg`
- Transitions to `SETUP` state

### SLAVE
- Observes `PSEL = 0`
- Bus is idle
- No operation performed

---

## 4.2 SETUP Stage

### MASTER
- FSM state = `SETUP`
- Drives:
  - `PSEL    = 1`
  - `PENABLE = 0`
  - `PADDR   = addr_reg`
  - `PWRITE  = write_reg`
  - `PWDATA  = wdata_reg`
- Address and control signals are stable
- No data transfer occurs
- Transitions to `ACCESS` on the next clock edge

### SLAVE
- Detects `PSEL = 1` and `PENABLE = 0`
- Decodes address combinationally
- Computes:
  - `addr_valid_next`
  - `addr_index_next`
- On next rising clock edge:
  - Latches decoded address into:
    - `addr_valid_r`
    - `addr_index_r`

### SYSTEM
- Deasserts `req_valid`
- Waits for response from master

---

## 4.3 ACCESS Stage (Transfer + Response)

### MASTER
- FSM state = `ACCESS`
- Drives:
  - `PSEL    = 1`
  - `PENABLE = 1`
  - `PADDR`, `PWRITE`, and `PWDATA` remain stable
- Waits for `PREADY` from slave
- When `PREADY = 1`:
  - On rising clock edge:
    - Captures `PRDATA` (for read transactions)
    - Captures `PSLAVERR`
    - Asserts `resp_valid` for one clock cycle
  - Returns FSM to `IDLE` state

---

### SLAVE Behavior in ACCESS Stage

#### Write Operation (`PWRITE = 1`)
- On rising clock edge:
  - If `addr_valid_r = 1`:
    - `REGx <= PWDATA`
- Implemented as **sequential logic** because storage elements are updated

#### Read Operation (`PWRITE = 0`)
- Combinationally drives:
  - `PRDATA = REGx` (based on `addr_index_r`)
- No clock edge required because no state is modified

#### Handshake & Error Handling
- `PREADY` is asserted to indicate transfer completion
- `PSLAVERR` is asserted if the address is invalid

---

## 5. End of Transaction

### SYSTEM
- Waits for `resp_valid`
- Samples:
  - `resp_rdata`
  - `resp_error`
- Transaction is complete

---

## 6. Key Design Concepts Reinforced
- Clear separation of **System**, **Master**, and **Slave** roles
- Correct APB **SETUP and ACCESS phase timing**
- Sequential logic used for **state and storage**
- Combinational logic used for **read data and decoding**
- Wait-state handling using `PREADY`
- Clock-synchronous system-to-master handshake

---
