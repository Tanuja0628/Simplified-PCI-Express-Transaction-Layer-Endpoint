`timescale 1ns / 1ps
// Regenerated source: transaction routing controller.
// Routes parsed TLPs. The full request is captured on acceptance.
module rw_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic        valid,
    input  logic        supported,
    input  logic [2:0]  tlp_type,
    input  logic [15:0] address,
    input  logic [31:0] data,
    input  logic [7:0]  tag,
    input  logic [31:0] mem_rdata,
    input  logic [31:0] cfg_rdata,
    output logic        ready,
    output logic        mem_we,
    output logic        mem_re,
    output logic        cfg_we,
    output logic        cfg_re,
    output logic [7:0]  mem_addr,
    output logic [11:0] cfg_addr,
    output logic [31:0] write_data,
    output logic        send_completion,
    output logic [15:0] completion_address,
    output logic [31:0] completion_data,
    output logic [7:0]  completion_tag
);
    localparam logic [2:0] MEM_WRITE = 3'b000, MEM_READ = 3'b001,
                           CFG_WRITE = 3'b010, CFG_READ = 3'b011;
    typedef enum logic [2:0] {IDLE, EXECUTE, READ_WAIT, RESPOND} state_t;
    state_t state, next_state;
    logic [2:0]  saved_type;
    logic [15:0] saved_address;
    logic [31:0] saved_data, saved_read_data;
    logic [7:0]  saved_tag;

    always_ff @(posedge clk) begin
        if (rst) begin
            state           <= IDLE;
            saved_type      <= '0;
            saved_address   <= '0;
            saved_data      <= '0;
            saved_tag       <= '0;
            saved_read_data <= '0;
        end else begin
            state <= next_state;
            if (state == IDLE && valid && supported) begin
                saved_type    <= tlp_type;
                saved_address <= address;
                saved_data    <= data;
                saved_tag     <= tag;
            end
            if (state == READ_WAIT)
                saved_read_data <= (saved_type == MEM_READ) ? mem_rdata : cfg_rdata;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:      if (valid && supported) next_state = EXECUTE;
            EXECUTE:   if ((saved_type == MEM_READ) || (saved_type == CFG_READ)) next_state = READ_WAIT;
                       else next_state = IDLE;
            READ_WAIT: next_state = RESPOND;
            RESPOND:   next_state = IDLE;
            default:   next_state = IDLE;
        endcase
    end

    always_comb begin
        mem_we = 1'b0; mem_re = 1'b0; cfg_we = 1'b0; cfg_re = 1'b0;
        mem_addr = saved_address[7:0];
        cfg_addr = saved_address[11:0];
        write_data = saved_data;
        send_completion = (state == RESPOND);
        ready = (state == IDLE);
        completion_address = saved_address;
        completion_data    = saved_read_data;
        completion_tag     = saved_tag;
        if (state == EXECUTE) begin
            case (saved_type)
                MEM_WRITE: mem_we = 1'b1;
                MEM_READ:  mem_re = 1'b1;
                CFG_WRITE: cfg_we = 1'b1;
                CFG_READ:  cfg_re = 1'b1;
                default: ;
            endcase
        end
    end
endmodule
