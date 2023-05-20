module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);


enum{Q1, Q2, Q3, Q4, Q5} state;
logic write_flag,read_flag;
//logic [255:0]read_buf;
logic [255:0]write_buff;
always_ff @( posedge clk) begin 
    //---------------------------------------------------------load case mem->LLC--------------------------------------------------//
    if(read_i == 1'b1)begin
        read_flag <= 1'b1; //set up reading flag
        read_o <= 1'b1;    //start reading
        write_o <= 1'b0;
        address_o <= address_i; //load addr
        state <= Q1;
        
    end

    if(read_flag)begin
        case (state)
            Q1: begin 
                if(resp_i)begin //read data only when receive resp signal
                    line_o[63:0] <= burst_i;
                    state <= Q2;
                end
            end

            Q2: begin 
                if(resp_i)begin //read data only when receive resp signal
                    line_o[127:64] <= burst_i;
                    state <= Q3;
                end
            end

            Q3: begin 
                if(resp_i)begin //read data only when receive resp signal
                    line_o[191:128] <= burst_i;
                    state <= Q4;
                end
            end

            Q4: begin 
                if(resp_i)begin //read data only when receive resp signal
                    line_o[255:192] <= burst_i;
                    //line_o[255:0] <= read_buf[255:0];
                    resp_o <= 1'b1; 
                    state <= Q5;
                end
            end

            Q5: begin
                read_o <= 1'b0;
                resp_o <= 1'b0;
                read_flag <= 1'b0;
                state <= Q5;
            end


    endcase  
    end
    //-------------------------------------------------------store case LLC -> mem-----------------------------------------------//
    if(write_i==1'b1)begin
        write_flag <= 1'b1;
        read_o <= 1'b0;
        write_o <= 1'b1;
        address_o <= address_i;
        //resp_o <= 1'b1;
        burst_o<= line_i[63:0]; //shift write cycle forward due to timing problem
        state <= Q1;
    end

    //start writing
    if(write_flag)begin
        case (state)
            Q1: begin 
                
                if(resp_i)begin //write data only when receive resp signal
                    //write_buff[63:0] <= line_i[63:0];
                    burst_o<=line_i[127:64];
                    state <= Q2;
                end
            end
            Q2: begin 
                if(resp_i)begin//write data only when receive resp signal
                    //write_buff[191:128] <= line_i[191:128];
                    burst_o<= line_i[191:128];
                    state <= Q3;
                end
            end

            Q3: begin 
                if(resp_i)begin //write data only when receive resp signal
                    //write_buff[191:128] <= line_i[191:128];
                    burst_o<= line_i[255:192];
                    state <= Q4;
                end
            end

            // Q4: begin 
            //     if(resp_i == 1'b1)begin
            //         //write_buff [255:192]<= line_i[255:192];
                    
            //         //resp_o <= 1'b1; 
            //         // burst_o<= write_buff[63:0];
            //         // burst_o<= write_buff[127:64];
            //         // burst_o<= write_buff[191:128];
            //         // burst_o<= write_buff[255:192];
            //         state <= Q5;
            //     end
            // end
            
            Q4: begin
                resp_o <= 1'b1; 
                state <= Q5;
            end

            Q5: begin
                write_o <= 1'b0;
                resp_o <= 1'b0;
                write_flag <= 1'b0;
                state <= Q5;
            end
    endcase   
    end

    else if(reset_n <= 1'b0)begin  //reset all signal to defaut
        read_o <= 1'b0;
        write_o <= 1'b0;
        state <= Q1;
        write_flag <= 1'b0;
        read_flag <= 1'b0;
    end
end


endmodule : cacheline_adaptor
