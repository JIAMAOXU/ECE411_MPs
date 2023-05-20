module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);
logic resp_o;
logic read_i; 
logic read_o;
logic write_i;
logic mem_resp;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
logic [31:0] mem_wdata;
logic [31:0] mem_rdata;
logic [31:0] mem_address;
logic [31:0] address_i;
logic [255:0] line_i, line_o;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(
    .clk(clk), 
    .rst(rst),
    .mem_resp(mem_resp),
    .mem_rdata(mem_rdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_address(mem_address),
    .mem_wdata(mem_wdata)    
);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk(clk),
    .rst(rst),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_resp(mem_resp),
    .mem_address(mem_address),
    .mem_byte_enable(mem_byte_enable),
    
    .pmem_rdata(line_o),
    .pmem_wdata(line_i),
    .pmem_read(read_i), 
    .pmem_write(write_i),
    .pmem_address(address_i),
    .pmem_resp(resp_o)    
);

cacheline_adaptor cacheline_adaptor(
    .clk(clk), 
    .reset_n(~rst),
    //cacheline adaptor-->cache
    .line_i(line_i), 
    .line_o(line_o),
    .read_i(read_i), 
    .write_i(write_i),
    .address_i(address_i), 
    .resp_o(resp_o),
    //mem-->cacheline adaotir
    .burst_i(pmem_rdata), 
    .burst_o(pmem_wdata), 
    .read_o(pmem_read), 
    .write_o(pmem_write),
    .address_o(pmem_address), 
    .resp_i(pmem_resp)
);
// Hint: What do you need to interface between cache and main memory?

endmodule : mp3