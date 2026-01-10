module Master_d(
//System-Side Interface
  input req_valid,
  input [31:0]req_addr,
  input req_write,
  input [31:0]req_wdata,
  
  output reg req_ready,
  output reg resp_valid,
  output reg [31:0]resp_rdata,
  output reg resp_error,
  
//APB Bus-Side Interface
  input PCLK,
  input PRESETn,
  input PREADY,
  input [31:0]PRDATA,
  input PSLAVERR,
  
  output reg [31:0]PADDR,
  output reg PSELx,
  output reg PWRITE,
  output reg [31:0]PWDATA,
  output reg PENABLE
    );

reg [31:0]addr_reg;  // Store requested address
reg [31:0]wdata_reg; // Store write data
reg write_reg;       // Store read/write type (1 = write, 0 = read)

reg [1:0]present_state, next_state;
localparam IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b10;  


always @(posedge PCLK or negedge PRESETn)
begin
  if(!PRESETn)
   begin  
    addr_reg <= 0;
    write_reg <= 0;
    wdata_reg <= 0;
    resp_valid <= 0;
    resp_rdata <= 0;
    resp_error <= 0; 
    present_state <= IDLE;
   end
  else 
   begin
    present_state <= next_state;
    if(present_state == ACCESS && PREADY)
    begin
      resp_rdata <= (!write_reg) ? PRDATA : 32'd0;
      resp_error <= PSLAVERR;
      resp_valid <= 1'b1;
    end
    else
      resp_valid <= 1'b0;
    
    if(present_state == IDLE && req_valid) //Present State is in IDLE i.e, req_ready is HIGH!
    begin
     addr_reg <= req_addr;
     wdata_reg <= req_wdata;
     write_reg <= req_write;
   end
 end   
end

always @(*)
begin
req_ready  = 0;
PADDR   = 0;
PSELx   = 0;
PWRITE  = 0;
PWDATA  = 0;
PENABLE = 0;
next_state = present_state;
  case(present_state)  
     IDLE : begin
              PSELx = 0;
              PENABLE = 0;
              req_ready = 1;
              if(req_valid)
                next_state = SETUP;
            end
            
    SETUP : begin
              PADDR = addr_reg;
              PWRITE = write_reg;
              PWDATA = wdata_reg;  
              PSELx = 1;
              PENABLE = 0;
              req_ready = 0; // Master is Busy, Block new request
              
              next_state = ACCESS;
            end
            
   ACCESS : begin
              PSELx = 1;
              PENABLE = 1;
              PADDR = addr_reg;  
              PWRITE = write_reg;
              PWDATA = wdata_reg;
              next_state = (PREADY) ? (IDLE):(ACCESS); 
            end
  default : next_state = present_state; 
  endcase
end

endmodule

