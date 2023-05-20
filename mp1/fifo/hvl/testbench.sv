`ifndef testbench
`define testbench


module testbench(fifo_itf itf);
import fifo_types::*;

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

task enqueue_word();
    itf.valid_i<= 1'b1; //start enqueue
    for (int i=0; i<=cap_p-1; ++i)begin
        itf.data_i <=i;
        @(tb_clk);
    end
    itf.valid_i <= 1'b0; //end enqueue
endtask: enqueue_word

task dequeue_word();
    itf.yumi <= 1'b1; //start dequeue
    for (int j=0; j<=cap_p-1; ++j)begin
        assert (itf.data_o ==j) //check the result according to FIFO rule
        else begin
            $error ("%0d: %0t: %s error detected", `__LINE__, $time, "RESET_DOES_NOT_CAUSE_READY_O");
            report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end      
        @(tb_clk);
    end
    itf.yumi <= 1'b0; //end dequeue

endtask: dequeue_word

task simultaneously();
    for (int k=0; k<=cap_p-1; ++k)begin
        itf.data_i <= k; 
		itf.valid_i <= 1'b1; //start enqueue
        @(tb_clk); //wait for a cycle

        itf.yumi <= 1'b1; //start dequeue
        @(tb_clk); 
        
        itf.yumi <= 1'b0;
        itf.valid_i <= 1'b0;
        end
endtask :simultaneously

task check_reset();
    @(tb_clk);
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
    assert (itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: %s error detected", `__LINE__, $time, "RESET_DOES_NOT_CAUSE_READY_O");
        report_error (RESET_DOES_NOT_CAUSE_READY_O);
    end  
endtask: check_reset

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.

    enqueue_word();
    dequeue_word();
    simultaneously();
    check_reset();

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

