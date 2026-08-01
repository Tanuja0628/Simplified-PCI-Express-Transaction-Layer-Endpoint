`timescale 1ns / 1ps
// Regenerated source: minimal configuration-space register block.
// Minimal PCIe-like configuration space. Addresses are byte offsets.
module config_space (
    input  logic        clk,
    input  logic        rst,
    input  logic        we,
    input  logic        re,
    input  logic [11:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);
    logic [15:0] command_reg;
    logic [31:0] bar0_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            command_reg <= 16'h0000;
            bar0_reg    <= 32'h0000_1000;
            read_data   <= 32'h0000_0000;
        end else begin
            if (we) begin
                case (address[11:2])
                    10'h001: command_reg <= write_data[15:0]; // 0x004 Command
                    10'h004: bar0_reg    <= {write_data[31:4], 4'b0000}; // 0x010 BAR0
                    default: ; // read-only or unimplemented register
                endcase
            end
            if (re) begin
                case (address[11:2])
                    10'h000: read_data <= 32'h5678_1234;              // Device / Vendor ID
                    10'h001: read_data <= {16'h0010, command_reg};    // Status / Command
                    10'h002: read_data <= 32'h0108_0001;              // Class / Revision
                    10'h004: read_data <= bar0_reg;                   // BAR0
                    default:  read_data <= 32'h0000_0000;
                endcase
            end
        end
    end
endmodule
