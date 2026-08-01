`timescale 1ns / 1ps
// Regenerated source: completion-with-data output block.
module completion_generator (
    input logic send_completion,
    input logic [15:0] address,
    input logic [31:0] data,
    input logic [7:0] tag,
    output logic cpl_valid,
    output logic [2:0] cpl_type,
    output logic [15:0] cpl_address,
    output logic [31:0] cpl_data,
    output logic [7:0] cpl_tag
);
    always_comb begin
        cpl_valid = send_completion;
        cpl_type = 3'b100; // Completion with Data in this simplified format
        cpl_address = address;
        cpl_data = data;
        cpl_tag = tag;
    end
endmodule
