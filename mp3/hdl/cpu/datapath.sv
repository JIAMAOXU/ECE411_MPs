module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    /* You will need to connect more signals to your datapath module*/
    
    //--------control to datapath---------//
    //load
    input logic load_pc,
    input logic load_ir,
    input logic load_regfile,
    input logic load_mar,
    input logic load_mdr,
    input logic load_data_out,
    // Muxes
    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    //opcode
    input alu_ops aluop,
    input branch_funct3_t cmpop,

    //--------Memory to datapath--------//
    input rv32i_word mem_rdata,

    //--------Datapath to control--------//
    output rv32i_opcode opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic br_en,
    output logic [4:0] rs1,
    output logic [4:0] rs2,

    //--------Datapath to memory--------//
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
    output logic [1:0] shift
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word marmux_out;
rv32i_word cmpmux_out;
rv32i_word mdrreg_out;
rv32i_word regfilemux_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;
rv32i_reg rd;
rv32i_word alu_mux_1_out;
rv32i_word alu_mux_2_out;
rv32i_word alu_out;
rv32i_word mem_wdata_temp;
rv32i_word mar_out;
assign shift = mar_out[1:0];
assign mem_address = {mar_out[31:2], 2'b0};
/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk (clk),
    .rst (rst),
    .load (load_ir),
    .in (mdrreg_out),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk  (clk),
    .rst (rst),
    .load (load_mar),
    .in   (marmux_out),
    .out  (mar_out) //question here
);

register mem_data_out(
    .clk (clk),
    .rst (rst),
    .load (load_data_out),
    .in (rs2_out),
    .out (mem_wdata_temp) //question here
);

regfile regfile(
    .clk (clk),
    .rst (rst),
    .load (load_regfile),
    .in (regfilemux_out),
    .src_a (rs1),
    .src_b (rs2),
    .dest (rd),
    .reg_a (rs1_out),
    .reg_b (rs2_out)
);
pc_register PC(
    .clk (clk),
    .rst (rst),
    .load (load_pc),
    .in (pcmux_out),
    .out (pc_out) //question here
);
/*****************************************************************************/

/******************************* ALU and CMP *********************************/
/*****************************************************************************/
alu ALU (
	.aluop (aluop),
	.a (alu_mux_1_out),
	.b (alu_mux_2_out),
	.f (alu_out)
);

branch CMP(
    .s1(rs1_out),
    .s2(cmpmux_out),
    .cmpop(cmpop),
    .br_en(br_en)
);

    always_comb begin
            case(opcode)
                op_store:
                    case(store_funct3_t'(funct3))
                        sh: mem_wdata = mem_wdata_temp << (shift * 8);
                        sb: mem_wdata = mem_wdata_temp << (shift * 8);
                        default: mem_wdata = mem_wdata_temp;
                    endcase
            default: mem_wdata = mem_wdata_temp;
        endcase
    end
/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:2], 2'b0};
        
    endcase

    unique case(marmux_sel)
        marmux::pc_out: marmux_out = pc_out;
        marmux::alu_out: marmux_out = alu_out;
        //default: ;
    endcase

    unique case(cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = rs2_out;
        cmpmux::i_imm: cmpmux_out = i_imm;
        //default: ;
    endcase

    unique case(alumux1_sel)
        alumux::rs1_out: alu_mux_1_out = rs1_out;
        alumux::pc_out: alu_mux_1_out = pc_out;
        default: ;
    endcase

    unique case(alumux2_sel)
        alumux::i_imm: alu_mux_2_out = i_imm;
        alumux::u_imm: alu_mux_2_out = u_imm;
        alumux::b_imm: alu_mux_2_out = b_imm;
        alumux::s_imm: alu_mux_2_out = s_imm;
        alumux::j_imm: alu_mux_2_out = j_imm; 
        alumux::rs2_out: alu_mux_2_out = rs2_out;
        //default: ;
    endcase

    unique case(regfilemux_sel) 
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::lw: regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        
        regfilemux::lh:
            case(shift)
                2'b00: begin
                    regfilemux_out = 32'($signed(mdrreg_out[15:0]));
                end
                2'b10: begin
                    regfilemux_out = 32'($signed(mdrreg_out[31:16]));
                end
                default: regfilemux_out = mdrreg_out;
            endcase 

        regfilemux::lhu: 
             case(shift)
                2'b00: begin
                    regfilemux_out = 32'(mdrreg_out[15:0]);
                end
                2'b10: begin
                    regfilemux_out = 32'(mdrreg_out[31:16]);
                end
                default: regfilemux_out = mdrreg_out;
            endcase  
        regfilemux::lb: 
             case(shift)
                2'b00: begin
                    regfilemux_out = 32'($signed(mdrreg_out[7:0]));
                end
                2'b01: begin
                    regfilemux_out = 32'($signed(mdrreg_out[15:8]));
                end
                2'b10: begin
                    regfilemux_out = 32'($signed(mdrreg_out[23:16]));
                end
                2'b11: begin 
                    regfilemux_out = 32'($signed(mdrreg_out[31:24]));
                end
            endcase 
        regfilemux::lbu:             
             case(shift)
                2'b00: begin 
                    regfilemux_out = 32'(mdrreg_out[7:0]);
                end
                2'b01: begin 
                    regfilemux_out = 32'(mdrreg_out[15:8]);
                end
                2'b10: begin 
                    regfilemux_out = 32'(mdrreg_out[23:16]);
                end
                2'b11: begin 
                    regfilemux_out = 32'(mdrreg_out[31:24]);
                end
            endcase 




    endcase
end
/*****************************************************************************/
endmodule : datapath

module branch

import rv32i_types::*;
(
    input rv32i_word s1,
    input rv32i_word s2,
    input branch_funct3_t cmpop,
    output logic br_en
);
always_comb begin
    unique case (cmpop)
        beq:br_en = (s1 == s2);
        bne:br_en = (s1 != s2);
        blt:br_en = ($signed(s1) < $signed(s2));
        bge:br_en = ($signed(s1) >= $signed(s2));
        bltu:br_en = ($unsigned(s1) < $unsigned(s2));
        bgeu:br_en = ($unsigned(s1) >= $unsigned(s2));
        default: br_en=1'b0;
    endcase
end

endmodule: branch