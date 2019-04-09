//=====================================================
// Store Datapath - SB, SH, SW
//=====================================================

module store_datapath (
    input  wire [1:0]  store_type, // 00=SB, 01=SH, 10=SW
    input  wire [31:0] write_data, // rs2 data
    input  wire [31:0] addr,       // ALU result (byte address)
    output reg  [31:0] mem_write_data,
    output reg  [3:0]  byte_enable
);

    always @(*) begin
        mem_write_data = 32'b0;
        byte_enable    = 4'b0000;

        case(store_type)
            //---------------------------------------------------
            // SB - Store Byte (write_data[7:0])
            //---------------------------------------------------
            2'b00: begin
                mem_write_data = {4{write_data[7:0]}}; // replicated
                case(addr[1:0])
                    2'b00: byte_enable = 4'b0001;
                    2'b01: byte_enable = 4'b0010;
                    2'b10: byte_enable = 4'b0100;
                    2'b11: byte_enable = 4'b1000;
                endcase
            end

            //---------------------------------------------------
            // SH - Store Halfword (write_data[15:0])
            //---------------------------------------------------
            2'b01: begin
                mem_write_data = {2{write_data[15:0]}};
                byte_enable = addr[1] ? 4'b1100 : 4'b0011;
            end

            //---------------------------------------------------
            // SW - Store Word (write_data[31:0])
            //---------------------------------------------------
            2'b10: begin
                mem_write_data = write_data;
                byte_enable    = 4'b1111;
            end
        endcase
    end

endmodule

