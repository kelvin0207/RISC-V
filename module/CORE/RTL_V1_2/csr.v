// This file is created by Yang Jingkui on 2023/12/26
// This file includes the csr module, embedded in EX stage
`include "define.v"

module csr(
	input	wire		clk,
	input	wire		rstn,
	input	wire[1:0]	priv_mode,
	input	wire		w_en,
	input	wire[31:0]	w_data,
	input	wire[11:0]	w_addr,

	output	wire[31:0]	o_mtvec,
	output	wire[31:0]	o_mstatus,
	output	wire[31:0]	o_mepc,
	output	wire[31:0]	o_mtval,
	output	wire[31:0]	o_mcause,
	output	wire[31:0]	o_satp,
	output	wire[31:0]	o_sepc
);

reg	[31:0]	mtvec;
reg	[31:0]	mstatus;
reg	[31:0]	mepc;
reg	[31:0]	mtval;
reg	[31:0]	mcause;
reg	[31:0]	satp;
reg	[31:0]	sepc;

// write CSRs
always @(posedge clk or negedge rstn) begin
    if (!rstn)begin
		mtvec		<= 0;
		mstatus		<= 0;
		mepc		<= 0;
		mtval		<= 0;
		mcause		<= 0;
		satp		<= 0;
		sepc		<= 0;
	end
	else if(w_en && priv_mode==2'b11) begin // M mode can write any CSRs
		case(w_addr)
			`MTVEC:		mtvec	<= w_data;
			`MSTATUS:	mstatus	<= w_data;
			`MEPC:		mepc	<= w_data;
			`MTVAL:		mtval	<= w_data;
			`MCAUSE:	mcause	<= w_data;
			`SATP:		satp	<= w_data;
			`SEPC:		sepc	<= w_data;
		endcase
	end
	else if(w_en && priv_mode==2'b01) begin // S mode can write S CSRs
		case(w_addr)
			`SATP:		satp	<= w_data;
			`SEPC:		sepc	<= w_data;
		endcase
	end
end

assign o_mtvec		= mtvec		;
assign o_mstatus	= mstatus	;
assign o_mepc		= mepc		;
assign o_mtval		= mtval		;
assign o_mcause		= mcause	;
assign o_satp		= satp		;
assign o_sepc		= sepc		;

endmodule