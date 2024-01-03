`include "define.v"

module stage_ex(
    input  wire        clk, // yjk add
    input  wire        rstn, // yjk add
    input  wire[31:0]  ex_pc,  //pc_now
    input  wire[31:0]  ex_regs_data1,
    input  wire[31:0]  ex_regs_data2,
    input  wire[31:0]  ex_imm,
    input  wire[2:0]   ex_func3_code, 
    input  wire        ex_func7_code,
    input  wire[2:0]   ex_alu_op,
    input  wire[1:0]   ex_alu_src1,
    input  wire[1:0]   ex_alu_src2,
    input  wire        ex_br_addr_mode,
    input  wire        ex_br,
    //forwarding
    input  wire[1:0]   forwardA,
    input  wire[1:0]   forwardB,
    input  wire[31:0]  me_alu_o,
    input  wire[31:0]  w_regs_data,

    // yjk add
    input  wire[1:0]   ex_csr_op, // default=00, csrrw=01, csrrs=10
    input  wire[1:0]   ex_priv_ret, // default=00, mret=01, sret=10
    input  wire[11:0]  ex_csr_addr,
    output wire[31:0]  ret_pc,
    output wire        ret_ctrl,
    output wire[1:0]   ex_priv_mode,
    output wire[31:0]  ex_satp,
    // yjk add end
    output wire[31:0]  ex_alu_o,
    output wire[31:0]  ex_regs_data2_o,//the data for S-inst 
    output wire[31:0]  br_pc, //branch address
    output wire        br_ctrl
);

wire [3:0]  alu_ctrl;
wire [31:0] op_A;
wire [31:0] op_A_pre;
wire [31:0] op_B;
wire [31:0] op_B_pre;
wire        br_mark;
wire [31:0] br_addr_op_A; 

// yjk add
reg[1:0]      priv_mode; // indicating priv_mode, M:11, S:01, U:00

wire[31:0]    ex_mtvec;
wire[31:0]    ex_mstatus;
wire[31:0]    ex_mepc;
wire[31:0]    ex_mtval;
wire[31:0]    ex_mcause;
// wire[31:0]    ex_satp;
wire[31:0]    ex_sepc;

wire          csr_w_en;
wire[31:0]    csr_w_data;
wire[11:0]    csr_w_addr;

reg[31:0]    csr_r_data;
// wire[31:0]    ex_alu_o; // add for csrrs

wire[31:0]    ex_alu_o2;
// yjk add end

alu_control u_alu_control(
    .alu_op     (ex_alu_op     ),
    .func3_code (ex_func3_code ),
    .func7_code (ex_func7_code ),
    .alu_ctrl_r (alu_ctrl      )
);


alu u_alu(
    .alu_ctrl (alu_ctrl      ),
    .op_A     (op_A          ),
    .op_B     (op_B          ),
    .alu_o    (ex_alu_o2     ),
    .br_mark  (br_mark       )
);

assign br_addr_op_A    = (ex_br_addr_mode == `J_REG) ? op_A_pre : ex_pc;
assign br_pc           = br_addr_op_A + ex_imm;
assign op_B            = (ex_alu_src2 == `PC_PLUS4)? 32'd4 : (ex_alu_src2 == `IMM)? ex_imm : op_B_pre;
assign op_A            = (ex_alu_src1 == `NULL)? 32'd0 : (ex_alu_src1 == `PC)? ex_pc : op_A_pre;
assign op_B_pre        = (forwardB == `EX_MEM_B)? me_alu_o : (forwardB == `MEM_WB_B)? w_regs_data : ex_regs_data2;
assign op_A_pre        = (forwardA == `EX_MEM_A)? me_alu_o : (forwardA == `MEM_WB_A)? w_regs_data : ex_regs_data1;
assign br_ctrl         = br_mark && ex_br;
assign ex_regs_data2_o = op_B_pre;

always @(*) begin
    if (forwardA)
        $display("forwardA! OP_A: %h",op_A);
    else if (forwardB)
        $display("forwardB! OP_B: %h",op_B);
end

// yjk add
// support csrrw
assign csr_w_en = (ex_csr_op==2'b01)? 1'b1 : 1'b0;
assign csr_w_data = ex_regs_data1;
assign csr_w_addr = ex_csr_addr;

// support csrrs
always@(*) begin
    case(ex_csr_addr)
        `MTVEC:		csr_r_data = ex_mtvec;
        `MSTATUS:	csr_r_data = ex_mstatus;
        `MEPC:		csr_r_data = ex_mepc;
        `MTVAL:		csr_r_data = ex_mtval;
        `MCAUSE:	csr_r_data = ex_mcause;
        `SATP:		csr_r_data = ex_satp;
        `SEPC:		csr_r_data = ex_sepc;
    endcase
end

assign ex_alu_o = (ex_csr_op==2'b10)? csr_r_data : ex_alu_o2;

// support mret & sret
assign ret_pc = (ex_priv_ret==2'b01)? ex_mepc:
                    (ex_priv_ret==2'b10)? ex_sepc : 0;

assign ret_ctrl = |ex_priv_ret;

// priv_mode change
always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        priv_mode <= 2'b11;
    end
    else begin
        // mret
        if(ex_priv_ret==2'b01) begin
            priv_mode = ex_mstatus[12:11];
        end
        // sret
        else if(ex_priv_ret==2'b10) begin
            priv_mode = {1'b0, ex_mstatus[8]};
        end
    end
end

assign ex_priv_mode = priv_mode;
// CSRs
csr u_csr(
	.clk        (clk),
	.rstn       (rstn),
	.priv_mode  (priv_mode),
	.w_en       (csr_w_en),
	.w_data     (csr_w_data),
	.w_addr     (csr_w_addr),

	.o_mtvec    (ex_mtvec),
	.o_mstatus  (ex_mstatus),
	.o_mepc     (ex_mepc),
	.o_mtval    (ex_mtval),
	.o_mcause   (ex_mcause),
	.o_satp     (ex_satp),
	.o_sepc     (ex_sepc)
);

// yjk add end
endmodule