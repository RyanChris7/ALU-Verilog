module alu(instCode, reg_a, reg_b, flag, res);

    input[31:0] instCode, reg_a, reg_b;
    reg[5:0] opcode, func;  
    reg[31:0] finResult, zero_extend, sign_extend, RS, RT; 
    reg[2:0] finFlags;  

    output signed [31:0] res;
    output[2:0] flag;

    always @(instCode, reg_a, reg_b) begin

        opcode = instCode[31:26];
        func = instCode[5:0];

        if (instCode[25:21] == 5'b00000) RS = reg_a;
        else if (instCode[25:21] == 5'b00001) RS = reg_b;
        else RS = 0;

        if(instCode[20:16] == 5'b00000) RT = reg_a;
        else if (instCode[20:16] == 5'b00001) RT = reg_b;
        else RT = 0;
        
        // R-type instruction
        if(opcode == 6'b000000) begin
            case(func)

            6'b100000: begin // Add instruction
                finResult = RS + RT;
                            
                if (finResult[30:0] == 0) begin
                    finFlags[0] = 1'b1;
                end

                if (finResult[31] == 0) begin
                    if ($signed(RS[31]) == 1 & $signed(RT[31]) == 1) begin
                        finFlags[2] = 1'b1;
                    end
                end
                else if (finResult[31] == 1) begin
                    if ($signed(RS[31]) == 0 & $signed(RT[31]) == 0) begin
                        finFlags[2] = 1'b1;
                    end
                end
                            
                if(finResult[31] == 1) finFlags[1] = 1;
                else finFlags[1] = 0;
            end

            6'b100010: begin  // Sub instruction
                finResult = RS - RT;   
                        
                if (finResult[30:0] == 0 )begin
                    finFlags[0] = 1'b1;
                end
                        
                if($signed(RS[31]) == 0 & $signed(RT[31]) == 0) begin
                    if(finResult[31] == 0) finFlags[0] = 1'b1;
                    else if (RT < RS) finFlags[1] = 1'b1;
                end

                else if($signed(RS[31]) == 1 & $signed(RT[31]) == 1) begin
                    if(finResult[31] == 0) finFlags[0] = 1'b1;
                    else if (RT > RS) finFlags[1] = 1'b1;
                end

                else if($signed(RS[31]) == 1 & $signed(RT[31]) == 0) begin
                    finFlags[1] = 1'b1;
                    if (finResult[31] == 0) finFlags[2] = 1'b1;  
                end

                else begin
                    if (finResult[31] == 1) finFlags[2] = 1'b1;  
                end
            end

            6'b100001: 
                finResult = RS + RT;       //Addu instruction

            6'b100011: 
                finResult = RS - RT;                //Subu instruction

            6'b000000: 
                finResult = RT << instCode[10:6];    //Sll instruction

            6'b000100: 
                finResult = RT << RS;               //Sllv instruction

            6'b000010: 
                finResult = RT >> instCode[10:6];    //Srl instruction

            6'b000110: 
                finResult = RT >> RS;               //Srlv instruction

            6'b000011: 
                finResult = RT >>> instCode[10:6];   //Sra instruction

            6'b000111: 
                finResult = RT >>> RS;              //Srav instruction

            6'b100100: 
                finResult = RS & RT;                //And instruction

            6'b100111: 
                finResult = ~(RS | RT);             //Nor instruction

            6'b100101: 
                finResult = RS | RT;                //Or instruction

            6'b100110: 
                finResult = RS ^ RT;                //Xor instruction

            6'b101011: begin                               //Sltu instruction          
                if(RS < RT) begin
                    finResult = 1;
                    finFlags[1] = 1'b1;
                end
                else finResult = 0;
            end

            6'b101010: begin                               //Slt instruction
                if($signed(RS) < $signed(RT)) begin
                    finResult = 1;
                    finFlags[1] = 1'b1;
                end
                else finResult = 0;
            end
            endcase
        end
         
        else // I instruction
        begin
            
            sign_extend = {{16{instCode[15]}}, instCode[15:0]};
		    zero_extend = {{16{1'b0}}, instCode[15:0]};

            case(opcode)

            6'b001000: begin //Addi instruction
                finResult = RS + sign_extend;

                if (finResult[30:0] == 0) begin
                    finFlags[0] = 1'b1;
                end

                if (finResult[31] == 0) begin
                    if ($signed(RS[31]) == 1 & $signed(RT[31]) == 1) begin
                         finFlags[2] = 1'b1;
                    end
                end
                else if (finResult[31] == 1) begin
                    if ($signed(RS[31]) == 0 & $signed(RT[31]) == 0) begin
                        finFlags[2] = 1'b1;
                    end
                end
                            
                if(finResult[31] == 1) finFlags[1] = 1;
                else finFlags[1] = 0;   
                
            end
            6'b001100: 
                finResult = RS & zero_extend; //Andi instruction
            
            6'b001001: 
                finResult = RS + sign_extend; //Addiu instruction

            6'b001101: 
                finResult = RS | zero_extend; //Ori instruction

            6'b001110: 
                finResult = RS ^ zero_extend; //Xori instruction

            6'b000100: begin //Beq instruction
                if($signed(RS) == $signed(RT)) finResult = instCode[15:0];
                else begin
                    finResult = 0;
                    finFlags[0] = 1'b1;
                end
            end

            6'b000101: begin //Bne instruction
                if($signed(RS) == $signed(RT)) begin
                    finResult = 0;
                    finFlags[0] = 1'b1;   
                end
                else finResult = instCode[15:0];
            end

            6'b001010: begin //Slti instruction
                if($signed(RS) < $signed(sign_extend)) begin
                    finResult = 1;
                    finFlags[1] = 1'b1;
                end
                else finResult = 0;
            end

            6'b001011: begin //Sltiu instruction
                if(RS < sign_extend) begin
                    finResult = 1;
                    finFlags[0] = 1'b1;
                end
                else finResult = 0;
            end

            6'b100011: 
                finResult = $signed(RT) + $signed(sign_extend); //Lw instruction

            6'b101011: 
                finResult = $signed(RT) + $signed(sign_extend); //Sw instruction

            endcase
        end
    end

    assign res = finResult;
    assign flag = finFlags;

endmodule