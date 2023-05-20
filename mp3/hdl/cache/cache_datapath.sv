/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index

)

(

    input clk,
    input rst, 

    //CPU --> Cache
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata256,
    input logic allocate_way0,
    input logic allocate_way1,
    //cache --> CPU
    output logic [255:0] mem_rdata256,

    //memory --> cache
    input logic [255:0] pmem_rdata,
    //cache --> memory
    input logic pmem_addr,
    output logic [31:0] pmem_address,
    output logic [255:0] pmem_wdata,

    //control to datapath
    //hit array
    output logic hit_way0, hit_way1,
    //Valid array
    input logic load_valid0, load_valid1, 
    input logic read_valid0, read_valid1, 
    input logic datain_valid0, datain_valid1,
    output logic dataout_valid0, dataout_valid1,

    //Dirty array
    input logic load_dirty0, load_dirty1, 
    input logic read_dirty0, read_dirty1,
    input logic datain_dirty0, datain_dirty1,
    output logic dataout_dirty0, dataout_dirty1, 

    //Tag array
    input logic load_tag0, load_tag1, 
    input logic read_tag0, read_tag1, 
   

    //LRU array
    input logic load_lru,
    input logic read_lru, 
    input logic datain_lru,
    output logic dataout_lru, 

    //Data array
    input logic load_data0, load_data1, 
    input logic [31:0]data0_mem_byte_enable, 
    input logic [31:0]data1_mem_byte_enable


);
/*****************************************************************************/
logic [23:0]dataout_tag0;
logic [23:0]dataout_tag1;
logic [255:0]datain_data0;
logic [255:0]datain_data1;
logic [255:0]dataout_data0;
logic [255:0]dataout_data1;
/***************************** Valid Array *************************************/

array valid0(
    .clk(clk),
    .rst(rst),
    .read(read_valid0),
    .load(load_valid0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_valid0),
    .dataout(dataout_valid0)
);

array valid1(
    .clk(clk),
    .rst(rst),
    .read(read_valid1),
    .load(load_valid1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_valid1),
    .dataout(dataout_valid1)
);

/***************************** Dirty Array *************************************/
array dirty0(
    .clk(clk),
    .rst(rst),
    .read(read_dirty0),
    .load(load_dirty0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_dirty0),
    .dataout(dataout_dirty0)
);

array dirty1(
    .clk(clk),
    .rst(rst),
    .read(read_dirty1),
    .load(load_dirty1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_dirty1),
    .dataout(dataout_dirty1)
);

/***************************** Tag Array *************************************/
array #(.width(s_tag))tag0(
    .clk(clk),
    .rst(rst),
    .read(read_tag0),
    .load(load_tag0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(dataout_tag0)
);

array #(.width(s_tag))tag1(
    .clk(clk),
    .rst(rst),
    .read(read_tag1),
    .load(load_tag1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(dataout_tag1)
);

/***************************** LRU Array *************************************/
array LRU(
    .clk(clk),
    .rst(rst),
    .read(read_lru),
    .load(load_lru),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_lru),
    .dataout(dataout_lru)
);

/***************************** Data Array *************************************/
data_array data0(
    .clk(clk),
    .read(load_data0),
    .write_en(data0_mem_byte_enable),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_data0),
    .dataout(dataout_data0)
);

data_array data1(
    .clk(clk),
    .read(load_data1),
    .write_en(data1_mem_byte_enable),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(datain_data1),
    .dataout(dataout_data1)
);


/*****************************************************************************/
assign hit_way0 = ((dataout_tag0 == mem_address[31:8]) && dataout_valid0);
assign hit_way1 = ((dataout_tag1 == mem_address[31:8]) && dataout_valid1);
/***************************** Supporting logic*************************************/
always_comb begin: supporting_logic

    //select dataout according to LRU bit
    if (dataout_lru == 1'b0)begin 
        pmem_wdata = dataout_data0; //to physical mem
        mem_rdata256 = dataout_data0; //to CPU
    end
    else if (dataout_lru == 1'b1) begin 
        pmem_wdata = dataout_data1; //to physical mem
        mem_rdata256 = dataout_data1; //to CPU
    end
    

    //Hit action
    if (hit_way0) begin 
        mem_rdata256 = dataout_data0; //data to CPU
    end
    else if (hit_way1) begin 
        mem_rdata256 = dataout_data1; //data to CPU
    end

    //Write allocate action
    if (allocate_way0 == 1'b1)begin 
        datain_data0 = pmem_rdata;
    end
    else if (allocate_way1 == 1'b1)begin 
        datain_data1 = pmem_rdata;
    end
    else begin 
        datain_data0 = mem_wdata256;
        datain_data1 = mem_wdata256;
    end

    //write back action
    if (pmem_addr == 1'b1) begin 
        if(dataout_lru == 1'b0)begin 
            pmem_address = {dataout_tag0, mem_address[7:5], 5'b00000};
        end
        else if (dataout_lru == 1'b1)begin 
            pmem_address = {dataout_tag1, mem_address[7:5], 5'b00000};
        end
    end
    else begin 
        pmem_address = {mem_address[31:5], 5'b00000};
    end
end:supporting_logic

endmodule : cache_datapath
