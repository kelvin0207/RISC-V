// This file is created by Yang Jingkui on 2023/12/27
// This file includes the dmem, supporting 3R1W for page table access
// If in M mode, use addr3 and rdata3, write use addr3
module dmem
    #(
        parameter   DATA_WIDTH  = 32    ,
        parameter   DATA_SIZE   = 8     ,
        parameter   ADDR_WIDTH  = 10    ,
        parameter   RAM_DEPTH   = 1024  ,
        parameter   DATA_BYTE = DATA_WIDTH/DATA_SIZE
    )
	(
    //system signals
    input                               clk     ,
    //RAM Control signals
    input                               en      ,
    input           [DATA_BYTE-1:0]     wen     ,
    input           [31:0]              addr1   ,
	input			[31:0]              addr2   ,
	input			[31:0]              addr3   ,
    input           [DATA_WIDTH-1:0]    wdata   ,
    output          [DATA_WIDTH-1:0]    rdata1  ,
    output          [DATA_WIDTH-1:0]    rdata2  ,
    output          [DATA_WIDTH-1:0]    rdata3
);

reg [DATA_WIDTH-1:0] mem    [0:RAM_DEPTH-1] ;

wire [ADDR_WIDTH-1:0] addr1_align;
wire [ADDR_WIDTH-1:0] addr2_align;
wire [ADDR_WIDTH-1:0] addr3_align;

assign addr1_align = addr1[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE
assign addr2_align = addr2[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE
assign addr3_align = addr3[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE

assign rdata1 = (wen)? 0: mem[addr1_align];
assign rdata2 = (wen)? 0: mem[addr2_align];
assign rdata3 = (wen)? 0: mem[addr3_align];

genvar i;

generate
    for(i=0; i<DATA_BYTE; i=i+1)begin:ram_with_mask
        always @(posedge clk)begin
            if(en && wen[i])
                mem[addr3_align][(DATA_SIZE*i)+:DATA_SIZE] <= wdata[(DATA_SIZE*i)+:DATA_SIZE];
        end
    end
endgenerate

endmodule