//=====================================================
// TOP DATA MEMORY SUBSYSTEM FOR RISC-V
// SB, SH, SW + LB, LH, LW, LBU, LHU
//=====================================================

module data_mem_top (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  load_type,   // 000 LB, 001 LH, 010 LW, 011 LBU, 100 LHU
    input  wire [1:0]  store_type,  // 00 SB, 01 SH, 10 SW
    input  wire [31:0] addr,        // ALU result (byte address)
    input  wire [31:0] rs2_data,    // data to store (from register file)
    output wire [31:0] read_data    // load result to register file
);

    // Internal connections between submodules
    wire [31:0] mem_write_data;
    wire [3:0]  byte_enable;
    wire [31:0] mem_data_out;

    //===============================
    // STORE DATAPATH
    //===============================
    store_datapath u_store (
        .store_type(store_type),
        .write_data(rs2_data),
        .addr(addr),
        .mem_write_data(mem_write_data),
        .byte_enable(byte_enable)
    );

    //===============================
    // MEMORY (BYTE ADDRESSABLE)
    //===============================
    data_memory u_mem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(mem_write_data),
        .byte_enable(byte_enable),
        .mem_data_out(mem_data_out)
    );

    //===============================
    // LOAD DATAPATH
    //===============================
    load_datapath u_load (
        .load_type(load_type),
        .mem_data_in(mem_data_out),
        .addr(addr),
        .read_data(read_data)
    );

endmodule

//`timescale 1ns/1ps

module tb_data_mem_top;

    reg         clk;
    reg         mem_read;
    reg         mem_write;
    reg  [2:0]  load_type;
    reg  [1:0]  store_type;
    reg  [31:0] addr;
    reg  [31:0] rs2_data;
    wire [31:0] read_data;

    // DUT
    data_mem_top dut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .load_type(load_type),
        .store_type(store_type),
        .addr(addr),
        .rs2_data(rs2_data),
        .read_data(read_data)
    );
initial begin
$shm_open("wave.shm");
$shm_probe("ACTMF");
end

    // Clock = 10ns
    always #5 clk = ~clk;

    // Check and print PASS/FAIL
    task check;
        input [31:0] exp;
        input [200*8:1] msg;
        begin
            if (read_data === exp)
                $display("PASS : %s | exp=%h | got=%h", msg, exp, read_data);
            else
                $display("FAIL : %s | exp=%h | got=%h", msg, exp, read_data);
        end
    endtask

    // Clean write procedure
    task do_store;
        input [1:0] stype;
        input [31:0] a;
        input [31:0] din;
        begin
            mem_read = 0;
            store_type = stype;
            addr = a;
            rs2_data = din;
            mem_write = 1;
            @(posedge clk); // write happens here
            @(posedge clk); // allow settle
            mem_write = 0;
        end
    endtask

    // Clean read procedure
    task do_load;
        input [2:0] ltype;
        input [31:0] a;
        begin
            mem_write = 0;
            load_type = ltype;
            addr = a;
            mem_read = 1;
            @(posedge clk); // fetch
            @(posedge clk); // stable read_data
        end
    endtask


    initial begin
        $display("\n======== DATA MEMORY TEST START ========\n");

        clk = 0;
        mem_read = 0;
        mem_write = 0;
        addr = 0;
        rs2_data = 0;
        load_type = 3'b000;
        store_type = 2'b00;

        //=====================
        // SW + LW
        //=====================
        do_store(2'b10, 32'h10, 32'hAABBCCDD);
        do_load(3'b010,  32'h10);
        check(32'hAABBCCDD, "LW test after SW");

        //=====================
        // SB + LB (sign extend)
        //=====================
        do_store(2'b00, 32'h14, 32'h0000007F);
        do_load(3'b000, 32'h14);
        check(32'h0000007F, "LB test after SB");

        //=====================
        // SB + LBU (zero extend)
        //=====================
        do_store(2'b00, 32'h15, 32'h00000080);
        do_load(3'b011, 32'h15);
        check(32'h00000080, "LBU test after SB");

        //=====================
        // SH + LH / LHU
        //=====================
        do_store(2'b01, 32'h20, 32'h00008001);
        do_load(3'b001, 32'h20);
        check(32'hFFFF8001, "LH sign extend test");
        do_load(3'b100, 32'h20);
        check(32'h00008001, "LHU zero extend test");

        $display("\n======== DATA MEMORY TEST COMPLETE ========\n");
        $finish;
    end

endmodule


