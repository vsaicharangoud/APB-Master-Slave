module APB_tb;

reg PCLK;
reg PRESETn;

// System-Side Signals
reg req_valid;
reg [31:0]req_addr;
reg req_write;
reg [31:0]req_wdata;

wire req_ready;
wire resp_valid;
wire [31:0]resp_rdata;
wire resp_error;

// APB Bus-Side Signals
wire [31:0]PADDR;
wire PSELx;
wire PWRITE;
wire [31:0]PWDATA;
wire PENABLE;

wire PREADY;
wire [31:0]PRDATA;
wire PSLAVERR;


//DUTs

Master_d MASTER(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    
    .req_valid(req_valid),
    .req_addr(req_addr),
    .req_write(req_write),
    .req_wdata(req_wdata),
    
    .req_ready(req_ready),
    .resp_valid(resp_valid),
    .resp_rdata(resp_rdata),
    .resp_error(resp_error),
    
    .PADDR(PADDR),
    .PSELx(PSELx),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PENABLE(PENABLE),
   
    .PREADY(PREADY),
    .PRDATA(PRDATA),
    .PSLAVERR(PSLAVERR)
  );

Slave_d SLAVE(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    
    .PADDR(PADDR),   
    .PSELx(PSELx),   
    .PWRITE(PWRITE), 
    .PWDATA(PWDATA), 
    .PENABLE(PENABLE),
    
    .PREADY(PREADY),   
    .PRDATA(PRDATA),   
    .PSLAVERR(PSLAVERR)
  );

initial PCLK = 0;
always #5 PCLK = ~PCLK;

initial begin
// RESET
req_valid = 0;
req_addr = 0;
req_write = 0;
req_wdata = 0;

PRESETn = 0;   #20
PRESETn = 1;

//------------------- WRITE REG2 (0X08) -------------------
@(posedge PCLK);
while(!req_ready) @(posedge PCLK);

req_addr = 32'h0000_0008; //REG-2
req_write = 1;
req_wdata = 32'hABCD1234;
req_valid = 1;

@(posedge PCLK);
req_valid = 0;

wait(resp_valid);
@(posedge PCLK);
$display("WRITE DONE!, ERROR = %0d ", resp_error);


//------------------- WRITE REG5 (0X14) -------------------
@(posedge PCLK);
while(!req_ready) @(posedge PCLK);

req_addr = 32'h0000_0014; //REG-5
req_write = 1;
req_wdata = 32'h9876_4321;
req_valid = 1;

@(posedge PCLK);
req_valid = 0;

wait(resp_valid);
@(posedge PCLK);
$display("WRITE DONE!, ERROR = %0d ", resp_error);


// ------------------- READ REG2 (0x08) -------------------
@(posedge PCLK);
while(!req_ready) @(posedge PCLK);

req_addr = 32'h0000_0008;
req_write = 0;   // READ
req_valid = 1;

@(posedge PCLK);
req_valid = 0;

wait(resp_valid);
@(posedge PCLK);
$display("READ DATA = %h, ERROR = %0d",resp_rdata, resp_error);
// ------------------- END SIMULATION -------------------
#20
$finish;
end
endmodule
