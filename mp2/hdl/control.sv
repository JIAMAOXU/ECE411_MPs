
module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp,
    input logic [1:0]shift,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,
    output logic mem_read,
    output logic mem_write,
    output logic[3:0]mem_byte_enable,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0]rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = '0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << (shift)/* Modify for MP1 Final */ ;
                lb, lbu: rmask = 4'b0001 << (shift)/* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << (shift)/* Modify for MP1 Final */ ;
                sb: wmask = 4'b0001 << (shift)/* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        default: trap = '1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1, fetch2, fetch3, decode, imm, lui, calc_addr, auipc, br, ld1, ld2, st1, st2, register_op,jal,jalr
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    cmpop = branch_funct3_t'(funct3);
    pcmux_sel = pcmux::pc_plus4;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = alu_add;
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b1111;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    load_regfile=1'b1;
    regfilemux_sel = sel; //select reg file mux according to input
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = 1'b1;
    marmux_sel = sel;    //select mar mux according to input
endfunction

function void loadMDR();
    load_mdr = 1'b1;
    mem_read = 1'b1;
endfunction
                                                                     
function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop , alu_ops op);
    /* Student code here */
    alumux1_sel = sel1;
    alumux2_sel = sel2;
    if (setop)
        aluop = op; // else default value

endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel=sel;
    cmpop = op;
endfunction

/*****************************************************************************/
//-----------------------------------STATE ACTION-------------------------------//
always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case(state)
        fetch1: begin
            loadMAR(marmux::pc_out);
        end

        fetch2: begin
            loadMDR();
        end

        fetch3: begin
            load_ir = 1'b1;
        end

        decode: begin

        end

        imm: begin 
            case(arith_funct3)
                slt:begin  //Sets destination reg to 1 if the first reg's val less than second reg's val. Otherwise, set to 0.
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::i_imm, blt);
                end

                sltu:begin //used with unsaigned integers
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::i_imm, bltu);
                end
                sr:begin //read value from reg and subtract from the argument
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);    
                    //SRAI case               
                    if (funct7[5] == 1'b1) begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra) ;
                    end
                    //SRLI case
                    else begin
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl) ;
                    end
                end   

                default:begin  
                        loadRegfile(regfilemux::alu_out);
                        loadPC(pcmux::pc_plus4); 
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3) );
                    end
            endcase
        end
            
        lui:begin
            loadRegfile(regfilemux::u_imm);
            loadPC(pcmux::pc_plus4);
        end

        calc_addr:begin 
            case(opcode)//opcode to determine load or store
                op_load:begin //LW instruction
                    loadMAR(marmux::alu_out);
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                end
                op_store:begin
                    loadMAR(marmux::alu_out);
                    setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
                    load_data_out = 1'b1;
                end
            endcase
        end

        auipc:begin 
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
        end

        br:begin 
            loadPC(pcmux::pcmux_sel_t'(br_en));
            setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
            setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3));
        end

        ld1:begin 
            loadMDR();
            mem_read = 1'b1;
        end

        ld2:begin 
            loadPC(pcmux::pc_plus4);
			case(load_funct3)
            	lw: loadRegfile(regfilemux::lw);
				lb: loadRegfile(regfilemux::lb);
                lbu: loadRegfile(regfilemux::lbu);
				lh: loadRegfile(regfilemux::lh);
				lhu: loadRegfile(regfilemux::lhu);
			endcase            
        end

        st1:begin 
            mem_write = 1'b1;
            case (store_funct3_t'(funct3))
                sw: mem_byte_enable = 4'b1111;
                sh: mem_byte_enable = 4'b0011 << shift;
                sb: mem_byte_enable = 4'b0001 << shift;
            endcase
            
        end

        st2:begin
            loadPC(pcmux::pc_plus4);
            //mem_byte_enable = 4'b1111;
        end
        jal: begin 
            loadRegfile(regfilemux::pc_plus4);
            loadPC(pcmux::alu_mod2);			
			setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
        end

        jalr: begin
			loadRegfile(regfilemux::pc_plus4);
            loadPC(pcmux::alu_mod2);
			setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
		end
        register_op: begin
            case(arith_funct3)
                slt: begin 
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::rs2_out,blt);
                end

                sltu: begin 
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::rs2_out,bltu);
                end
                
                sr: begin 
                    if(funct7[5] ==1'b1)begin
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                    end

                    else begin
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                    end
                end
                add: begin
                    if(funct7[5] == 1'b1)begin 
                        loadPC(pcmux::pc_plus4);
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                    end
                    else begin
                        loadPC(pcmux::pc_plus4);
                        loadRegfile(regfilemux::alu_out);
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
                    end
                end

                default: begin                 
                    loadPC(pcmux::pc_plus4);
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
                end
            endcase
        end
                jal: begin 
                    loadRegfile(regfilemux::pc_plus4);
                    loadPC(pcmux::alu_mod2);
                    setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
                end

                jalr:begin 
                    loadRegfile(regfilemux::pc_plus4);
                    loadPC(pcmux::alu_mod2);
                    setALU(alumux::pc_out, alumux::i_imm, 1'b1, alu_add);
                end
        default: set_defaults();
    endcase
end

//-----------------------------------STATE TRANSITION-------------------------------//
always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */

    if(rst) begin //if reset, go to state fetch 1
        next_states = fetch1; 
    end
    else begin
        case(state)
            fetch1: begin 
                next_states = fetch2;
            end

            fetch2:begin
                if(mem_resp == 1'b0) begin 
                    next_states = fetch2;
                end
                else begin 
                    next_states = fetch3;
                end
            end

            fetch3: begin 
                next_states = decode;
            end

            decode: begin 
                case(opcode)
                    op_lui: next_states = lui; 
                    op_auipc: next_states = auipc;
                    op_jal:next_states = jal; 
                    op_jalr:next_states = jalr;
                    op_br: next_states = br;
                    op_load: next_states = calc_addr;
                    op_store:   next_states = calc_addr;
                    op_imm: next_states = imm;
                    op_reg:next_states = register_op; 
                    default: next_states = fetch1;
                endcase
            end
            jal: next_states = fetch1;
            jalr: next_states = fetch1;
            auipc: next_states = fetch1;
            
            br: next_states = fetch1;

            imm: begin 
                next_states = fetch1;
            end

            lui: begin 
                next_states = fetch1;
            end

            calc_addr: begin
                case(opcode)
                    op_load: next_states = ld1;
                    op_store: next_states = st1;
                    default: next_states = fetch1;
                endcase
            end

            ld1: begin 
                if (mem_resp == 1'b0) begin 
                    next_states = ld1;
                end

                else begin 
                    next_states = ld2;
                end
            end

            ld2: begin 
                next_states = fetch1;
            end

            st1: begin 
                if (mem_resp == 1'b0) begin
                    next_states = st1;
                end
                else begin 
                    next_states = st2;
                end
            end

           st2: begin 
                next_states = fetch1;
           end 
        
        default: next_states = fetch1;
        endcase
    end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_states;
end

endmodule : control
