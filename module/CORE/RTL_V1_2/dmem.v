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
    input   wire        [DATA_BYTE-1:0]     wen     ,
    input   wire                            page_fault,
    input   wire        [31:0]              addr1   ,
	input	wire		[31:0]              addr2   ,
	input	wire		[31:0]              addr3   ,
    input   wire        [DATA_WIDTH-1:0]    wdata   ,
    output  wire        [DATA_WIDTH-1:0]    rdata1  ,
    output  wire        [DATA_WIDTH-1:0]    rdata2  ,
    output  wire        [DATA_WIDTH-1:0]    rdata3  
);

reg [DATA_WIDTH-1:0] mem    [0:RAM_DEPTH-1] ;

wire [ADDR_WIDTH-1:0] addr1_align;
wire [ADDR_WIDTH-1:0] addr2_align;
wire [ADDR_WIDTH-1:0] addr3_align;

assign addr1_align = addr1[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE
assign addr2_align = addr2[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE
assign addr3_align = addr3[ADDR_WIDTH +2-1 : 2];//Word-alignment, and width depends on `RAM_SPACE

assign rdata1 = (en)? mem[addr1_align] : 0;
assign rdata2 = (en)? mem[addr2_align] : 0;
assign rdata3 = (en)? mem[addr3_align] : 0;

genvar i;

generate
    for(i=0; i<DATA_BYTE; i=i+1)begin:ram_with_mask
        always @(posedge clk)begin
            if(en && wen[i] && ~page_fault)
                mem[addr3_align][(DATA_SIZE*i)+:DATA_SIZE] <= wdata[(DATA_SIZE*i)+:DATA_SIZE];
        end
    end
endgenerate

endmodule