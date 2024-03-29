
`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

task check_multiply();
    //generate multiplicand
    for (int unsigned i =0; i<= 8'b11111111; ++i)begin
        for(int unsigned j = 0; j<=8'b11111111; ++j) begin
            @(tb_clk);
            itf.multiplicand<=i;
            itf.multiplier<=j;
    itf.start <=1'b1; //start multiplier

    @(posedge itf.done);

    assert(itf.product == i*j)    //check if the product is correct
    else begin     //if bad product, report error
        $error("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
        report_error(BAD_PRODUCT);
    end

    itf.start <= 1'b0;

        end
    end 

    // assert(itf.rdy == 1'b1)    //check if the product is correct
    // else begin     //if bad product, report error
    //     $error("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
    //     report_error(NOT_READY);
    // end
endtask : check_multiply

// task check_start();
//     itf.start <=1'b1; //start multiplier
//     @(tb_clk);
//     itf.start <=1'b0; //start multiplier
//     @(tb_clk iff (itf.mult_op == ADD)) //wait for first posedge
    
//     itf.start <=1'b1; //start multiplier
//     @(tb_clk);
//     itf.start <=1'b0; //start multiplier
//     @(tb_clk iff (itf.mult_op == SHIFT)) //wait for first posedge
//     itf.start <=1'b1; //start multiplier

//     @(tb_clk);
//     itf.start <= 1'b0;
// endtask :check_start

task check_reset();
    itf.multiplier <= 8'b10101010;
    itf.multiplicand <= 8'b10101010;
    @(tb_clk);
    itf.start <=1'b1; //start multiplier
    @(tb_clk);
    itf.start <= 1'b0;
    @(tb_clk iff (itf.mult_op == SHIFT)) //wait for first posedge
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    @(tb_clk);
    itf.start <=1'b1;
    @(tb_clk iff (itf.mult_op == ADD)) //wait for first posedge
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask :check_reset


// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error



initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    check_multiply();
    //check_start();
    check_reset();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
