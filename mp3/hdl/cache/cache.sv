/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
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

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic load_dirty0, load_dirty1;
logic read_dirty0, read_dirty1;
logic load_tag0, load_tag1;
logic read_tag0, read_tag1;
logic load_valid0, load_valid1;
logic read_valid0, read_valid1;
logic load_data0, load_data1;
logic load_lru;
logic read_lru;
logic datain_valid0, datain_valid1;
logic dataout_valid0, dataout_valid1;
logic datain_dirty0, datain_dirty1;
logic dataout_dirty0, dataout_dirty1;
logic dataout_tag0, dataout_tag1;
logic datain_data0,datain_data1;
logic datain_lru;
logic dataout_lru;
logic [255:0] mem_rdata256, mem_wdata256;
logic [31:0] mem_byte_enable256;
logic [31:0]data0_mem_byte_enable, data1_mem_byte_enable;
logic hit_way0, hit_way1;
logic allocate_way0, allocate_way1;
logic pmem_addr;
cache_control control
(.*
);

cache_datapath datapath
(.*
);

bus_adapter bus_adapter
(.*,
.address(mem_address)
);


endmodule : cache
