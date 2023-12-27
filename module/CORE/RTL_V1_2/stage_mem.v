`include "define.v"
module stage_mem(
    input  wire        clk,
    input  wire        rstn,
    input  wire[31:0]  me_regs_data2,
    input  wire[31:0]  me_alu_o, 
    input  wire        me_mem_read,
    input  wire        me_mem_write,
    input  wire[2:0]   me_func3_code,
    //forwarding
    input wire         forward_data,
    input wire[31:0]   w_regs_data,

    input wire[1:0]    me_priv_mode, // yjk add
    input wire[31:0]   me_satp, // yjk add

`ifdef FPGA_MODE
    output reg[2:0]    me_led,
`endif
    output wire[31:0]  me_mem_data
);

reg [31:0]  w_data_mem;//actually wire
wire[31:0]  w_data_mem_pre;
wire[31:0]  r_data_mem;
reg [ 3:0]  w_en_mem;//actually wire
//wire[ 3:0]  r_en_mem;
wire[31:0]  addr_mem;
wire[ 1:0]  addr_in_word;
wire        en_mem;

// yjk del
// data_memory 
// #(
//     .RAM_SPACE (4096       )
// )
// u_data_memory(
//     .clk        (clk               ),
//     //.rstn       (rstn              ),
//     .addr_mem   (addr_mem          ),
//     .w_data_mem (w_data_mem        ),
// //    .r_en_mem   (r_en_mem          ),
//     .w_en_mem   (w_en_mem          ),
//     .en_mem     (en_mem            ),
//     .r_data_mem (r_data_mem        )
// );
// yjk del end

// yjk add, replace data_memory
// orginally use 
// Read: addr_mem, en_mem, r_data_mem
// Write: addr_mem, w_en_mem, w_data_mem
// we need to replace *addr_mem* to *addr_mem_pa* only

wire [31:0] addr_mem_pa;
wire [31:0] pte1_addr;
wire [31:0] pte2_addr;
wire [31:0] paddr;
wire [31:0] pte1;
wire [31:0] pte2;

assign pte1_addr = {me_satp[21:0], addr_mem[31:22], 2'b0};
assign pte2_addr = {pte1[31:10], addr_mem[21:12], 2'b0};
assign paddr = {pte2[31:12], addr_mem[11:0]};

assign addr_mem_pa = (me_priv_mode==2'b11)? addr_mem : paddr;

dmem 
    #(
        .DATA_WHITH  (32    ),
        .DATA_SIZE   (8     ),
        .ADDR_WHITH  (10    ),
        .RAM_DEPTH   (1024  )
    )
    u_dmem(
    .clk     (clk       ),
    .en      (en_mem    ),
    .wen     (w_en_mem  ),
    .addr1   (pte1_addr),
	.addr2   (pte2_addr),
	.addr3   (addr_mem_pa),
    .wdata   (w_data_mem),
    .rdata1  (pte1),
    .rdata2  (pte2),
    .rdata3  (r_data_mem )
);

// yjk add end

assign w_data_mem_pre = forward_data ? w_regs_data : me_regs_data2; //forwarding for load+store which have data correlation
assign addr_mem       = me_alu_o;
assign addr_in_word   = addr_mem[1:0];
assign en_mem         = me_mem_read | me_mem_write ;

/*----------------Read DataMemory---------------------*/
// the data read from mem will be valid at next cycle, so the logic design for L-inst has been moved to stage_wb!

assign me_mem_data = r_data_mem;

/*----------------Write DataMemory---------------------*/
always @(*) begin
    case(me_func3_code[1:0])
    `SB:begin
        case (addr_in_word)
            2'b00:   w_data_mem = {24'd0,w_data_mem_pre[7:0]};
            2'b01:   w_data_mem = {16'd0,w_data_mem_pre[7:0], 8'd0};
            2'b10:   w_data_mem = {8'd0,w_data_mem_pre[7:0], 16'd0};
            2'b11:   w_data_mem = {w_data_mem_pre[7:0],24'd0};
            default: w_data_mem = {32'd0};
        endcase
    end
    `SH:begin
        case (addr_in_word[1])//Half-byte address alignment
            1'b0:    w_data_mem = {16'd0,w_data_mem_pre[15:0]};
            1'b1:    w_data_mem = {w_data_mem_pre[15:0],16'd0};
            default: w_data_mem = {32'd0};
        endcase
    end
    `SW:     w_data_mem = w_data_mem_pre;
    default: w_data_mem = 32'd0;
    endcase
    //$strobe("WRITE DATA MEMORY: Addr %d = %h ,mode:%d", addr_mem,{data[addr_mem+3],data[addr_mem+2],data[addr_mem+1],data[addr_mem]},byte_sel);
end

//write enable with byte selection
always @(*)begin
    if(me_mem_write)
        case(me_func3_code[1:0])
            `SB : w_en_mem = 4'b0001 << addr_in_word;
            `SH : w_en_mem = 4'b0011 << {addr_in_word[1],1'b0};//Half-byte address alignment
            `SW : w_en_mem = 4'b1111;
            default : w_en_mem = 4'b0000;
        endcase
    else
        w_en_mem = 4'b0000;
end

always @(*) begin
    if (me_mem_write) begin
    $strobe("WRITE DATA MEMORY: Addr %d = %h ", addr_mem, w_data_mem);
    end
end

`ifdef FPGA_MODE 
    always @(posedge clk  or negedge rstn) begin
        if (!rstn)begin
            me_led  <= 3'b0;
        end
        else if (me_alu_o == 32'h400) begin
            me_led  <= w_data_mem[2:0];
        end
    end
`endif

endmodule