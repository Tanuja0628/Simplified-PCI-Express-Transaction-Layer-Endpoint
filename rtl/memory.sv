`timescale 1ns / 1ps
// Regenerated source: internal endpoint memory.
//=========================================================
// File Name : memory.sv
// Description : Internal Endpoint Memory
//=========================================================

module memory
(
    input  logic        clk,
    input  logic        rst,

    input  logic        we,
    input  logic        mem_re,

    input  logic [7:0]  address,
    input  logic [31:0] write_data,

    output logic [31:0] read_data
);

    //------------------------------------------------------
    // Internal Memory
    //------------------------------------------------------

    logic [31:0] mem [0:255];

    integer i;

    //------------------------------------------------------
    // Memory Operation
    //------------------------------------------------------

    always_ff @(posedge clk)
    begin

        if(rst)
        begin

            for(i=0;i<256;i=i+1)
                mem[i] <= 32'd0;

            read_data <= 32'd0;

        end

        else
        begin

            //-----------------------------
            // Write Operation
            //-----------------------------

            if(we)
                mem[address] <= write_data;

            //-----------------------------
            // Read Operation
            //-----------------------------

            if(mem_re)
                read_data <= mem[address];

        end

    end

endmodule
