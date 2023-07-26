module iitb_risc(clk);
	input clk;
	reg [15:0] PC , IF_ID_IR , IF_ID_NPC;														//IF_ID
	reg [15:0] ID_RR_IR , ID_RR_NPC ;															//ID_RR
	reg [15:0] RR_EX_IR, RR_EX_NPC, RR_EX_A, RR_EX_B,RR_EX_Imm, RR_EX_Imm_9bits;  //RR_EX
	reg [15:0] EX_MEM_IR , EX_MEM_ALUout, EX_MEM_A ,EX_MEM_NPC ;		///				//EX_MEM
	reg cond, flush;																					// It will be useful in EX_MEM stage for conditional branching
	reg [15:0] MEM_WB_IR, MEM_WB_ALUout , MEM_WB_LMD, MEM_WB_NPC;						//MEM_WB
	reg [15:0] RF[7:0];      																		//register file 8x16
	reg [15:0] I_Mem [0:1023]; 																	// 1024 x 16 Instruction memory
	reg [15:0] D_Mem [0:1023];																		// 1024 x 16 Data Memory
	reg [1:0] CCR, EX_MEM_CCR, MEM_WB_CCR; 			 										// 1(carry) , 0(zero) Flag
	reg [15:0] EX_MEM_RF_LS [6:1];																//For Load Multiple 
	reg [15:0] MEM_WB_LMD_RF[6:1];	
	wire [1:0] DF_CONTROL_A, DF_CONTROL_B;
	reg [15:0] ALUout, WB_ALUout; 																// For forwarding
	integer i ;
	reg Imm_load_dep;
	reg count_en;
	
	
	parameter add_group= 4'b0001, nand_group= 4'b0010, adi_group= 4'b0000,
	lli_group= 4'b0011, lw_group= 4'b0100, sw_group= 4'b0101, lm_group= 4'b0110,
	sm_group= 4'b0111, beq_group= 4'b1000, blt_group= 4'b1001, ble_group= 4'b1010,
	jal_group= 4'b1100,jlr_group= 4'b1101, jri_group= 4'b1111;
	
	parameter ADA = 5'b00000, ADC= 5'b00001, ADZ= 5'b00010, AWC= 5'b00011, 
	ACA= 5'b00100, ACC= 5'b00101, ACZ= 5'b00110, ACW= 5'b00111, ADI= 5'b01000,
	NDU= 5'b01001, NDC= 5'b01010, NDZ= 5'b01011, NCU= 5'b01100, NCC= 5'b01101, NCZ= 5'b01110, 
	LLI= 5'b01111, LW= 5'b10000, SW= 5'b10001, LM= 5'b10010, LMF= 5'b10011, SM= 5'b10100, SMF= 5'b10101,
	BEQ= 5'b10110, BLT= 5'b10111, BLE= 5'b11000, JAL= 5'b11001, JLR= 5'b11010, JRI= 5'b11011;
																											
	
	reg STALLED ; 																						//set after Load Insruction
	reg [1:0]count_for_stall;
	reg [4:0] ID_RR_INSTRUCTION , RR_EX_INSTRUCTION , EX_MEM_INSTRUCTION , MEM_WB_INSTRUCTION;
	 
//..........................IF STAGE........................//

	always @(posedge clk)
		begin 
			if ((STALLED== 1) )
				begin
				end
			else 
				 begin
					if ((((EX_MEM_IR[15:12]==beq_group)|| (EX_MEM_IR[15:12]==ble_group) || (EX_MEM_IR[15:12]==blt_group)) && cond==1) || 
							(EX_MEM_IR[15:12]==jal_group) || (EX_MEM_IR[15:12]==jlr_group) || (EX_MEM_IR[15:12]==jri_group))           //Cond reg kyu hata diya yaha se?
					
					  begin 
						 IF_ID_IR     <= I_Mem[ALUout];
				 		 IF_ID_NPC    <= ALUout + 1;
						 PC           <= ALUout + 1; 
					  end
					else
						begin
						 IF_ID_IR     <= I_Mem[PC];
						 IF_ID_NPC    <= PC+1 ;
						 PC           <= PC+1 ;
						end
						
					
			 end
		end
		
//.................... ID STAGE ......................//

	always @(posedge clk)
	  begin
		 if ((STALLED == 1))
			begin
			end
		 else 
			 begin
				//This is for flush after Branch/Jump instruction
			  ID_RR_NPC <= IF_ID_NPC;
			  if ((((EX_MEM_IR[15:12]==beq_group)|| (EX_MEM_IR[15:12]==ble_group) || (EX_MEM_IR[15:12]==blt_group)) && flush==1) || 
					(EX_MEM_IR[15:12]==jal_group) || (EX_MEM_IR[15:12]==jlr_group) || (EX_MEM_IR[15:12]==jri_group)) 
					begin
						ID_RR_IR <= 16'bX;
						ID_RR_INSTRUCTION <= 5'bX;
					end
					else	
					begin
					ID_RR_IR <= IF_ID_IR;
			  
			  //Understanding the instruction
			  case (IF_ID_IR[15:12])
				
				
				add_group: 
					begin
						case(IF_ID_IR[2:0])
						  
							3'b000: ID_RR_INSTRUCTION <= ADA;
							3'b010: ID_RR_INSTRUCTION <= ADC;
							3'b001: ID_RR_INSTRUCTION <= ADZ;
							3'b011: ID_RR_INSTRUCTION <= AWC;
							3'b100: ID_RR_INSTRUCTION <= ACA;
							3'b110: ID_RR_INSTRUCTION <= ACC;
							3'b101: ID_RR_INSTRUCTION <= ACZ;
							3'b111: ID_RR_INSTRUCTION <= ACW;				
						  
						endcase
					end
				
				adi_group: ID_RR_INSTRUCTION <= ADI;
				
				nand_group: 
						begin
							case(IF_ID_IR[2:0])
							  
								3'b000: ID_RR_INSTRUCTION <= NDU;
								3'b010: ID_RR_INSTRUCTION <= NDC;
								3'b001: ID_RR_INSTRUCTION <= NDZ;
								3'b100: ID_RR_INSTRUCTION <= NCU;
								3'b110: ID_RR_INSTRUCTION <= NCC;
								3'b101: ID_RR_INSTRUCTION <= NCZ;			
							endcase
						end
				
				lli_group: ID_RR_INSTRUCTION <= LLI;
				
				lw_group: ID_RR_INSTRUCTION <= LW;
				
				sw_group: ID_RR_INSTRUCTION <= SW;
				
				lm_group: begin
								case(IF_ID_IR[8])
								
									1'b0: ID_RR_INSTRUCTION <= LM;
									1'b1: ID_RR_INSTRUCTION <= LMF;
								endcase
							 end
				
				sm_group: begin
								case(IF_ID_IR[8])
								
									1'b0: ID_RR_INSTRUCTION <= SM;
									1'b1: ID_RR_INSTRUCTION <= SMF;
								endcase
							 end
				
				beq_group: ID_RR_INSTRUCTION <= BEQ;
				
				blt_group: ID_RR_INSTRUCTION <= BLT;
				
				ble_group: ID_RR_INSTRUCTION <= BLE;
				
				jal_group: ID_RR_INSTRUCTION <= JAL;
				
				jlr_group: ID_RR_INSTRUCTION <= JLR;
				
				jri_group: ID_RR_INSTRUCTION <= JRI;
							
			   default  :  begin
								end		
			 endcase
			 
			 end
			
			
			end
	
	end
	
	always @(*)
	begin
			 if((RR_EX_IR[15:12] == lw_group) && (RR_EX_IR[11:9] == IF_ID_IR[11:9])) //level 1 load dependency
							begin
								Imm_load_dep <= 1'b0; count_en <=1'b1;
							end
					else if((ID_RR_IR[15:12] == lw_group) && (RR_EX_IR[11:9] == IF_ID_IR[11:9]))  //Immediate load dependency
							begin
								Imm_load_dep <= 1'b1; count_en <= 1'b1;
							end
					else if(STALLED == 0)
						count_en <= 0;
	end
	
	//assign LOAD_IMM_DEP = ((RR_EX_IR[11:9] == lw_group) && ((ID_RR_IR[11:9] == RR_EX_IR[5:3]) || (ID_RR_IR[8:6] == RR_EX_IR[5:3])));
	assign DF_CONTROL_A_IMM = (ID_RR_IR[11:9] == RR_EX_IR[5:3]);
	assign DF_CONTROL_A_L1 = (ID_RR_IR[11:9] == EX_MEM_IR[5:3]);
	assign DF_CONTROL_A_L2 = (ID_RR_IR[11:9] == MEM_WB_IR[5:3]);
	
	
	assign DF_CONTROL_B_IMM = (ID_RR_IR[8:6] == RR_EX_IR[5:3]);
	assign DF_CONTROL_B_L1 = (ID_RR_IR[8:6] == EX_MEM_IR[5:3]);
	assign DF_CONTROL_B_L2 = (ID_RR_IR[8:6] == MEM_WB_IR[5:3]);
	
	reg reg_DFC_A_Imm, reg_DFC_A_L1, reg_DFC_A_L2;
	reg reg_DFC_B_Imm, reg_DFC_B_L1, reg_DFC_B_L2;

	//.................... RR STAGE ......................//

	always @(posedge clk)
		begin
		 if ((STALLED == 1) )
			begin
			end
		 else 
			begin	 
			
				reg_DFC_A_Imm = DF_CONTROL_A_IMM;
				reg_DFC_A_L1 = DF_CONTROL_A_L1;
				reg_DFC_A_L2 = DF_CONTROL_A_L2;
				
				reg_DFC_B_Imm = DF_CONTROL_B_IMM;
				reg_DFC_B_L1 = DF_CONTROL_B_L1;
				reg_DFC_B_L2 = DF_CONTROL_B_L2;		 
			
				RR_EX_NPC <= ID_RR_NPC;
			
			
			
				if ((((RR_EX_IR[15:12]==beq_group)|| (RR_EX_IR[15:12]==ble_group) || (RR_EX_IR[15:12]==blt_group)) && flush==1) || 
					(RR_EX_IR[15:12]==jal_group) || (RR_EX_IR[15:12]==jlr_group) || (RR_EX_IR[15:12]==jri_group)) 
					begin
							RR_EX_IR <= 16'bX;
							RR_EX_INSTRUCTION <= 5'bX;
							RR_EX_A <= 16'bX;
							RR_EX_B <= 16'bX;
					end
				else	
					begin
					RR_EX_IR  <= ID_RR_IR;
				   RR_EX_INSTRUCTION <= ID_RR_INSTRUCTION;
					
						if(((MEM_WB_IR[15:12] == lw_group) && (MEM_WB_IR[11:9] == ID_RR_IR[11:9])) && (count_en == 0))  //Level 2 load dependency 
							begin
								RR_EX_A <= MEM_WB_LMD;
								RR_EX_B <= RF[ID_RR_IR[8:6]];
							end
						else if((MEM_WB_IR[15:12] == lw_group) && 
								(MEM_WB_IR[11:9] == ID_RR_IR[8:6]))
							begin
								RR_EX_B <= MEM_WB_LMD;
								RR_EX_A <=RF[ID_RR_IR[11:9]];
							end
					
						else
						
							begin
								
								// R-R data dependencies
								if(reg_DFC_A_Imm==1)
										RR_EX_A <= ALUout;
								else if(reg_DFC_A_L1==1)
										RR_EX_A <= EX_MEM_ALUout;
								else if(reg_DFC_A_L2==1)	
										RR_EX_A <= MEM_WB_ALUout;
								else 
										RR_EX_A <=RF[ID_RR_IR[11:9]];
								
								if(reg_DFC_B_Imm==1)
										RR_EX_B <= ALUout;
								else if(reg_DFC_B_L1==1)
										RR_EX_B <= EX_MEM_ALUout;
								else if(reg_DFC_B_L2==1)	
										RR_EX_B <= MEM_WB_ALUout;
								else 
									RR_EX_B <=RF[ID_RR_IR[8:6]];
							end
					end
					
		   
		   
		   RR_EX_Imm<= {{10{ID_RR_IR[5]}},{ID_RR_IR[5:0]}} ;								
		   RR_EX_Imm_9bits <= {{7{ID_RR_IR[8]}},{ID_RR_IR[8:0]}};
		  
		 
		  
		  
//		  case (DF_CONTROL_A)
//		     2'b00  : RR_EX_A <= RF[ID_RR_IR[11:9]];
//		     2'b01  : RR_EX_A <= EX_MEM_ALUout;
//		     2'b10  : RR_EX_A <= MEM_WB_ALUout;
//		     2'b11  : RR_EX_A <= WB_ALUout;
//		  endcase
//		
//		  case (DF_CONTROL_B)
//		     2'b00  : RR_EX_B <= RF[ID_RR_IR[8:6]];
//		     2'b01  : RR_EX_B <= EX_MEM_ALUout;
//		     2'b10  : RR_EX_B <= MEM_WB_ALUout;
//		     2'b11  : RR_EX_B <= WB_ALUout;
//		  endcase
//		   
		  

		 end
		end
		
//Always Block for Stall control signal

   always @(posedge clk)
		begin
			if(count_en == 1'b1)
				
				begin
					if(Imm_load_dep == 1'b0) //Level 1 load dependency
						begin
							if(count_for_stall !=1)
								begin
									STALLED <= 1'b1; 
									count_for_stall <= count_for_stall + 1; 
								end
					      else
								begin
									STALLED <= 1'b0;
									count_for_stall <= 0; 
								end
						end
					else //Immediate load dependency
						begin
							if(count_for_stall != 2)
								begin
									STALLED <= 1'b1; 
									count_for_stall <= count_for_stall + 1; 
								end
							else
								begin
									STALLED <= 1'b0;
									count_for_stall <= 0;
								end
						end
				end
			else
				begin
					count_for_stall <= 0;
					STALLED <= 0;
				end
		end
		

//.................... EX STAGE ......................//

	always @(posedge clk)
		begin

				EX_MEM_NPC <= RR_EX_NPC;
					if ((((MEM_WB_IR[15:12]==beq_group)|| (MEM_WB_IR[15:12]==ble_group) || (MEM_WB_IR[15:12]==blt_group)) && flush==1) || 
					(MEM_WB_IR[15:12]==jal_group) || (MEM_WB_IR[15:12]==jlr_group) || (MEM_WB_IR[15:12]==jri_group)) 
					begin
						 EX_MEM_IR <= 16'bX;
						 EX_MEM_INSTRUCTION <= 5'bX;
					end
					else	
						begin
						EX_MEM_IR <= RR_EX_IR;
						EX_MEM_INSTRUCTION <= RR_EX_INSTRUCTION; 
						end				

					EX_MEM_ALUout <= ALUout;
					EX_MEM_CCR <= CCR;
				
		
		end
	always @(*)
	begin
				case( RR_EX_INSTRUCTION)
					ADA: begin																//Basic Addition
							{CCR[1],ALUout} <= RR_EX_A + RR_EX_B;
							if(CCR[1] == 1'b0 && ALUout == 16'b0)
								begin 
								  CCR[0] = 1'b1;
								end
						  end
					ADC:begin																//Add when Carry Flag is set
						if(CCR[1] == 1'b1)
							begin
							{CCR[1],ALUout} <= RR_EX_A + RR_EX_B;
							if(CCR[1] == 1'b0 && ALUout == 16'b0)
								CCR[0] <= 1'b1;
							end
						end
					ADZ: begin																//Add when ZEro flag is set
							if(CCR[0] == 1'b1)
								begin
								{CCR[1],ALUout} <= RR_EX_A + RR_EX_B;
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					AWC: begin
								{CCR[1],ALUout} <= RR_EX_A + RR_EX_B + CCR[1];
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
						  end
					ACA: begin
								{CCR[1],ALUout} <= RR_EX_A + ~RR_EX_B;
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
						  end
					ACC: begin																
							if(CCR[1] == 1'b1)
							  begin
								{CCR[1],ALUout} <= RR_EX_A + ~RR_EX_B;
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
							  end
                     end			
               ACZ: begin																
							if(CCR[0] == 1'b1)
								begin
								{CCR[1],ALUout} <= RR_EX_A + ~RR_EX_B;
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					ACW: begin
								{CCR[1],ALUout} <= RR_EX_A + ~RR_EX_B + CCR[1];
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
						  end
					ADI: begin
							{CCR[1],ALUout} <= RR_EX_A + RR_EX_Imm;
							if(CCR[1] == 1'b0 && ALUout == 16'b0)
										CCR[0] <= 1'b1;
							end
					NDU: begin
							ALUout <= ~(RR_EX_A & RR_EX_B);
							if(ALUout == 16'b0)
								CCR[0] <= 1'b1;
							end
					NDC: begin																
							if(CCR[1] == 1'b1)
								begin
								{ALUout} <= ~(RR_EX_A & RR_EX_B);
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					NDZ: begin																
							if(CCR[0] == 1'b1)
								begin
								{ALUout} <= ~(RR_EX_A & RR_EX_B);
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					NCU: begin
							ALUout <= ~(RR_EX_A & ~RR_EX_B);
							if(ALUout == 16'b0)
								CCR[0] <= 1'b1;
							end
					NCC: begin																
							if(CCR[1] == 1'b1)
								begin
								{ALUout} <= ~(RR_EX_A & ~RR_EX_B);
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					NCZ: begin																
							if(CCR[0] == 1'b1)
								begin
								{ALUout} <= ~(RR_EX_A & ~RR_EX_B);
								if(CCR[1] == 1'b0 && ALUout == 16'b0)
									CCR[0] <= 1'b1;
								end
							end
					LLI: ALUout <= {{7{1'b0}},RR_EX_Imm_9bits[8:0]};					
					LW: begin 																			//Simple LW, SW
							ALUout <= RR_EX_B + RR_EX_Imm;
						 end
					SW: begin 																			//Simple LW, SW
							ALUout <= RR_EX_B + RR_EX_Imm;
							EX_MEM_A <= RR_EX_A;
						 end
					LM: begin
								ALUout <= RR_EX_A;
								for(i=1; i<7; i=i+1)
									begin
										EX_MEM_RF_LS[i] = RR_EX_A + i;
									end
						 end 	
					//LMF:																					//still left
					SM: begin
								ALUout <= RR_EX_A;
								for(i=1; i<7; i=i+1)
									begin
										EX_MEM_RF_LS[i] = RR_EX_A + i;
									end
						 end 	
					//SMF:																					//still left, need to understand
					BEQ: begin 
							if (RR_EX_A == RR_EX_B)
								begin
									ALUout <= RR_EX_NPC + RR_EX_Imm*2;			//Here (PC+1+IMM*2) has been done rather PC+IMM
									cond = 1'b1;
									flush = 1'b1;
									
								end
							else
								begin
								cond = 1'b0;
								flush = 1'b0;
								end
						  end
					BLT: begin 
							if (RR_EX_A < RR_EX_B)
								begin
									ALUout <= RR_EX_NPC + RR_EX_Imm*2;			//Here (PC+1+IMM*2) has been done rather PC+IMM
									cond = 1'b1;
									flush = 1'b1;
								end
							else
								begin
								cond = 1'b0;
								flush = 1'b0;
								end
						  end
					BLE: begin 
							if (RR_EX_A <= RR_EX_B)
								begin
									ALUout <= RR_EX_NPC + RR_EX_Imm*2;			//Here (PC+1+IMM*2) has been done rather PC+IMM
									cond = 1'b1;
									flush = 1'b1;
								end
							else
								begin
								cond = 1'b0;
								flush = 1'b0;
								end
						  end
					JAL: ALUout <= RR_EX_NPC +RR_EX_Imm_9bits*2; // pc+2 not done

					JLR: ALUout <= RR_EX_B; // pc+2 not done

					JRI: ALUout <= RR_EX_A + RR_EX_Imm_9bits*2;
					
					default: begin
								end
					
				 endcase
				 
			 end
		
		
		
//	always @(posedge clk)
//		begin
//			if ((((EX_MEM_IR[15:12]==beq_group)|| (EX_MEM_IR[15:12]==ble_group) || (EX_MEM_IR[15:12]==blt_group)) && flush==1) || 
//							(EX_MEM_IR[15:12]==jal_group) || (EX_MEM_IR[15:12]==jlr_group) || (EX_MEM_IR[15:12]==jri_group))  
				
					
		
		

//..............................MEM STAGE..................//

	always @(posedge clk)
		begin
			MEM_WB_INSTRUCTION <= EX_MEM_INSTRUCTION;
			MEM_WB_IR  <= EX_MEM_IR;
			MEM_WB_NPC <= EX_MEM_NPC;
			MEM_WB_CCR <= EX_MEM_CCR;
			//stalled=1'b0;                      					// Might be useful in stalling instruction t the time of load
			case(EX_MEM_IR[15:12])
				add_group,adi_group: MEM_WB_ALUout <= EX_MEM_ALUout;
				
				nand_group: MEM_WB_ALUout <= EX_MEM_ALUout;
				
				lli_group: MEM_WB_ALUout <= EX_MEM_ALUout;
				
				lw_group: MEM_WB_LMD <= D_Mem[EX_MEM_ALUout];
				
				sw_group: begin
								//if(TAKEN_BRANCH == 0)
								D_Mem[EX_MEM_ALUout] <= EX_MEM_A;
							end
							
				lm_group: case(EX_MEM_INSTRUCTION)
								LM: begin
										MEM_WB_ALUout <= D_Mem[EX_MEM_ALUout];
										MEM_WB_LMD_RF[1] <= D_Mem[EX_MEM_RF_LS[1]];
										MEM_WB_LMD_RF[2] <= D_Mem[EX_MEM_RF_LS[2]];
										MEM_WB_LMD_RF[3] <= D_Mem[EX_MEM_RF_LS[3]];
										MEM_WB_LMD_RF[4] <= D_Mem[EX_MEM_RF_LS[4]];
										MEM_WB_LMD_RF[5] <= D_Mem[EX_MEM_RF_LS[5]];
										MEM_WB_LMD_RF[6] <= D_Mem[EX_MEM_RF_LS[6]];
									 end
								//LMF: 
								
							 endcase
							 
				sm_group: case(EX_MEM_INSTRUCTION)
								SM: begin
										D_Mem[EX_MEM_ALUout]<= RF[1];
										D_Mem[EX_MEM_RF_LS[1]] <= RF[2];
					               D_Mem[EX_MEM_RF_LS[2]] <= RF[3];
				                  D_Mem[EX_MEM_RF_LS[3]] <= RF[4];
				                  D_Mem[EX_MEM_RF_LS[4]] <= RF[5];
				                  D_Mem[EX_MEM_RF_LS[5]] <= RF[6];
				                  D_Mem[EX_MEM_RF_LS[6]] <= RF[7];
									 end
								//SMF:
							 endcase
			endcase
		end

//..............................WB STAGE..................//
	always @(posedge clk)
		begin
	//	if(TAKEN_BRANCH == 0)
			//	begin
					WB_ALUout <= MEM_WB_ALUout ;
					
					case(MEM_WB_IR[15:12])
						//add_group, nand_group: RF[MEM_WB_IR[5:3]] <= MEM_WB_ALUout;
						add_group: case(MEM_WB_INSTRUCTION)
											ADC: RF[MEM_WB_IR[5:3]] = MEM_WB_CCR[1] ? MEM_WB_ALUout : RF[MEM_WB_IR[5:3]];
											ADZ: RF[MEM_WB_IR[5:3]] = MEM_WB_CCR[0] ? MEM_WB_ALUout : RF[MEM_WB_IR[5:3]];
											default: RF[MEM_WB_IR[5:3]] <= MEM_WB_ALUout;
									  endcase
									  
						nand_group: case(MEM_WB_INSTRUCTION)
											NDC: RF[MEM_WB_IR[5:3]] = MEM_WB_CCR[1] ? MEM_WB_ALUout : RF[MEM_WB_IR[5:3]];
											NDZ: RF[MEM_WB_IR[5:3]] = MEM_WB_CCR[0] ? MEM_WB_ALUout : RF[MEM_WB_IR[5:3]];
											default: RF[MEM_WB_IR[5:3]] <= MEM_WB_ALUout;
									  endcase
						
						adi_group : RF[MEM_WB_IR[8:6]] <= MEM_WB_ALUout;
						
						lli_group : RF[MEM_WB_IR[11:9]] <= MEM_WB_ALUout;
						
						lw_group : RF[MEM_WB_IR[11:9]] = MEM_WB_LMD ;
						
						lm_group : case(MEM_WB_INSTRUCTION)
											LM: begin
													RF[1] <= MEM_WB_IR[6] ? MEM_WB_ALUout: RF[1];
													RF[2] <= MEM_WB_IR[5] ? MEM_WB_LMD_RF[1]: RF[2];
													RF[3] <= MEM_WB_IR[4] ? MEM_WB_LMD_RF[2]: RF[3];
													RF[4] <= MEM_WB_IR[3] ? MEM_WB_LMD_RF[3]: RF[4];
													RF[5] <= MEM_WB_IR[2] ? MEM_WB_LMD_RF[4]: RF[5];
													RF[6] <= MEM_WB_IR[1] ? MEM_WB_LMD_RF[5]: RF[6];
													RF[7] <= MEM_WB_IR[0] ? MEM_WB_LMD_RF[6]: RF[7];
												 end
											//LMF: 
										endcase
										
					
					endcase
				//end
		end
endmodule