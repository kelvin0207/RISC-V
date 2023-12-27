// This file is created by Yang Jingkui on 2023/12/27
// This file includes the dmem, supporting 3R1W for page table access
// If in M mode, use addr3 and rdata3, write use addr3
module dmem
    #(
        parameter   DATA_WHITH  = 32    ,
        parameter   DATA_SIZE   = 8     ,
        parameter   ADDR_WHITH  = 10    ,
        parameter   RAM_DEPTH   = 1024  ,
        parameter   DATA_BYTE = DATA_WHITH/DATA_SIZE
    )
	(
    //system signals
    input                               clk     ,
    //RAM Control signals
    input                               en      ,
    input           [DATA_BYTE-1:0]     wen     ,
    input           [ADDR_WHITH-1:0]    addr1   ,
	input			[ADDR_WHITH-1:0]    addr2   ,
	input			[ADDR_WHITH-1:0]    addr3   ,
    input           [DATA_WHITH-1:0]    wdata   ,
    output          [DATA_WHITH-1:0]    rdata1  ,
    output          [DATA_WHITH-1:0]    rdata2  ,
    output          [DATA_WHITH-1:0]    rdata3
);

reg [DATA_WHITH-1:0] mem    [0:RAM_DEPTH-1] ;

assign rdata1 = (wen)? 0: mem[addr1];
assign rdata2 = (wen)? 0: mem[addr2];
assign rdata3 = (wen)? 0: mem[addr3];

genvar i;

generate
    for(i=0; i<DATA_BYTE; i=i+1)begin:ram_with_mask
        always @(posedge clk)begin
            if(en && wen[i])
                mem[addr3][(DATA_SIZE*i)+:DATA_SIZE] <= addr3[(DATA_SIZE*i)+:DATA_SIZE];
        end
    end
endgenerate

endmodule