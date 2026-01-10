module Slave_d(
  input PCLK,
  input PRESETn,
  input [31:0]PADDR,
  input PSELx,
  input PWRITE,         // 1 = write, 0 = read
  input [31:0]PWDATA,
  input PENABLE,

  output reg PREADY,
  output reg [31:0]PRDATA,
  output reg PSLAVERR
    );

reg [31:0]REG0;
reg [31:0]REG1;
reg [31:0]REG2;
reg [31:0]REG3;
reg [31:0]REG4;
reg [31:0]REG5;
reg [31:0]REG6;
reg [31:0]REG7;

reg addr_valid_next;
reg [2:0]addr_index_next;
reg addr_valid_r;
reg [2:0]addr_index_r;

//==========================SEQUENTIAL BLOCK==========================
always @(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
 begin
 REG0 <= 0;
 REG1 <= 0;
 REG2 <= 0;
 REG3 <= 0;
 REG4 <= 0;
 REG5 <= 0;
 REG6 <= 0;
 REG7 <= 0;
 addr_valid_r <= 0;
 addr_index_r <= 0;
 end
else
 begin
  if(PSELx && !PENABLE)
  begin 
    addr_valid_r <= addr_valid_next;
    addr_index_r <= addr_index_next;
  end
    
    
  // ACCESS - WRITE STATE   
  if(PSELx && PENABLE && PWRITE && addr_valid_r)
  begin
    case(addr_index_r)
      3'b000 : REG0 <= PWDATA; 
      3'b001 : REG1 <= PWDATA; 
      3'b010 : REG2 <= PWDATA; 
      3'b011 : REG3 <= PWDATA; 
      3'b100 : REG4 <= PWDATA; 
      3'b101 : REG5 <= PWDATA; 
      3'b110 : REG6 <= PWDATA; 
      3'b111 : REG7 <= PWDATA; 
    endcase  
  end
 end
end

//==========================COMBINAIONAL BLOCK==========================
always @(*)
begin
PREADY = 0;
PSLAVERR = 0;
PRDATA = 32'd0;
addr_valid_next = 0;
addr_index_next = 0;

  // IDLE Stage
  if(PSELx == 0)
  begin
    PREADY = 0;
    PSLAVERR = 0;
  end
  
  // SETUP Stage  
  if(PSELx && PENABLE == 0)
  begin
    PREADY = 0;
    addr_valid_next = (PADDR[6:2] <= 5'd7); 
    addr_index_next = PADDR[4:2];
  end
  
  // ACCESS Stage 
  if(PSELx && PENABLE)
  begin
    PREADY = 1;
    if(addr_valid_r == 0)
      PSLAVERR = 1;
  end
  
  
  // ACCESS - READ STATE
  if(PSELx && PENABLE && !PWRITE)
  begin  
    if(addr_valid_r)
    begin
     case(addr_index_r)
       3'b000 : PRDATA = REG0; 
       3'b001 : PRDATA = REG1; 
       3'b010 : PRDATA = REG2; 
       3'b011 : PRDATA = REG3; 
       3'b100 : PRDATA = REG4; 
       3'b101 : PRDATA = REG5; 
       3'b110 : PRDATA = REG6; 
       3'b111 : PRDATA = REG7; 
      default : PRDATA = 32'd0;   
     endcase
    end 
    else
      PRDATA = 32'd0;
  end
end
endmodule

