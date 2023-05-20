/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
input clk,
input rst, 
input logic hit_way0,
input logic hit_way1,
// CPU--CACHE
input logic mem_read,
input logic mem_write,
input logic [31:0]mem_byte_enable256,
output logic mem_resp, //tell cpu the cache finished
//CACHE--MEMORY
input logic pmem_resp, //from mem indicate that the mem finished
output logic pmem_write,
output logic pmem_read,
output logic pmem_addr,
//datapath signal
//valid
input logic dataout_valid0, dataout_valid1,
output logic load_valid0, load_valid1, 
output logic read_valid0, read_valid1, 
output logic datain_valid0, datain_valid1,

//dirty
input logic dataout_dirty0, dataout_dirty1,
output logic load_dirty0, load_dirty1, 
output logic read_dirty0, read_dirty1,
output logic datain_dirty0, datain_dirty1,
//tag
output logic load_tag0, load_tag1, 
output logic read_tag0, read_tag1,
//LRU
input logic dataout_lru,
output logic read_lru,
output logic load_lru, 
output logic datain_lru, 
//data
output logic load_data0, load_data1, 
output logic [31:0]data0_mem_byte_enable, 
output logic [31:0]data1_mem_byte_enable,
output logic allocate_way0,
output logic allocate_way1
);


enum int unsigned {
    start, hit, write, read, finish
}state, next_state;

function void set_default();
    load_valid0 = 1'b0;
    load_valid1 = 1'b0;
    load_dirty0 = 1'b0;
    load_dirty1 = 1'b0;
    load_tag0 = 1'b0;
    load_tag1 = 1'b0;
    load_lru = 1'b0;
    read_valid0 = 1'b1;
    read_valid1 = 1'b1;
    read_dirty0 = 1'b1;
    read_dirty1 = 1'b1;
    read_tag0 = 1'b1;
    read_tag1 = 1'b1;
    read_lru = 1'b1;
    datain_valid0 = dataout_valid0;
    datain_valid1 = dataout_valid1;
    datain_dirty0 = 1'b0;
    datain_dirty1 = 1'b0;
    datain_lru= dataout_lru;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    mem_resp=1'b0;
    data0_mem_byte_enable = {32{1'b0}};
    data1_mem_byte_enable = {32{1'b0}};
    allocate_way0 = 1'b0;
    allocate_way1 = 1'b0;

endfunction

always_comb begin : state_actions
    set_default();
    case (state)
        //first state
        start: begin 
            //read_lru = 1'b0;
            // load_lru = 1'b0;
            // datain_lru= dataout_lru;
        end 
            
        
        //second state
        hit: begin 
            if(mem_write==1'b1)begin 
                if(hit_way0 ==1'b1)begin 
                    data0_mem_byte_enable = mem_byte_enable256;
                    datain_dirty0 = 1'b1;
                    load_data0 = 1'b1;
                    mem_resp=1'b1;
                    datain_lru = ~(dataout_lru);
                    load_lru=1'b1;
                    //mem_rdata256 = dataout_data0;
                end
            end
            else if (mem_write ==1'b1)begin 
                if(hit_way1==1'b1)begin 
                    data1_mem_byte_enable = mem_byte_enable256;
                    datain_dirty1 = 1'b1;
                    load_data1 = 1'b1;
                    mem_resp=1'b1;
                    datain_lru = ~(dataout_lru);
                    load_lru=1'b1;
                    //mem_rdata256 = dataout_data1;
                end
            end
            else if (hit_way0==1'b1)begin 
                mem_resp=1'b1;
                if(dataout_lru==1'b0)begin
                    datain_lru = ~(dataout_lru);
                    load_lru=1'b1;
                end
                else begin 
                    load_lru = 1'b0;
                end
            end

            else if (hit_way1==1'b1)begin 
                mem_resp=1'b1;
                if(dataout_lru==1'b1)begin
                    datain_lru = ~(dataout_lru);
                    load_lru=1'b1;
                end
                else begin 
                    load_lru = 1'b0;
                end
            end
            else begin 
                datain_lru= dataout_lru;
                //read_lru=1'b0;
            end
        end

        //third state
        write: begin 
            pmem_write = 1'b1;
            pmem_addr = 1'b1;
        end

        //fourth state: write allocate
        read: begin 
            if (dataout_lru ==1'b0)begin 
                pmem_read = 1'b1;
                pmem_addr = 1'b0;
                data0_mem_byte_enable = {32{1'b1}};
                allocate_way0 = 1'b1;
                allocate_way1 = 1'b0;
                load_tag0 = 1'b1;
                datain_valid0 = 1'b1;
                datain_dirty0 = 1'b0;
                load_dirty0 = 1'b1;
                load_valid0 = 1'b1;
                load_data0 = 1'b1;
                //read_lru=1'b0;
            end
            else if (dataout_lru == 1'b1) begin 
                pmem_read = 1'b1;
                pmem_addr= 1'b0;
                data1_mem_byte_enable = {32{1'b1}};
                allocate_way1 = 1'b1;
                allocate_way0 = 1'b0;
                load_tag1 = 1'b1;
                datain_valid1 = 1'b1;
                datain_dirty1 = 1'b0;
                load_dirty1 = 1'b1;
                load_valid1 = 1'b1;
                load_data1 = 1'b1;
                //read_lru=1'b0;
            end

            end


        //last state 
        finish: begin 
            //read_lru=1'b1;
            if (mem_write)begin 
            case(dataout_lru)
                    1'b0: begin
                        mem_resp = 1'b1;
                        datain_lru = ~(dataout_lru);
                        load_lru = 1'b1;
                        load_dirty0 = 1'b1;
                        datain_dirty0 = 1'b1;
                        data0_mem_byte_enable = mem_byte_enable256;
                    end
                    1'b1:begin 
                        mem_resp = 1'b1;
                        datain_lru = ~(dataout_lru);
                        load_lru = 1'b1;
                        load_dirty1 = 1'b1;
                        datain_dirty1 = 1'b1;
                        data1_mem_byte_enable = mem_byte_enable256;
                    end
                endcase
            end
            else begin 
                mem_resp = 1'b1;
                datain_lru = ~(dataout_lru);
                load_lru = 1'b1;
            end
        end
    default:set_default();
    endcase
end

always_comb begin: next_state_logic
    if(rst)begin 
        next_state = start;
    end

    else begin 
        case(state)
            start:begin 
                if (mem_read || mem_write) begin 
                    next_state = hit;
                end
                else begin 
                    next_state = start;
                end
            end
            hit: begin 
                if (hit_way0 || hit_way1) begin 
                    next_state = start;
                end 
                else if (dataout_lru == 1'b0)begin
                        if(dataout_dirty0 == 1'b1)begin 
                            next_state = write;
                        end 
                        else begin 
                            next_state = read;
                        end
                    end
                else if (dataout_lru == 1'b1) begin 
                        if (dataout_dirty1 == 1'b1)begin 
                            next_state = write;
                        end
                        else begin 
                            next_state = read;
                        end
                    end
                
                else begin 
                    next_state = read;
                end
            end

            write: begin 
                if(pmem_resp) begin 
                    next_state = read;
                end
                else begin 
                    next_state = write; //self loop in current state until receive respond from main memory
                end
            end

            read: begin 
                if(pmem_resp) begin 
                    next_state = finish;
                end
                else begin 
                    next_state = read; //self loop in current state until receive respond from main memory
                end
            end

            finish: begin next_state = start; end
            default: next_state = start;
           
        endcase
    end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : cache_control
