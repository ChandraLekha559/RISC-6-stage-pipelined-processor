module risc6_tb ;

reg clk;
integer i,j;

iitb_risc dut(clk);

initial 
	begin
		clk=0;
		repeat(150)
			begin
				#5 clk=1; #5 clk=0;
				
			end
	end
	
	
	initial begin 
				for(i=0;i<16;i=i+1)
				dut.RF[i]=i*10;
            dut.PC <= 0;
				
				for(j=0;j<1025;j=j+1)
				dut.D_Mem[j] = j;
				
			  end
	
initial 
	begin
		   
			 dut.I_Mem[0]  = 16'b0001_100_010_011_000;//ada r3,r4,r2;	r3=60
			 dut.I_Mem[1]  = 16'b0100_111_101_001111; //lw r7,r5,imm=15;	r7=mem[50+15]
          dut.I_Mem[2]  = 16'b0101_111_011_001_000;// ada r1,r3,r7;
			 dut.I_Mem[3]  = 16'b0100_001_110_111100; // sw r1,r6,imm ;
			 dut.I_Mem[4]  = 16'b1000_011_110_001111; //beq r3,r6,imm;	4+1+30=35
          dut.I_Mem[5]  = 16'b0010_010_011_001_000; //ndu r2,r2,r2;	r2=-12
			 dut.I_Mem[6]  = 16'b0001_110_111_010_000;//ada r2,r6,r7;	r3=60

//			 dut.I_Mem[1]  = 16'b0001_111_011_001_000;// ada r1,r3,r7;
//			 dut.I_Mem[2]  = 16'b0001_101_100_011_010; //adc r3,r5,r4;	r3=30
//        dut.I_Mem[3]  = 16'b0010_010_011_001_000; //ndu r1,r2,r3;	r1=-45
//			 dut.I_Mem[4]  = 16'b0001_110_100_011_000; //ada r3,r6,r4;	r3=100
//			 dut.I_Mem[5]  = 16'b0010_110_111_101_100; //ncu r5,r6,r7;	r5=60
//			 dut.I_Mem[6]  = 16'b0011_010_001100100; //lli r2,imm=100;	r2=100
//			 dut.I_Mem[7]  = 16'b1000_011_010_001111; //beq r3,r2,imm;	7+1+30=38
			
		    dut.D_Mem[65]  = 16'b0000_0000_0001_0000; //for lw
		    dut.I_Mem[35]  = 16'b0000_001_001_001_000; //ada r1,r1,r1;	r1=20
//         
	 
	 
	 
	 
	 #1000
	 $display("R1 = %d", dut.RF[1]);			
 end
	



endmodule