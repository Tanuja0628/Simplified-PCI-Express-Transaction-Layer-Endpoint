`timescale 1ns / 1ps
// Regenerated source: simplified PCIe TLP parser.
// Parses the simplified 96-bit teaching TLP produced by tlp_generator.
module packet_decoder (
    input  logic        tlp_valid_in,
    input  logic [95:0] tlp_word,
    output logic        packet_valid,
    output logic        packet_supported,
    output logic [2:0]  tlp_type,
    output logic [15:0] address,
    output logic [31:0] data,
    output logic [7:0]  tag
);
    always_comb begin
        packet_valid     = tlp_valid_in;
        tlp_type         = tlp_word[95:93];
        tag              = tlp_word[92:85];
        address          = tlp_word[84:69];
        data             = tlp_word[68:37];
        // Endpoint accepts Memory and Configuration Read/Write only.
        packet_supported = (tlp_type <= 3'b011) && (tlp_word[36:32] == 5'd1);
    end
endmodule
