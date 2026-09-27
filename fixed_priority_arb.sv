// Code your design here
interface intf(input wire clk);
  logic       rst;
  logic [3:0] req;
  logic [3:0] gnt;

  
endinterface

//DUT

module fixed_priority_arb(input wire clk,
                          input wire rst,
                          input wire [3:0]req,
                          output reg [3:0]gnt);
  always @(posedge clk)
    begin //{
      if(rst)
        gnt<=4'b0;
      else
        begin//{
        gnt<=4'b0;
          for(int i=0;i<4;i++)  //Fixed priority for req[0]
          begin //{
            if(req[i])
              begin//{
                gnt[i]<=1'b1;
                break;
              end//}
          end //}
        end//}
    end //}
  
endmodule

//Assertion Module
module assertion_chk(
  input wire       clk,
  input wire       rst,
  input wire [3:0] req,
  input [3:0] gnt
);

  property one_hot;
    @(posedge clk) disable iff (rst) $rose(req) |=>$onehot(gnt);
  endproperty
  
  // for every req, gnt must occur
  property req_ack;
    @(posedge clk) disable iff (rst) $rose(req) |-> ##[0:$]gnt;
  endproperty

  assert property(one_hot)
    else `uvm_error("ASSERTION_FAIL", "Grant is not one-hot");
    
  assert property(req_ack)
    else `uvm_error("ASSERTION_FAIL", "Grant is not one-hot");
    
endmodule
