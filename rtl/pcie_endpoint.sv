`timescale 1ns / 1ps
// Regenerated source: top-level educational PCIe endpoint.
// Educational PCIe endpoint: simplified TLP generation/parsing + config space.
module pcie_endpoint (
    input logic clk, rst, valid,
    input logic [2:0] packet_type,
    input logic [15:0] address,
    input logic [31:0] data,
    input logic [7:0] tag,
    output logic req_ready,
    output logic cpl_valid,
    output logic [2:0] cpl_type,
    output logic [15:0] cpl_address,
    output logic [31:0] cpl_data,
    output logic [7:0] cpl_tag
);
    logic tlp_valid, parsed_valid, parsed_supported;
    logic [95:0] tlp_word;
    logic [2:0] parsed_type;
    logic [15:0] parsed_address;
    logic [31:0] parsed_data, mem_rdata, cfg_rdata, write_data, response_data;
    logic [7:0] parsed_tag, response_tag, mem_addr;
    logic [11:0] cfg_addr;
    logic mem_we, mem_re, cfg_we, cfg_re, send_completion;
    logic [15:0] response_address;

    tlp_generator GEN (
    .request_valid(valid), 
    .request_type(packet_type), 
    .request_address(address),
    .request_data(data), 
    .request_tag(tag), 
    .tlp_valid(tlp_valid), 
    .tlp_word(tlp_word));

    packet_decoder PARSER (
    .tlp_valid_in(tlp_valid), 
    .tlp_word(tlp_word), 
    .packet_valid(parsed_valid),
    .packet_supported(parsed_supported), 
    .tlp_type(parsed_type), 
    .address(parsed_address),
    .data(parsed_data), 
    .tag(parsed_tag));


    rw_controller CTRL (
    .clk, 
    .rst, 
    .valid(parsed_valid), 
    .supported(parsed_supported), 
    .tlp_type(parsed_type),
    .address(parsed_address), 
    .data(parsed_data), 
    .tag(parsed_tag), 
    .mem_rdata, 
    .cfg_rdata,
    .ready(req_ready), 
    .mem_we, 
    .mem_re, 
    .cfg_we, 
    .cfg_re, 
    .mem_addr, 
    .cfg_addr, 
    .write_data,
    .send_completion, 
    .completion_address(response_address), 
    .completion_data(response_data), 
    .completion_tag(response_tag));

    memory MEM (
    .clk, 
    .rst, 
    .we(mem_we), 
    .mem_re, 
    .address(mem_addr), 
    .write_data, 
    .read_data(mem_rdata));

    config_space CFG (
    .clk, 
    .rst, 
    .we(cfg_we), 
    .re(cfg_re), 
    .address(cfg_addr), 
    .write_data, 
    .read_data(cfg_rdata));

    completion_generator CPL (
    .send_completion, 
    .address(response_address), 
    .data(response_data), 
    .tag(response_tag),
    .cpl_valid, 
    .cpl_type, 
    .cpl_address, 
    .cpl_data, 
    .cpl_tag);
    
endmodule
