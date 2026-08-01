`timescale 1ns / 1ps
// Regenerated source: simplified PCIe TLP generator.
// Simplified teaching TLP format (not the PCIe wire encoding):
// [95:93] type, [92:85] tag, [84:69] address, [68:37] payload data,
// [36:32] length in DW, [31:16] requester ID, [15:0] reserved.
module tlp_generator (
    input  logic        request_valid,
    input  logic [2:0]  request_type,
    input  logic [15:0] request_address,
    input  logic [31:0] request_data,
    input  logic [7:0]  request_tag,
    output logic        tlp_valid,
    output logic [95:0] tlp_word
);
    always_comb begin
        tlp_valid       = request_valid;
        tlp_word        = '0;
        tlp_word[95:93] = request_type;
        tlp_word[92:85] = request_tag;
        tlp_word[84:69] = request_address;
        tlp_word[68:37] = request_data;
        tlp_word[36:32] = 5'd1;       // one 32-bit data word
        tlp_word[31:16] = 16'h0000;   // simplified requester ID
    end
endmodule
