// EDA Playground Testbench pane bundle for Cadence Xcelium.
// Generated from tb/ layered verification sources.
`define PCIE_EDAPLAYGROUND

// ============================================================
// Source: tb\interface\pcie_tl_if.sv
// ============================================================
`timescale 1ns / 1ps

interface pcie_tl_if(input logic clk);
    timeunit 1ns;
    timeprecision 1ps;

    logic        rst;
    logic        valid;
    logic [2:0]  packet_type;
    logic [15:0] address;
    logic [31:0] data;
    logic [7:0]  tag;

    logic        req_ready;
    logic        cpl_valid;
    logic [2:0]  cpl_type;
    logic [15:0] cpl_address;
    logic [31:0] cpl_data;
    logic [7:0]  cpl_tag;

    // Driver updates outputs away from the active sampling edge.
    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output rst;
        output valid;
        output packet_type;
        output address;
        output data;
        output tag;
        input  req_ready;
        input  cpl_valid;
        input  cpl_type;
        input  cpl_address;
        input  cpl_data;
        input  cpl_tag;
    endclocking

    // Monitor samples the bus as it existed just before the active edge.
    // This is important because req_ready changes when the DUT FSM updates.
    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input rst;
        input valid;
        input packet_type;
        input address;
        input data;
        input tag;
        input req_ready;
        input cpl_valid;
        input cpl_type;
        input cpl_address;
        input cpl_data;
        input cpl_tag;
    endclocking

    modport dut_mp (
        input  clk,
        input  rst,
        input  valid,
        input  packet_type,
        input  address,
        input  data,
        input  tag,
        output req_ready,
        output cpl_valid,
        output cpl_type,
        output cpl_address,
        output cpl_data,
        output cpl_tag
    );

    modport drv_mp (clocking drv_cb, input clk);
    modport mon_mp (clocking mon_cb, input clk);

endinterface

// ============================================================
// Source: tb\pcie_tl_pkg.sv
// ============================================================
`timescale 1ns / 1ps

package pcie_tl_pkg;
    timeunit 1ns;
    timeprecision 1ps;

    typedef enum logic [2:0] {
        PCIE_MEM_WRITE = 3'b000,
        PCIE_MEM_READ  = 3'b001,
        PCIE_CFG_WRITE = 3'b010,
        PCIE_CFG_READ  = 3'b011,
        PCIE_CPLD      = 3'b100
    } pcie_packet_type_e;

    typedef enum int {
        PCIE_DATA_ZERO,
        PCIE_DATA_ALL_ONES,
        PCIE_DATA_ALT_AA55,
        PCIE_DATA_ALT_55AA,
        PCIE_DATA_RANDOM
    } pcie_data_pattern_e;

    typedef enum int {
        PCIE_ADDR_MEM_DIRECT,
        PCIE_ADDR_MEM_ALIASED,
        PCIE_ADDR_CFG_ID,
        PCIE_ADDR_CFG_COMMAND,
        PCIE_ADDR_CFG_CLASS,
        PCIE_ADDR_CFG_BAR0,
        PCIE_ADDR_CFG_UNIMPLEMENTED,
        PCIE_ADDR_CFG_ALIASED,
        PCIE_ADDR_UNSUPPORTED
    } pcie_addr_range_e;

    typedef enum int {
        PCIE_DIR_READ,
        PCIE_DIR_WRITE,
        PCIE_DIR_UNSUPPORTED
    } pcie_rw_e;

    localparam bit [2:0] PCIE_COMPLETION_TYPE = 3'b100;
    localparam bit [31:0] PCIE_VENDOR_DEVICE_ID_RESET = 32'h5678_1234;
    localparam bit [15:0] PCIE_VENDOR_ID_RESET = 16'h1234;
    localparam bit [15:0] PCIE_DEVICE_ID_RESET = 16'h5678;
    localparam bit [15:0] PCIE_COMMAND_RESET = 16'h0000;
    localparam bit [15:0] PCIE_STATUS_RESET = 16'h0010;
    localparam bit [31:0] PCIE_STATUS_COMMAND_RESET = 32'h0010_0000;
    localparam bit [31:0] PCIE_CLASS_REVISION_RESET = 32'h0108_0001;
    localparam bit [31:0] PCIE_BAR0_RESET = 32'h0000_1000;


// ============================================================
// Source: tb\transaction\pcie_tl_transaction.svh
// ============================================================
class pcie_tl_transaction;
    string name;

    rand bit [2:0]            packet_type;
    rand bit [15:0]           address;
    rand bit [31:0]           data;
    rand bit [7:0]            tag;
    rand int unsigned         idle_cycles;
    rand int unsigned         valid_cycles;
    rand pcie_data_pattern_e  data_pattern;

    bit legal = 1'b1;
    bit drive_when_busy = 1'b0;
    bit valid_glitch = 1'b0;
    bit hold_valid_until_ready = 1'b0;

    bit accepted;
    bit req_ready_sampled;
    bit is_completion;
    bit expect_completion;
    bit [2:0]  cpl_type;
    bit [15:0] cpl_address;
    bit [31:0] cpl_data;
    bit [7:0]  cpl_tag;
    time observed_time;

    constraint c_packet_type {
        if (legal) {
            packet_type inside {
                PCIE_MEM_WRITE,
                PCIE_MEM_READ,
                PCIE_CFG_WRITE,
                PCIE_CFG_READ
            };
        } else {
            !(packet_type inside {
                PCIE_MEM_WRITE,
                PCIE_MEM_READ,
                PCIE_CFG_WRITE,
                PCIE_CFG_READ
            });
        }
    }

    constraint c_address_alignment {
        if (packet_type inside {PCIE_CFG_WRITE, PCIE_CFG_READ}) {
            address[1:0] == 2'b00;
        }
    }

    constraint c_address_distribution {
        if (packet_type inside {PCIE_MEM_WRITE, PCIE_MEM_READ}) {
            address dist {
                [16'h0000:16'h00ff] :/ 70,
                [16'h0100:16'hffff] :/ 30
            };
        }
        if (packet_type inside {PCIE_CFG_WRITE, PCIE_CFG_READ}) {
            address dist {
                16'h0000              :/ 10,
                16'h0004              :/ 20,
                16'h0008              :/ 10,
                16'h0010              :/ 20,
                [16'h0014:16'h0ffc]   :/ 25,
                [16'h1000:16'hffff]   :/ 15
            };
        }
    }

    constraint c_data_pattern {
        solve data_pattern before data;
        if (data_pattern == PCIE_DATA_ZERO) {
            data == 32'h0000_0000;
        } else if (data_pattern == PCIE_DATA_ALL_ONES) {
            data == 32'hffff_ffff;
        } else if (data_pattern == PCIE_DATA_ALT_AA55) {
            data == 32'haaaa_5555;
        } else if (data_pattern == PCIE_DATA_ALT_55AA) {
            data == 32'h5555_aaaa;
        }
    }

    constraint c_idle_and_valid_width {
        idle_cycles inside {[0:20]};
        valid_cycles inside {[1:4]};
    }

    function new(string name = "pcie_tl_transaction");
        this.name = name;
        packet_type = PCIE_MEM_WRITE;
        address = '0;
        data = '0;
        tag = '0;
        idle_cycles = 0;
        valid_cycles = 1;
        data_pattern = PCIE_DATA_RANDOM;
    endfunction

    function bit is_supported();
        return packet_type inside {
            PCIE_MEM_WRITE,
            PCIE_MEM_READ,
            PCIE_CFG_WRITE,
            PCIE_CFG_READ
        };
    endfunction

    function bit is_read();
        return (packet_type == PCIE_MEM_READ) || (packet_type == PCIE_CFG_READ);
    endfunction

    function bit is_write();
        return (packet_type == PCIE_MEM_WRITE) || (packet_type == PCIE_CFG_WRITE);
    endfunction

    function bit is_memory();
        return (packet_type == PCIE_MEM_WRITE) || (packet_type == PCIE_MEM_READ);
    endfunction

    function bit is_config();
        return (packet_type == PCIE_CFG_WRITE) || (packet_type == PCIE_CFG_READ);
    endfunction

    function pcie_rw_e rw_kind();
        if (is_read()) begin
            return PCIE_DIR_READ;
        end
        if (is_write()) begin
            return PCIE_DIR_WRITE;
        end
        return PCIE_DIR_UNSUPPORTED;
    endfunction

    function pcie_addr_range_e addr_range();
        if (is_memory()) begin
            return (address <= 16'h00ff) ? PCIE_ADDR_MEM_DIRECT : PCIE_ADDR_MEM_ALIASED;
        end

        if (is_config()) begin
            if (address[15:12] != 4'h0) begin
                return PCIE_ADDR_CFG_ALIASED;
            end
            unique case (address[11:2])
                10'h000: return PCIE_ADDR_CFG_ID;
                10'h001: return PCIE_ADDR_CFG_COMMAND;
                10'h002: return PCIE_ADDR_CFG_CLASS;
                10'h004: return PCIE_ADDR_CFG_BAR0;
                default: return PCIE_ADDR_CFG_UNIMPLEMENTED;
            endcase
        end

        return PCIE_ADDR_UNSUPPORTED;
    endfunction

    static function pcie_data_pattern_e classify_data(bit [31:0] value);
        if (value == 32'h0000_0000) begin
            return PCIE_DATA_ZERO;
        end
        if (value == 32'hffff_ffff) begin
            return PCIE_DATA_ALL_ONES;
        end
        if (value == 32'haaaa_5555) begin
            return PCIE_DATA_ALT_AA55;
        end
        if (value == 32'h5555_aaaa) begin
            return PCIE_DATA_ALT_55AA;
        end
        return PCIE_DATA_RANDOM;
    endfunction

    function pcie_data_pattern_e observed_data_pattern();
        return classify_data(data);
    endfunction

    static function string type_to_string(bit [2:0] typ);
        case (typ)
            PCIE_MEM_WRITE: return "MEM_WRITE";
            PCIE_MEM_READ:  return "MEM_READ";
            PCIE_CFG_WRITE: return "CFG_WRITE";
            PCIE_CFG_READ:  return "CFG_READ";
            PCIE_CPLD:      return "CPLD";
            default:        return $sformatf("UNSUPPORTED_%0d", typ);
        endcase
    endfunction

    function string type_name();
        return type_to_string(packet_type);
    endfunction

    function pcie_tl_transaction clone();
        pcie_tl_transaction copy = new({name, "_clone"});
        copy.packet_type = packet_type;
        copy.address = address;
        copy.data = data;
        copy.tag = tag;
        copy.idle_cycles = idle_cycles;
        copy.valid_cycles = valid_cycles;
        copy.data_pattern = data_pattern;
        copy.legal = legal;
        copy.drive_when_busy = drive_when_busy;
        copy.valid_glitch = valid_glitch;
        copy.hold_valid_until_ready = hold_valid_until_ready;
        copy.accepted = accepted;
        copy.req_ready_sampled = req_ready_sampled;
        copy.is_completion = is_completion;
        copy.expect_completion = expect_completion;
        copy.cpl_type = cpl_type;
        copy.cpl_address = cpl_address;
        copy.cpl_data = cpl_data;
        copy.cpl_tag = cpl_tag;
        copy.observed_time = observed_time;
        return copy;
    endfunction

    function string sprint();
        if (is_completion) begin
            return $sformatf(
                "%s completion type=%0b addr=0x%04h data=0x%08h tag=0x%02h time=%0t",
                name, cpl_type, cpl_address, cpl_data, cpl_tag, observed_time
            );
        end

        return $sformatf(
            "%s req type=%s addr=0x%04h data=0x%08h tag=0x%02h accepted=%0b ready=%0b idle=%0d valid_cycles=%0d",
            name,
            type_name(),
            address,
            data,
            tag,
            accepted,
            req_ready_sampled,
            idle_cycles,
            valid_cycles
        );
    endfunction
endclass

// ============================================================
// Source: tb\scoreboard\pcie_tl_reg_model.svh
// ============================================================
class pcie_tl_reg_model;
    string name;

    bit [15:0] vendor_id;
    bit [15:0] device_id;
    bit [15:0] command_reg;
    bit [15:0] status_reg;
    bit [31:0] class_revision_reg;
    bit [31:0] bar0_reg;

    function new(string name = "pcie_tl_reg_model");
        this.name = name;
        reset();
    endfunction

    function void reset();
        vendor_id = PCIE_VENDOR_ID_RESET;
        device_id = PCIE_DEVICE_ID_RESET;
        command_reg = PCIE_COMMAND_RESET;
        status_reg = PCIE_STATUS_RESET;
        class_revision_reg = PCIE_CLASS_REVISION_RESET;
        bar0_reg = PCIE_BAR0_RESET;
    endfunction

    // Mirrors the config_space RTL. The address is a byte offset and the
    // DUT uses address[11:2] to select 32-bit registers.
    function void write(bit [15:0] address, bit [31:0] write_data);
        unique case (address[11:2])
            10'h001: command_reg = write_data[15:0];
            10'h004: bar0_reg = {write_data[31:4], 4'b0000};
            default: ;
        endcase
    endfunction

    function bit [31:0] read(bit [15:0] address);
        unique case (address[11:2])
            10'h000: return {device_id, vendor_id};
            10'h001: return {status_reg, command_reg};
            10'h002: return class_revision_reg;
            10'h004: return bar0_reg;
            default: return 32'h0000_0000;
        endcase
    endfunction

    function bit check_reset_mirror();
        return (vendor_id == PCIE_VENDOR_ID_RESET) &&
               (device_id == PCIE_DEVICE_ID_RESET) &&
               (command_reg == PCIE_COMMAND_RESET) &&
               (status_reg == PCIE_STATUS_RESET) &&
               (class_revision_reg == PCIE_CLASS_REVISION_RESET) &&
               (bar0_reg == PCIE_BAR0_RESET);
    endfunction

    function string sprint();
        return $sformatf(
            "%s vendor=0x%04h device=0x%04h command=0x%04h status=0x%04h class_rev=0x%08h bar0=0x%08h",
            name,
            vendor_id,
            device_id,
            command_reg,
            status_reg,
            class_revision_reg,
            bar0_reg
        );
    endfunction
endclass

// ============================================================
// Source: tb\generator\pcie_tl_generator.svh
// ============================================================
class pcie_tl_generator;
    string name;
    mailbox #(pcie_tl_transaction) out_mb;
    int unsigned generated_count;

    function new(mailbox #(pcie_tl_transaction) out_mb = null,
                 string name = "pcie_tl_generator");
        this.name = name;
        this.out_mb = out_mb;
        generated_count = 0;
    endfunction

    task send(pcie_tl_transaction tr);
        if (out_mb == null) begin
            $fatal(1, "[%s] Generator output mailbox is not connected", name);
        end
        generated_count++;
        out_mb.put(tr.clone());
    endtask

    function pcie_tl_transaction create_directed(bit [2:0] typ,
                                                 bit [15:0] addr,
                                                 bit [31:0] wdata,
                                                 bit [7:0] req_tag,
                                                 int unsigned idle = 0);
        pcie_tl_transaction tr = new($sformatf("directed_%0d", generated_count));
        tr.packet_type = typ;
        tr.address = addr;
        tr.data = wdata;
        tr.tag = req_tag;
        tr.idle_cycles = idle;
        tr.valid_cycles = 1;
        tr.data_pattern = pcie_tl_transaction::classify_data(wdata);
        tr.legal = (typ inside {PCIE_MEM_WRITE, PCIE_MEM_READ, PCIE_CFG_WRITE, PCIE_CFG_READ});
        return tr;
    endfunction

    task send_directed(bit [2:0] typ,
                       bit [15:0] addr,
                       bit [31:0] wdata,
                       bit [7:0] req_tag,
                       int unsigned idle = 0);
        pcie_tl_transaction tr = create_directed(typ, addr, wdata, req_tag, idle);
        send(tr);
    endtask

    task send_burst(bit [2:0] typ,
                    bit [15:0] base_addr,
                    int unsigned count,
                    int unsigned stride = 4,
                    bit [31:0] start_data = 32'h0,
                    bit [7:0] start_tag = 8'h0,
                    int unsigned idle = 0);
        for (int unsigned i = 0; i < count; i++) begin
            bit [15:0] burst_addr;
            bit [7:0]  burst_tag;

            burst_addr = base_addr + (i * stride);
            burst_tag = start_tag + i;
            send_directed(
                typ,
                burst_addr,
                start_data + i,
                burst_tag,
                idle
            );
        end
    endtask

    task send_back_to_back(pcie_tl_transaction tr_q[$]);
        foreach (tr_q[i]) begin
            tr_q[i].idle_cycles = 0;
            send(tr_q[i]);
        end
    endtask

    function bit [2:0] choose_legal_type(int unsigned mem_write_weight = 25,
                                         int unsigned mem_read_weight = 25,
                                         int unsigned cfg_write_weight = 25,
                                         int unsigned cfg_read_weight = 25);
        int unsigned total;
        int unsigned pick;

        total = mem_write_weight + mem_read_weight + cfg_write_weight + cfg_read_weight;
        if (total == 0) begin
            return PCIE_MEM_WRITE;
        end

        pick = $urandom_range(1, total);
        if (pick <= mem_write_weight) begin
            return PCIE_MEM_WRITE;
        end
        pick -= mem_write_weight;

        if (pick <= mem_read_weight) begin
            return PCIE_MEM_READ;
        end
        pick -= mem_read_weight;

        if (pick <= cfg_write_weight) begin
            return PCIE_CFG_WRITE;
        end

        return PCIE_CFG_READ;
    endfunction

    task send_random(int unsigned count,
                     int unsigned mem_write_weight = 25,
                     int unsigned mem_read_weight = 25,
                     int unsigned cfg_write_weight = 25,
                     int unsigned cfg_read_weight = 25,
                     int unsigned max_idle = 10,
                     int unsigned unsupported_pct = 0);
        pcie_tl_transaction tr;
        bit [2:0] selected_type;

        for (int unsigned i = 0; i < count; i++) begin
            tr = new($sformatf("random_%0d", i));
            if ((unsupported_pct > 0) && ($urandom_range(0, 99) < unsupported_pct)) begin
                tr.legal = 1'b0;
                assert(tr.randomize() with {
                    idle_cycles <= max_idle;
                    data_pattern dist {
                        PCIE_DATA_ZERO     := 5,
                        PCIE_DATA_ALL_ONES := 5,
                        PCIE_DATA_ALT_AA55 := 10,
                        PCIE_DATA_ALT_55AA := 10,
                        PCIE_DATA_RANDOM   := 70
                    };
                }) else $fatal(1, "[%s] Unsupported randomization failed", name);
            end else begin
                selected_type = choose_legal_type(
                    mem_write_weight,
                    mem_read_weight,
                    cfg_write_weight,
                    cfg_read_weight
                );
                tr.legal = 1'b1;
                assert(tr.randomize() with {
                    packet_type == selected_type;
                    idle_cycles <= max_idle;
                    data_pattern dist {
                        PCIE_DATA_ZERO     := 5,
                        PCIE_DATA_ALL_ONES := 5,
                        PCIE_DATA_ALT_AA55 := 10,
                        PCIE_DATA_ALT_55AA := 10,
                        PCIE_DATA_RANDOM   := 70
                    };
                }) else $fatal(1, "[%s] Legal randomization failed", name);
            end
            send(tr);
        end
    endtask

    task send_unsupported(int unsigned count);
        pcie_tl_transaction tr;

        for (int unsigned i = 0; i < count; i++) begin
            tr = new($sformatf("unsupported_%0d", i));
            tr.legal = 1'b0;
            assert(tr.randomize() with {
                packet_type inside {[3'b100:3'b111]};
                idle_cycles inside {[0:4]};
            }) else $fatal(1, "[%s] Unsupported transaction randomization failed", name);
            send(tr);
        end
    endtask

    task send_busy_violation(bit [2:0] typ = PCIE_MEM_READ,
                             bit [15:0] addr = 16'h0000,
                             bit [31:0] wdata = 32'h0,
                             bit [7:0] req_tag = 8'h00);
        pcie_tl_transaction tr = create_directed(typ, addr, wdata, req_tag, 0);
        tr.drive_when_busy = 1'b1;
        tr.valid_cycles = 1;
        send(tr);
    endtask

    task send_valid_glitch(bit [2:0] typ,
                           bit [15:0] addr,
                           bit [31:0] wdata,
                           bit [7:0] req_tag);
        pcie_tl_transaction tr = create_directed(typ, addr, wdata, req_tag, 0);
        tr.valid_glitch = 1'b1;
        send(tr);
    endtask

    task send_repeated_tag(int unsigned count,
                           bit [7:0] repeated_tag,
                           bit [2:0] typ = PCIE_MEM_READ,
                           bit [15:0] base_addr = 16'h0000);
        for (int unsigned i = 0; i < count; i++) begin
            bit [15:0] addr;
            addr = base_addr + i;
            send_directed(typ, addr, 32'h0, repeated_tag, 0);
        end
    endtask
endclass

// ============================================================
// Source: tb\driver\pcie_tl_driver.svh
// ============================================================
class pcie_tl_driver;
    string name;
    virtual pcie_tl_if vif;
    mailbox #(pcie_tl_transaction) in_mb;

    int unsigned random_delay_min;
    int unsigned random_delay_max;
    int unsigned driven_count;
    bit busy;

    function new(virtual pcie_tl_if vif,
                 mailbox #(pcie_tl_transaction) in_mb,
                 string name = "pcie_tl_driver");
        this.name = name;
        this.vif = vif;
        this.in_mb = in_mb;
        random_delay_min = 0;
        random_delay_max = 0;
        driven_count = 0;
        busy = 1'b0;
    endfunction

    task reset_signals();
        vif.valid <= 1'b0;
        vif.packet_type <= '0;
        vif.address <= '0;
        vif.data <= '0;
        vif.tag <= '0;
    endtask

    task wait_not_in_reset();
        while (vif.rst) begin
            @(posedge vif.clk);
        end
    endtask

    task run();
        pcie_tl_transaction tr;

        reset_signals();
        forever begin
            in_mb.get(tr);
            busy = 1'b1;
            drive_transaction(tr);
            driven_count++;
            busy = 1'b0;
        end
    endtask

    task drive_payload(pcie_tl_transaction tr);
        vif.packet_type <= tr.packet_type;
        vif.address <= tr.address;
        vif.data <= tr.data;
        vif.tag <= tr.tag;
    endtask

    task drive_transaction(pcie_tl_transaction tr);
        int unsigned extra_delay;
        int unsigned busy_guard;

        wait_not_in_reset();

        extra_delay = 0;
        if (random_delay_max >= random_delay_min) begin
            extra_delay = $urandom_range(random_delay_min, random_delay_max);
        end
        repeat (tr.idle_cycles + extra_delay) begin
            @(posedge vif.clk);
        end

        if (tr.valid_glitch) begin
            @(negedge vif.clk);
            drive_payload(tr);
            vif.valid <= 1'b1;
            #1ns;
            vif.valid <= 1'b0;
            return;
        end

        if (tr.drive_when_busy) begin
            busy_guard = 0;
            while (vif.req_ready && !vif.rst && (busy_guard < 32)) begin
                @(posedge vif.clk);
                busy_guard++;
            end
        end else begin
            while ((!vif.req_ready) || vif.rst) begin
                @(posedge vif.clk);
            end
        end

        @(negedge vif.clk);
        drive_payload(tr);
        vif.valid <= 1'b1;

        if (tr.hold_valid_until_ready) begin
            @(posedge vif.clk);
            while ((!vif.req_ready) && !vif.rst) begin
                @(posedge vif.clk);
            end
            @(posedge vif.clk);
            @(negedge vif.clk);
        end else begin
            repeat (tr.valid_cycles) begin
                @(negedge vif.clk);
            end
        end

        vif.valid <= 1'b0;
    endtask
endclass

// ============================================================
// Source: tb\monitor\pcie_tl_monitor.svh
// ============================================================
class pcie_tl_monitor;
    string name;
    virtual pcie_tl_if vif;

    mailbox #(pcie_tl_transaction) req_sb_mb;
    mailbox #(pcie_tl_transaction) cpl_sb_mb;
    mailbox #(pcie_tl_transaction) req_cov_mb;
    mailbox #(pcie_tl_transaction) cpl_cov_mb;

    int unsigned observed_request_count;
    int unsigned observed_completion_count;

    function new(virtual pcie_tl_if vif,
                 mailbox #(pcie_tl_transaction) req_sb_mb,
                 mailbox #(pcie_tl_transaction) cpl_sb_mb,
                 mailbox #(pcie_tl_transaction) req_cov_mb,
                 mailbox #(pcie_tl_transaction) cpl_cov_mb,
                 string name = "pcie_tl_monitor");
        this.name = name;
        this.vif = vif;
        this.req_sb_mb = req_sb_mb;
        this.cpl_sb_mb = cpl_sb_mb;
        this.req_cov_mb = req_cov_mb;
        this.cpl_cov_mb = cpl_cov_mb;
        observed_request_count = 0;
        observed_completion_count = 0;
    endfunction

    task run();
        fork
            request_loop();
            completion_loop();
        join_none
    endtask

    task request_loop();
        pcie_tl_transaction tr;

        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst && vif.mon_cb.valid) begin
                tr = new($sformatf("mon_req_%0d", observed_request_count));
                tr.packet_type = vif.mon_cb.packet_type;
                tr.address = vif.mon_cb.address;
                tr.data = vif.mon_cb.data;
                tr.tag = vif.mon_cb.tag;
                tr.req_ready_sampled = vif.mon_cb.req_ready;
                tr.accepted = vif.mon_cb.req_ready && tr.is_supported();
                tr.expect_completion = tr.accepted && tr.is_read();
                tr.observed_time = $time;
                observed_request_count++;

                req_sb_mb.put(tr.clone());
                req_cov_mb.put(tr.clone());
            end
        end
    endtask

    task completion_loop();
        pcie_tl_transaction tr;

        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.rst && vif.mon_cb.cpl_valid) begin
                tr = new($sformatf("mon_cpl_%0d", observed_completion_count));
                tr.is_completion = 1'b1;
                tr.packet_type = PCIE_CPLD;
                tr.address = vif.mon_cb.cpl_address;
                tr.data = vif.mon_cb.cpl_data;
                tr.tag = vif.mon_cb.cpl_tag;
                tr.cpl_type = vif.mon_cb.cpl_type;
                tr.cpl_address = vif.mon_cb.cpl_address;
                tr.cpl_data = vif.mon_cb.cpl_data;
                tr.cpl_tag = vif.mon_cb.cpl_tag;
                tr.observed_time = $time;
                observed_completion_count++;

                cpl_sb_mb.put(tr.clone());
                cpl_cov_mb.put(tr.clone());
            end
        end
    endtask
endclass

// ============================================================
// Source: tb\scoreboard\pcie_tl_scoreboard.svh
// ============================================================
class pcie_tl_scoreboard;
    string name;
    virtual pcie_tl_if vif;

    mailbox #(pcie_tl_transaction) req_mb;
    mailbox #(pcie_tl_transaction) cpl_mb;

    bit [31:0] mem_model [256];
    pcie_tl_reg_model ral_model;
    pcie_tl_transaction expected_cpl_q[$];

    int unsigned request_count;
    int unsigned accepted_count;
    int unsigned ignored_busy_count;
    int unsigned unsupported_count;
    int unsigned completion_count;
    int unsigned compare_pass_count;
    int unsigned error_count;
    int unsigned reset_count;

    function new(virtual pcie_tl_if vif,
                 mailbox #(pcie_tl_transaction) req_mb,
                 mailbox #(pcie_tl_transaction) cpl_mb,
                 string name = "pcie_tl_scoreboard");
        this.name = name;
        this.vif = vif;
        this.req_mb = req_mb;
        this.cpl_mb = cpl_mb;
        ral_model = new("pcie_cfg_ral");
        reset_model();
    endfunction

    function void reset_model();
        foreach (mem_model[i]) begin
            mem_model[i] = 32'h0000_0000;
        end
        ral_model.reset();
        expected_cpl_q.delete();
    endfunction

    task run();
        fork
            request_loop();
            completion_loop();
            reset_watch_loop();
        join_none
    endtask

    task request_loop();
        pcie_tl_transaction req;

        forever begin
            req_mb.get(req);
            request_count++;

            if (!req.accepted) begin
                if (!req.req_ready_sampled) begin
                    ignored_busy_count++;
                end
                if (!req.is_supported()) begin
                    unsupported_count++;
                end
                continue;
            end

            accepted_count++;
            unique case (req.packet_type)
                PCIE_MEM_WRITE: begin
                    mem_model[req.address[7:0]] = req.data;
                end
                PCIE_MEM_READ: begin
                    push_expected_completion(req, mem_model[req.address[7:0]]);
                end
                PCIE_CFG_WRITE: begin
                    ral_model.write(req.address, req.data);
                end
                PCIE_CFG_READ: begin
                    push_expected_completion(req, ral_model.read(req.address));
                end
                default: begin
                    unsupported_count++;
                end
            endcase
        end
    endtask

    function void push_expected_completion(pcie_tl_transaction req,
                                           bit [31:0] expected_data);
        pcie_tl_transaction exp = req.clone();
        exp.is_completion = 1'b1;
        exp.cpl_type = PCIE_COMPLETION_TYPE;
        exp.cpl_address = req.address;
        exp.cpl_data = expected_data;
        exp.cpl_tag = req.tag;
        expected_cpl_q.push_back(exp);
    endfunction

    task completion_loop();
        pcie_tl_transaction got;
        pcie_tl_transaction exp;

        forever begin
            cpl_mb.get(got);
            completion_count++;

            if (expected_cpl_q.size() == 0) begin
                error_count++;
                $error("[%s] Unexpected completion: %s", name, got.sprint());
                continue;
            end

            exp = expected_cpl_q.pop_front();
            if ((got.cpl_type !== exp.cpl_type) ||
                (got.cpl_address !== exp.cpl_address) ||
                (got.cpl_data !== exp.cpl_data) ||
                (got.cpl_tag !== exp.cpl_tag)) begin
                error_count++;
                $error(
                    "[%s] Completion mismatch\n  expected type=%0b addr=0x%04h data=0x%08h tag=0x%02h\n  got      type=%0b addr=0x%04h data=0x%08h tag=0x%02h",
                    name,
                    exp.cpl_type,
                    exp.cpl_address,
                    exp.cpl_data,
                    exp.cpl_tag,
                    got.cpl_type,
                    got.cpl_address,
                    got.cpl_data,
                    got.cpl_tag
                );
            end else begin
                compare_pass_count++;
            end
        end
    endtask

    task reset_watch_loop();
        bit last_rst;

        last_rst = 1'b0;
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.rst && !last_rst) begin
                reset_count++;
                reset_model();
                if (!ral_model.check_reset_mirror()) begin
                    error_count++;
                    $error("[%s] RAL reset mirror mismatch: %s", name, ral_model.sprint());
                end
            end
            last_rst = vif.mon_cb.rst;
        end
    endtask

    function int unsigned outstanding_completions();
        return expected_cpl_q.size();
    endfunction

    function bit has_errors();
        return (error_count != 0) || (expected_cpl_q.size() != 0);
    endfunction

    task wait_for_idle(int unsigned timeout_cycles = 1000);
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            if (expected_cpl_q.size() == 0) begin
                return;
            end
            @(vif.mon_cb);
        end

        error_count++;
        $error(
            "[%s] Timed out waiting for %0d expected completion(s)",
            name,
            expected_cpl_q.size()
        );
    endtask

    function void report();
        $display("[%s] requests=%0d accepted=%0d completions=%0d pass=%0d busy_ignored=%0d unsupported=%0d resets=%0d errors=%0d outstanding=%0d",
                 name,
                 request_count,
                 accepted_count,
                 completion_count,
                 compare_pass_count,
                 ignored_busy_count,
                 unsupported_count,
                 reset_count,
                 error_count,
                 expected_cpl_q.size());
    endfunction
endclass

// ============================================================
// Source: tb\coverage\pcie_tl_coverage.svh
// ============================================================
class pcie_tl_coverage;
    string name;
    virtual pcie_tl_if vif;

    mailbox #(pcie_tl_transaction) req_mb;
    mailbox #(pcie_tl_transaction) cpl_mb;

    bit [2:0] sample_packet_type;
    bit [15:0] sample_address;
    bit [31:0] sample_data;
    bit [7:0] sample_tag;
    bit sample_valid;
    bit sample_ready;
    bit sample_reset;
    bit sample_supported;
    bit sample_accepted;
    bit sample_completion;
    bit sample_is_mem;
    bit sample_is_cfg;
    bit sample_cpl_valid;
    bit [2:0] sample_cpl_type;
    pcie_addr_range_e sample_addr_range;
    pcie_data_pattern_e sample_data_pattern;
    pcie_rw_e sample_rw;

`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
    covergroup request_cg;
        option.per_instance = 1;
        option.name = "pcie_tl_request_cg";

        cp_packet_type: coverpoint sample_packet_type {
            bins mem_write   = {PCIE_MEM_WRITE};
            bins mem_read    = {PCIE_MEM_READ};
            bins cfg_write   = {PCIE_CFG_WRITE};
            bins cfg_read    = {PCIE_CFG_READ};
            bins unsupported = {[3'b100:3'b111]};
        }

        cp_mem_read: coverpoint (sample_packet_type == PCIE_MEM_READ) {
            bins no = {0};
            bins yes = {1};
        }

        cp_mem_write: coverpoint (sample_packet_type == PCIE_MEM_WRITE) {
            bins no = {0};
            bins yes = {1};
        }

        cp_cfg_read: coverpoint (sample_packet_type == PCIE_CFG_READ) {
            bins no = {0};
            bins yes = {1};
        }

        cp_cfg_write: coverpoint (sample_packet_type == PCIE_CFG_WRITE) {
            bins no = {0};
            bins yes = {1};
        }

        cp_address_range: coverpoint sample_addr_range {
            bins mem_direct        = {PCIE_ADDR_MEM_DIRECT};
            bins mem_aliased       = {PCIE_ADDR_MEM_ALIASED};
            bins cfg_id            = {PCIE_ADDR_CFG_ID};
            bins cfg_command       = {PCIE_ADDR_CFG_COMMAND};
            bins cfg_class         = {PCIE_ADDR_CFG_CLASS};
            bins cfg_bar0          = {PCIE_ADDR_CFG_BAR0};
            bins cfg_unimplemented = {PCIE_ADDR_CFG_UNIMPLEMENTED};
            bins cfg_aliased       = {PCIE_ADDR_CFG_ALIASED};
            bins unsupported       = {PCIE_ADDR_UNSUPPORTED};
        }

        cp_mem_address: coverpoint sample_address[7:0] iff (sample_is_mem) {
            bins low      = {[8'h00:8'h3f]};
            bins middle   = {[8'h40:8'hbf]};
            bins high     = {[8'hc0:8'hff]};
            bins boundary = {8'h00, 8'hff};
        }

        cp_cfg_address: coverpoint sample_address[11:2] iff (sample_is_cfg) {
            bins vendor_device = {10'h000};
            bins command       = {10'h001};
            bins class_rev     = {10'h002};
            bins bar0          = {10'h004};
            bins unimplemented = default;
        }

        cp_data_pattern: coverpoint sample_data_pattern {
            bins zero        = {PCIE_DATA_ZERO};
            bins all_ones    = {PCIE_DATA_ALL_ONES};
            bins alt_aa55    = {PCIE_DATA_ALT_AA55};
            bins alt_55aa    = {PCIE_DATA_ALT_55AA};
            bins random_data = {PCIE_DATA_RANDOM};
        }

        cp_tag: coverpoint sample_tag {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3f]};
            bins middle   = {[8'h40:8'hbf]};
            bins high     = {[8'hc0:8'hfe]};
            bins all_ones = {8'hff};
        }

        cp_completion: coverpoint sample_completion {
            bins no_completion = {0};
            bins completion    = {1};
        }

        cp_read_write: coverpoint sample_rw {
            bins read        = {PCIE_DIR_READ};
            bins write       = {PCIE_DIR_WRITE};
            bins unsupported = {PCIE_DIR_UNSUPPORTED};
        }

        cp_valid_request: coverpoint sample_valid {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_supported: coverpoint sample_supported {
            bins unsupported = {0};
            bins supported   = {1};
        }

        cp_accepted: coverpoint sample_accepted {
            bins not_accepted = {0};
            bins accepted     = {1};
        }

        cp_ready: coverpoint sample_ready {
            bins not_ready = {0};
            bins ready     = {1};
        }

        x_type_addr:       cross cp_packet_type, cp_address_range;
        x_type_completion: cross cp_packet_type, cp_completion;
        x_type_tag:        cross cp_packet_type, cp_tag;
        x_type_data:       cross cp_packet_type, cp_data_pattern;
        x_rw_addr:         cross cp_read_write, cp_address_range;
        x_rw_completion:   cross cp_read_write, cp_completion;
    endgroup

    covergroup completion_cg;
        option.per_instance = 1;
        option.name = "pcie_tl_completion_cg";

        cp_cpl_valid: coverpoint sample_cpl_valid {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_cpl_type: coverpoint sample_cpl_type {
            bins completion_with_data = {PCIE_COMPLETION_TYPE};
            illegal_bins other = default;
        }

        cp_cpl_address_range: coverpoint sample_addr_range {
            bins mem_direct        = {PCIE_ADDR_MEM_DIRECT};
            bins mem_aliased       = {PCIE_ADDR_MEM_ALIASED};
            bins cfg_id            = {PCIE_ADDR_CFG_ID};
            bins cfg_command       = {PCIE_ADDR_CFG_COMMAND};
            bins cfg_class         = {PCIE_ADDR_CFG_CLASS};
            bins cfg_bar0          = {PCIE_ADDR_CFG_BAR0};
            bins cfg_unimplemented = {PCIE_ADDR_CFG_UNIMPLEMENTED};
            bins cfg_aliased       = {PCIE_ADDR_CFG_ALIASED};
        }

        cp_cpl_tag: coverpoint sample_tag {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3f]};
            bins middle   = {[8'h40:8'hbf]};
            bins high     = {[8'hc0:8'hfe]};
            bins all_ones = {8'hff};
        }

        cp_cpl_data_pattern: coverpoint sample_data_pattern {
            bins zero        = {PCIE_DATA_ZERO};
            bins all_ones    = {PCIE_DATA_ALL_ONES};
            bins alt_aa55    = {PCIE_DATA_ALT_AA55};
            bins alt_55aa    = {PCIE_DATA_ALT_55AA};
            bins random_data = {PCIE_DATA_RANDOM};
        }
    endgroup

    covergroup bus_cg;
        option.per_instance = 1;
        option.name = "pcie_tl_bus_cg";

        cp_reset: coverpoint sample_reset {
            bins deasserted = {0};
            bins asserted   = {1};
        }

        cp_valid: coverpoint sample_valid {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_ready: coverpoint sample_ready {
            bins not_ready = {0};
            bins ready     = {1};
        }

        cp_cpl_valid: coverpoint sample_cpl_valid {
            bins inactive = {0};
            bins active   = {1};
        }

        x_valid_ready: cross cp_valid, cp_ready;
        x_reset_valid: cross cp_reset, cp_valid;
    endgroup
`endif

    function new(virtual pcie_tl_if vif,
                 mailbox #(pcie_tl_transaction) req_mb,
                 mailbox #(pcie_tl_transaction) cpl_mb,
                 string name = "pcie_tl_coverage");
        this.name = name;
        this.vif = vif;
        this.req_mb = req_mb;
        this.cpl_mb = cpl_mb;
`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
        request_cg = new();
        completion_cg = new();
        bus_cg = new();
`endif
    endfunction

    task run();
        fork
            request_loop();
            completion_loop();
            bus_loop();
        join_none
    endtask

    task request_loop();
        pcie_tl_transaction tr;

        forever begin
            req_mb.get(tr);
            sample_request(tr);
        end
    endtask

    task completion_loop();
        pcie_tl_transaction tr;

        forever begin
            cpl_mb.get(tr);
            process_completion(tr); // Corrected: Name collision resolved here
        end
    endtask

    task bus_loop();
        forever begin
            @(vif.mon_cb);
            sample_reset = vif.mon_cb.rst;
            sample_valid = vif.mon_cb.valid;
            sample_ready = vif.mon_cb.req_ready;
            sample_cpl_valid = vif.mon_cb.cpl_valid;
`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
            bus_cg.sample();
`endif
        end
    endtask

    function void sample_request(pcie_tl_transaction tr);
        sample_packet_type = tr.packet_type;
        sample_address = tr.address;
        sample_data = tr.data;
        sample_tag = tr.tag;
        sample_valid = 1'b1;
        sample_ready = tr.req_ready_sampled;
        sample_supported = tr.is_supported();
        sample_accepted = tr.accepted;
        sample_completion = tr.expect_completion;
        sample_is_mem = tr.is_memory();
        sample_is_cfg = tr.is_config();
        sample_addr_range = tr.addr_range();
        sample_data_pattern = tr.observed_data_pattern();
        sample_rw = tr.rw_kind();
`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
        request_cg.sample();
`endif
    endfunction

    // Corrected: Renamed from sample_completion() to process_completion() 
    function void process_completion(pcie_tl_transaction tr);
        sample_packet_type = PCIE_CPLD;
        sample_address = tr.cpl_address;
        sample_data = tr.cpl_data;
        sample_tag = tr.cpl_tag;
        sample_cpl_type = tr.cpl_type;
        sample_cpl_valid = 1'b1;
        sample_addr_range = classify_completion_address(tr.cpl_address);
        sample_data_pattern = pcie_tl_transaction::classify_data(tr.cpl_data);
`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
        completion_cg.sample();
`endif
    endfunction

    function pcie_addr_range_e classify_completion_address(bit [15:0] address);
        if (address[15:12] != 4'h0) begin
            return PCIE_ADDR_MEM_ALIASED;
        end

        unique case (address[11:2])
            10'h000: return PCIE_ADDR_CFG_ID;
            10'h001: return PCIE_ADDR_CFG_COMMAND;
            10'h002: return PCIE_ADDR_CFG_CLASS;
            10'h004: return PCIE_ADDR_CFG_BAR0;
            default: begin
                if (address <= 16'h00ff) begin
                    return PCIE_ADDR_MEM_DIRECT;
                end
                return PCIE_ADDR_CFG_UNIMPLEMENTED;
            end
        endcase
    endfunction

    function void report();
`ifndef PCIE_DISABLE_FUNCTIONAL_COVERAGE
        $display("[%s] coverage request=%0.2f completion=%0.2f bus=%0.2f total=%0.2f",
                 name,
                 request_cg.get_coverage(),
                 completion_cg.get_coverage(),
                 bus_cg.get_coverage(),
                 (request_cg.get_coverage() + completion_cg.get_coverage() + bus_cg.get_coverage()) / 3.0);
`else
        $display("[%s] functional coverage collection disabled by PCIE_DISABLE_FUNCTIONAL_COVERAGE", name);
`endif
    endfunction
endclass

// ============================================================
// Source: tb\environment\pcie_tl_env.svh
// ============================================================
class pcie_tl_env;
    string name;
    virtual pcie_tl_if vif;

    mailbox #(pcie_tl_transaction) gen2drv_mb;
    mailbox #(pcie_tl_transaction) req_sb_mb;
    mailbox #(pcie_tl_transaction) cpl_sb_mb;
    mailbox #(pcie_tl_transaction) req_cov_mb;
    mailbox #(pcie_tl_transaction) cpl_cov_mb;

    pcie_tl_generator  gen;
    pcie_tl_driver     drv;
    pcie_tl_monitor    mon;
    pcie_tl_scoreboard sb;
    pcie_tl_coverage   cov;

    bit built;
    bit started;

    function new(virtual pcie_tl_if vif, string name = "pcie_tl_env");
        this.name = name;
        this.vif = vif;
        built = 1'b0;
        started = 1'b0;
    endfunction

    function void build();
        gen2drv_mb = new();
        req_sb_mb = new();
        cpl_sb_mb = new();
        req_cov_mb = new();
        cpl_cov_mb = new();

        gen = new(gen2drv_mb, "gen");
        drv = new(vif, gen2drv_mb, "drv");
        mon = new(vif, req_sb_mb, cpl_sb_mb, req_cov_mb, cpl_cov_mb, "mon");
        sb = new(vif, req_sb_mb, cpl_sb_mb, "sb");
        cov = new(vif, req_cov_mb, cpl_cov_mb, "cov");

        built = 1'b1;
    endfunction

    task start();
        if (!built) begin
            build();
        end

        if (!started) begin
            fork
                drv.run();
                mon.run();
                sb.run();
                cov.run();
            join_none
            started = 1'b1;
        end
    endtask

    task apply_reset(int unsigned cycles = 5);
        if (!built) begin
            build();
        end

        drv.reset_signals();
        vif.rst <= 1'b1;
        repeat (cycles) begin
            @(posedge vif.clk);
        end
        @(negedge vif.clk);
        vif.rst <= 1'b0;
        repeat (2) begin
            @(posedge vif.clk);
        end
    endtask

    task pulse_reset(int unsigned cycles = 2);
        apply_reset(cycles);
    endtask

    function void set_driver_random_delay(int unsigned min_delay,
                                          int unsigned max_delay);
        drv.random_delay_min = min_delay;
        drv.random_delay_max = max_delay;
    endfunction

    task wait_for_drain(int unsigned timeout_cycles = 2000);
        for (int unsigned i = 0; i < timeout_cycles; i++) begin
            if ((gen2drv_mb.num() == 0) &&
                !drv.busy &&
                (sb.outstanding_completions() == 0)) begin
                repeat (5) begin
                    @(vif.mon_cb);
                end
                if ((gen2drv_mb.num() == 0) &&
                    !drv.busy &&
                    (sb.outstanding_completions() == 0)) begin
                    return;
                end
            end
            @(vif.mon_cb);
        end

        $error("[%s] Environment drain timed out", name);
    endtask

    function bit has_errors();
        return sb.has_errors();
    endfunction

    function void report();
        sb.report();
        cov.report();
    endfunction
endclass

// ============================================================
// Source: tb\tests\pcie_tl_tests.svh
// ============================================================
class pcie_tl_base_test;
    string name;
    virtual pcie_tl_if vif;
    pcie_tl_env env;
    bit [7:0] tag_seed;
    int unsigned default_timeout;

    function new();
        name = "pcie_tl_base_test";
        vif = null;
        env = null;
        tag_seed = 8'h00;
        default_timeout = 5000;
    endfunction

    function void set_context(string name, virtual pcie_tl_if vif);
        this.name = name;
        this.vif = vif;
        this.env = new(vif, {name, "_env"});
    endfunction

    virtual task run();
        if (env == null) begin
            $fatal(1, "[%s] Test context was not configured", name);
        end

        $display("[%s] START", name);
        env.build();
        env.start();
        env.apply_reset(5);
        run_phase();
        env.wait_for_drain(default_timeout);
        env.report();

        if (env.has_errors()) begin
            $fatal(1, "[%s] FAIL", name);
        end
        $display("[%s] PASS", name);
    endtask

    virtual task run_phase();
    endtask

    function bit [7:0] next_tag();
        tag_seed++;
        return tag_seed;
    endfunction

    task send_req(bit [2:0] typ,
                  bit [15:0] addr,
                  bit [31:0] wdata = 32'h0,
                  bit [7:0] req_tag = 8'h00,
                  int unsigned idle = 0);
        env.gen.send_directed(typ, addr, wdata, req_tag, idle);
    endtask

    task mem_write(bit [15:0] addr,
                   bit [31:0] wdata,
                   bit [7:0] req_tag = 8'h00,
                   int unsigned idle = 0);
        send_req(PCIE_MEM_WRITE, addr, wdata, req_tag, idle);
    endtask

    task mem_read(bit [15:0] addr,
                  bit [7:0] req_tag = 8'h00,
                  int unsigned idle = 0,
                  bit [31:0] ignored_data = 32'h0);
        send_req(PCIE_MEM_READ, addr, ignored_data, req_tag, idle);
    endtask

    task cfg_write(bit [15:0] addr,
                   bit [31:0] wdata,
                   bit [7:0] req_tag = 8'h00,
                   int unsigned idle = 0);
        send_req(PCIE_CFG_WRITE, addr, wdata, req_tag, idle);
    endtask

    task cfg_read(bit [15:0] addr,
                  bit [7:0] req_tag = 8'h00,
                  int unsigned idle = 0,
                  bit [31:0] ignored_data = 32'h0);
        send_req(PCIE_CFG_READ, addr, ignored_data, req_tag, idle);
    endtask
endclass

class pcie_tl_reset_test extends pcie_tl_base_test;
    virtual task run_phase();
        env.apply_reset(3);
        env.apply_reset(1);
    endtask
endclass

class pcie_tl_sanity_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0020, 32'h1234_5678, next_tag());
        mem_read (16'h0020, next_tag());
        cfg_read (16'h0000, next_tag());
    endtask
endclass

class pcie_tl_smoke_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0020, 32'h1234_5678, next_tag(), 1);
        mem_read (16'h0020, next_tag(), 1);
        cfg_read (16'h0000, next_tag(), 1);
        cfg_write(16'h0004, 32'h0000_0007, next_tag(), 1);
        cfg_read (16'h0004, next_tag(), 1);
    endtask
endclass

class pcie_tl_memory_write_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0000, 32'h0000_0000, next_tag());
        mem_write(16'h0004, 32'hffff_ffff, next_tag());
        mem_write(16'h0008, 32'haaaa_5555, next_tag());
        mem_write(16'h000c, 32'h5555_aaaa, next_tag());
        mem_write(16'h00fc, 32'hcafe_f00d, next_tag());
        mem_read(16'h0000, next_tag());
        mem_read(16'h0004, next_tag());
        mem_read(16'h0008, next_tag());
        mem_read(16'h000c, next_tag());
        mem_read(16'h00fc, next_tag());
    endtask
endclass

class pcie_tl_memory_read_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_read(16'h0000, next_tag());
        mem_read(16'h0040, next_tag());
        mem_read(16'h00ff, next_tag());
        mem_read(16'h0120, next_tag());
    endtask
endclass

class pcie_tl_configuration_write_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_write(16'h0004, 32'h0000_0007, next_tag());
        cfg_read (16'h0004, next_tag());
        cfg_write(16'h0010, 32'hffff_fff5, next_tag());
        cfg_read (16'h0010, next_tag());
        cfg_write(16'h0000, 32'hdead_beef, next_tag());
        cfg_read (16'h0000, next_tag());
    endtask
endclass

class pcie_tl_configuration_read_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_read(16'h0000, next_tag());
        cfg_read(16'h0004, next_tag());
        cfg_read(16'h0008, next_tag());
        cfg_read(16'h0010, next_tag());
        cfg_read(16'h0020, next_tag());
    endtask
endclass

class pcie_tl_bar0_read_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_read(16'h0010, next_tag());
    endtask
endclass

class pcie_tl_command_register_write_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_write(16'h0004, 32'h0000_0001, next_tag());
        cfg_write(16'h0004, 32'h0000_0007, next_tag());
        cfg_read (16'h0004, next_tag());
    endtask
endclass

class pcie_tl_command_register_read_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_read(16'h0004, next_tag());
    endtask
endclass

class pcie_tl_sequential_reads_test extends pcie_tl_base_test;
    virtual task run_phase();
        for (int unsigned i = 0; i < 16; i++) begin
            bit [15:0] addr;
            addr = i * 4;
            mem_write(addr, 32'h1000_0000 + i, next_tag());
        end
        for (int unsigned i = 0; i < 16; i++) begin
            bit [15:0] addr;
            addr = i * 4;
            mem_read(addr, next_tag());
        end
    endtask
endclass

class pcie_tl_sequential_writes_test extends pcie_tl_base_test;
    virtual task run_phase();
        for (int unsigned i = 0; i < 32; i++) begin
            bit [15:0] addr;
            addr = i;
            mem_write(addr, 32'h2000_0000 + i, next_tag());
        end
        for (int unsigned i = 0; i < 32; i++) begin
            bit [15:0] addr;
            addr = i;
            mem_read(addr, next_tag());
        end
    endtask
endclass

class pcie_tl_read_after_write_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0034, 32'hfeed_1234, next_tag());
        mem_read (16'h0034, next_tag());
        cfg_write(16'h0004, 32'h0000_0005, next_tag());
        cfg_read (16'h0004, next_tag());
        cfg_write(16'h0010, 32'h0000_2abc, next_tag());
        cfg_read (16'h0010, next_tag());
    endtask
endclass

class pcie_tl_multiple_config_accesses_test extends pcie_tl_base_test;
    virtual task run_phase();
        cfg_read (16'h0000, next_tag());
        cfg_read (16'h0008, next_tag());
        cfg_write(16'h0004, 32'h0000_0003, next_tag());
        cfg_read (16'h0004, next_tag());
        cfg_write(16'h0010, 32'h0000_400f, next_tag());
        cfg_read (16'h0010, next_tag());
        cfg_read (16'h0024, next_tag());
        cfg_write(16'h0024, 32'hffff_ffff, next_tag());
        cfg_read (16'h0024, next_tag());
    endtask
endclass

class pcie_tl_mixed_memory_config_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0008, 32'h1111_2222, next_tag());
        cfg_read (16'h0000, next_tag());
        mem_read (16'h0008, next_tag());
        cfg_write(16'h0004, 32'h0000_0006, next_tag());
        mem_write(16'h0188, 32'h3333_4444, next_tag());
        cfg_read (16'h0004, next_tag());
        mem_read (16'h0088, next_tag());
        mem_read (16'h0188, next_tag());
        cfg_write(16'h0010, 32'h0000_8003, next_tag());
        cfg_read (16'h0010, next_tag());
    endtask
endclass

class pcie_tl_completion_validation_test extends pcie_tl_base_test;
    virtual task run_phase();
        mem_write(16'h0001, 32'h0000_0000, 8'h10);
        mem_write(16'h0002, 32'hffff_ffff, 8'h11);
        mem_write(16'h0003, 32'haaaa_5555, 8'h12);
        mem_read (16'h0001, 8'h00);
        mem_read (16'h0002, 8'h55);
        mem_read (16'h0003, 8'hff);
        cfg_read (16'h0000, 8'h33);
        cfg_read (16'h0010, 8'hcc);
    endtask
endclass

class pcie_tl_constrained_random_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 50000;
        env.set_driver_random_delay(0, 4);
        env.gen.send_random(1000, 30, 30, 20, 20, 10, 0);
    endtask
endclass

class pcie_tl_back_to_back_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 20000;
        env.set_driver_random_delay(0, 0);
        env.gen.send_random(500, 30, 30, 20, 20, 0, 0);
    endtask
endclass

class pcie_tl_negative_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 30000;

        // Invalid TLP length is not a top-level stimulus field in this DUT:
        // tlp_generator hardwires one DW, so the negative space is packet type,
        // address aliasing, valid glitches, and requests while busy.
        mem_write(16'h0020, 32'h1111_aaaa, next_tag());
        mem_read (16'h0020, 8'h40);
        env.gen.send_busy_violation(PCIE_MEM_WRITE, 16'h0020, 32'hdead_beef, 8'h41);
        env.gen.send_unsupported(8);
        env.gen.send_valid_glitch(PCIE_MEM_WRITE, 16'h0030, 32'hbad0_bad0, 8'h42);

        mem_read (16'h1234, 8'h43, 0, 32'hffff_ffff);
        mem_write(16'h1abc, 32'h2468_ace0, 8'h44);
        mem_read (16'h00bc, 8'h45);

        cfg_read (16'h1ffc, 8'h46);
        cfg_write(16'h2ffc, 32'hffff_ffff, 8'h47);
        cfg_read (16'h0ffc, 8'h48);

        env.gen.send_repeated_tag(4, 8'hAA, PCIE_MEM_READ, 16'h0000);
    endtask
endclass

class pcie_tl_stress_1000_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 100000;
        env.set_driver_random_delay(0, 3);
        env.gen.send_random(1000, 35, 35, 15, 15, 6, 1);
    endtask
endclass

class pcie_tl_stress_5000_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 400000;
        env.set_driver_random_delay(0, 2);
        env.gen.send_random(5000, 35, 35, 15, 15, 4, 1);
    endtask
endclass

class pcie_tl_stress_10000_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 800000;
        env.set_driver_random_delay(0, 1);
        env.gen.send_random(10000, 35, 35, 15, 15, 2, 1);
    endtask
endclass

class pcie_tl_random_reset_stress_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 200000;
        env.set_driver_random_delay(0, 2);
        for (int unsigned batch = 0; batch < 10; batch++) begin
            env.gen.send_random(100, 30, 30, 20, 20, 3, 0);
            env.wait_for_drain(20000);
            env.pulse_reset($urandom_range(1, 4));
        end
    endtask
endclass

class pcie_tl_long_duration_test extends pcie_tl_base_test;
    virtual task run_phase();
        default_timeout = 1000000;
        env.set_driver_random_delay(0, 8);
        env.gen.send_random(12000, 30, 30, 20, 20, 12, 1);
    endtask
endclass

function automatic pcie_tl_base_test pcie_tl_create_test(string testname,
                                                         virtual pcie_tl_if vif);
    pcie_tl_base_test test;

    case (testname)
        "reset_test": begin
            pcie_tl_reset_test t = new();
            test = t;
        end
        "sanity_test": begin
            pcie_tl_sanity_test t = new();
            test = t;
        end
        "smoke_test": begin
            pcie_tl_smoke_test t = new();
            test = t;
        end
        "memory_write_test": begin
            pcie_tl_memory_write_test t = new();
            test = t;
        end
        "memory_read_test": begin
            pcie_tl_memory_read_test t = new();
            test = t;
        end
        "configuration_write_test": begin
            pcie_tl_configuration_write_test t = new();
            test = t;
        end
        "configuration_read_test": begin
            pcie_tl_configuration_read_test t = new();
            test = t;
        end
        "bar0_read_test": begin
            pcie_tl_bar0_read_test t = new();
            test = t;
        end
        "command_register_write_test": begin
            pcie_tl_command_register_write_test t = new();
            test = t;
        end
        "command_register_read_test": begin
            pcie_tl_command_register_read_test t = new();
            test = t;
        end
        "sequential_reads_test": begin
            pcie_tl_sequential_reads_test t = new();
            test = t;
        end
        "sequential_writes_test": begin
            pcie_tl_sequential_writes_test t = new();
            test = t;
        end
        "read_after_write_test": begin
            pcie_tl_read_after_write_test t = new();
            test = t;
        end
        "multiple_config_accesses_test": begin
            pcie_tl_multiple_config_accesses_test t = new();
            test = t;
        end
        "mixed_memory_config_test": begin
            pcie_tl_mixed_memory_config_test t = new();
            test = t;
        end
        "completion_validation_test": begin
            pcie_tl_completion_validation_test t = new();
            test = t;
        end
        "constrained_random_test": begin
            pcie_tl_constrained_random_test t = new();
            test = t;
        end
        "back_to_back_test": begin
            pcie_tl_back_to_back_test t = new();
            test = t;
        end
        "negative_test": begin
            pcie_tl_negative_test t = new();
            test = t;
        end
        "stress_1000_test": begin
            pcie_tl_stress_1000_test t = new();
            test = t;
        end
        "stress_5000_test": begin
            pcie_tl_stress_5000_test t = new();
            test = t;
        end
        "stress_10000_test": begin
            pcie_tl_stress_10000_test t = new();
            test = t;
        end
        "random_reset_stress_test": begin
            pcie_tl_random_reset_stress_test t = new();
            test = t;
        end
        "long_duration_test": begin
            pcie_tl_long_duration_test t = new();
            test = t;
        end
        default: begin
            $warning("Unknown TESTNAME=%s. Falling back to sanity_test.", testname);
            begin
                pcie_tl_sanity_test t = new();
                test = t;
                testname = "sanity_test";
            end
        end
    endcase

    test.set_context(testname, vif);
    return test;
endfunction

endpackage

// ============================================================
// Source: tb\assertions\pcie_tl_assertions.sv
// ============================================================
`timescale 1ns / 1ps

`ifndef PCIE_DISABLE_SVA
module pcie_tl_assertions (
    input logic        clk,
    input logic        rst,
    input logic        valid,
    input logic [2:0]  packet_type,
    input logic [15:0] address,
    input logic [31:0] data,
    input logic [7:0]  tag,
    input logic        req_ready,
    input logic        cpl_valid,
    input logic [2:0]  cpl_type,
    input logic [15:0] cpl_address,
    input logic [31:0] cpl_data,
    input logic [7:0]  cpl_tag,
    input logic        parsed_valid,
    input logic        parsed_supported,
    input logic [2:0]  parsed_type,
    input logic [15:0] parsed_address,
    input logic [7:0]  parsed_tag,
    input logic        mem_we,
    input logic        mem_re,
    input logic        cfg_we,
    input logic        cfg_re,
    input logic        send_completion,
    input logic [15:0] response_address,
    input logic [7:0]  response_tag,
    input logic [2:0]  ctrl_state,
    input logic [2:0]  saved_type,
    input logic [15:0] saved_address,
    input logic [7:0]  saved_tag
);
    localparam logic [2:0] MEM_WRITE = 3'b000;
    localparam logic [2:0] MEM_READ  = 3'b001;
    localparam logic [2:0] CFG_WRITE = 3'b010;
    localparam logic [2:0] CFG_READ  = 3'b011;
    localparam logic [2:0] CPLD      = 3'b100;

    localparam logic [2:0] S_IDLE      = 3'd0;
    localparam logic [2:0] S_EXECUTE   = 3'd1;
    localparam logic [2:0] S_READ_WAIT = 3'd2;
    localparam logic [2:0] S_RESPOND   = 3'd3;

    default clocking cb @(posedge clk);
    endclocking

    function automatic bit is_read_type(logic [2:0] typ);
        return (typ == MEM_READ) || (typ == CFG_READ);
    endfunction

    function automatic bit is_write_type(logic [2:0] typ);
        return (typ == MEM_WRITE) || (typ == CFG_WRITE);
    endfunction

    function automatic bit is_supported_type(logic [2:0] typ);
        return (typ inside {MEM_WRITE, MEM_READ, CFG_WRITE, CFG_READ});
    endfunction

    ap_reset_behavior: assert property (
        rst |=> (req_ready &&
                 !cpl_valid &&
                 !mem_we &&
                 !mem_re &&
                 !cfg_we &&
                 !cfg_re)
    ) else $error("[PCIE_SVA] Reset behavior check failed");

    ap_no_accept_when_not_ready: assert property (
        disable iff (rst)
        (valid && !req_ready)
        |=> ($stable(saved_type) &&
             $stable(saved_address) &&
             $stable(saved_tag))
    ) else $error("[PCIE_SVA] Saved request changed while req_ready was low");

    ap_completion_only_for_reads: assert property (
        disable iff (rst)
        cpl_valid |-> is_read_type(saved_type)
    ) else $error("[PCIE_SVA] Completion generated for non-read request");

    ap_completion_type: assert property (
        disable iff (rst)
        cpl_valid |-> (cpl_type == CPLD)
    ) else $error("[PCIE_SVA] Completion type is not CPLD");

    ap_completion_tag_matches_request: assert property (
        disable iff (rst)
        cpl_valid |-> ((cpl_tag == saved_tag) && (cpl_tag == response_tag))
    ) else $error("[PCIE_SVA] Completion tag does not match saved request tag");

    ap_completion_addr_matches_request: assert property (
        disable iff (rst)
        cpl_valid |-> ((cpl_address == saved_address) &&
                       (cpl_address == response_address))
    ) else $error("[PCIE_SVA] Completion address does not match saved request address");

    ap_one_enable_or_none: assert property (
        disable iff (rst)
        $onehot0({mem_we, mem_re, cfg_we, cfg_re})
    ) else $error("[PCIE_SVA] More than one controller enable asserted");

    ap_no_simultaneous_read_write_enables: assert property (
        disable iff (rst)
        !(((mem_we || cfg_we) && (mem_re || cfg_re)) ||
          (mem_we && mem_re) ||
          (cfg_we && cfg_re))
    ) else $error("[PCIE_SVA] Simultaneous read/write enables detected");

    ap_controller_eventually_idle_after_accept: assert property (
        disable iff (rst)
        (valid && req_ready && parsed_valid && parsed_supported)
        |-> ##[1:4] (ctrl_state == S_IDLE)
    ) else $error("[PCIE_SVA] Controller did not return to IDLE after accepted request");

    ap_non_idle_eventually_idle: assert property (
        disable iff (rst)
        (ctrl_state != S_IDLE)
        |-> ##[1:4] (ctrl_state == S_IDLE)
    ) else $error("[PCIE_SVA] Controller stuck outside IDLE");

    ap_read_accept_eventually_completes: assert property (
        disable iff (rst)
        (valid && req_ready && parsed_valid && parsed_supported && is_read_type(parsed_type))
        |-> ##[1:4] cpl_valid
    ) else $error("[PCIE_SVA] Accepted read did not generate completion");

    ap_write_accept_no_completion: assert property (
        disable iff (rst)
        (valid && req_ready && parsed_valid && parsed_supported && is_write_type(parsed_type))
        |=> !cpl_valid ##1 !cpl_valid
    ) else $error("[PCIE_SVA] Write request generated a completion");

    ap_unsupported_no_action: assert property (
        disable iff (rst)
        (valid && req_ready && parsed_valid && !parsed_supported)
        |=> (!mem_we && !mem_re && !cfg_we && !cfg_re && !send_completion)
    ) else $error("[PCIE_SVA] Unsupported request caused DUT action");

    ap_memory_write_only_during_mem_write: assert property (
        disable iff (rst)
        mem_we |-> ((ctrl_state == S_EXECUTE) && (saved_type == MEM_WRITE))
    ) else $error("[PCIE_SVA] mem_we asserted outside Memory Write execute cycle");

    ap_memory_read_only_during_mem_read: assert property (
        disable iff (rst)
        mem_re |-> ((ctrl_state == S_EXECUTE) && (saved_type == MEM_READ))
    ) else $error("[PCIE_SVA] mem_re asserted outside Memory Read execute cycle");

    ap_config_write_only_during_cfg_write: assert property (
        disable iff (rst)
        cfg_we |-> ((ctrl_state == S_EXECUTE) && (saved_type == CFG_WRITE))
    ) else $error("[PCIE_SVA] cfg_we asserted outside Config Write execute cycle");

    ap_config_read_only_during_cfg_read: assert property (
        disable iff (rst)
        cfg_re |-> ((ctrl_state == S_EXECUTE) && (saved_type == CFG_READ))
    ) else $error("[PCIE_SVA] cfg_re asserted outside Config Read execute cycle");

    ap_no_xz_on_outputs: assert property (
        disable iff (rst)
        !$isunknown({
            req_ready,
            cpl_valid,
            cpl_type,
            cpl_address,
            cpl_data,
            cpl_tag
        })
    ) else $error("[PCIE_SVA] X/Z detected on DUT outputs");

    ap_no_xz_on_controller_enables: assert property (
        disable iff (rst)
        !$isunknown({mem_we, mem_re, cfg_we, cfg_re, send_completion})
    ) else $error("[PCIE_SVA] X/Z detected on controller enables");

    cp_mem_read_completion: cover property (
        disable iff (rst)
        (valid && req_ready && parsed_supported && (parsed_type == MEM_READ))
        ##[1:4] cpl_valid
    );

    cp_cfg_read_completion: cover property (
        disable iff (rst)
        (valid && req_ready && parsed_supported && (parsed_type == CFG_READ))
        ##[1:4] cpl_valid
    );
endmodule

bind pcie_endpoint pcie_tl_assertions pcie_tl_sva_i (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .packet_type(packet_type),
    .address(address),
    .data(data),
    .tag(tag),
    .req_ready(req_ready),
    .cpl_valid(cpl_valid),
    .cpl_type(cpl_type),
    .cpl_address(cpl_address),
    .cpl_data(cpl_data),
    .cpl_tag(cpl_tag),
    .parsed_valid(parsed_valid),
    .parsed_supported(parsed_supported),
    .parsed_type(parsed_type),
    .parsed_address(parsed_address),
    .parsed_tag(parsed_tag),
    .mem_we(mem_we),
    .mem_re(mem_re),
    .cfg_we(cfg_we),
    .cfg_re(cfg_re),
    .send_completion(send_completion),
    .response_address(response_address),
    .response_tag(response_tag),
    .ctrl_state(CTRL.state),
    .saved_type(CTRL.saved_type),
    .saved_address(CTRL.saved_address),
    .saved_tag(CTRL.saved_tag)
);
`endif

// ============================================================
// Source: tb\top\pcie_tl_tb_top.sv
// ============================================================
`timescale 1ns / 1ps

module pcie_tl_tb_top;
    import pcie_tl_pkg::*;

    logic clk;
    string testname;
    pcie_tl_base_test test;

    pcie_tl_if pcie_if(clk);

    pcie_endpoint DUT (
        .clk         (clk),
        .rst         (pcie_if.rst),
        .valid       (pcie_if.valid),
        .packet_type (pcie_if.packet_type),
        .address     (pcie_if.address),
        .data        (pcie_if.data),
        .tag         (pcie_if.tag),
        .req_ready   (pcie_if.req_ready),
        .cpl_valid   (pcie_if.cpl_valid),
        .cpl_type    (pcie_if.cpl_type),
        .cpl_address (pcie_if.cpl_address),
        .cpl_data    (pcie_if.cpl_data),
        .cpl_tag     (pcie_if.cpl_tag)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        pcie_if.rst = 1'b1;
        pcie_if.valid = 1'b0;
        pcie_if.packet_type = '0;
        pcie_if.address = '0;
        pcie_if.data = '0;
        pcie_if.tag = '0;

        if ($test$plusargs("WAVES")) begin
`ifdef PCIE_EDAPLAYGROUND
            $dumpfile("dump.vcd");
`else
            $dumpfile("sim/pcie_tl_tb.vcd");
`endif
            $dumpvars(0, pcie_tl_tb_top);
        end

        if (!$value$plusargs("TESTNAME=%s", testname)) begin
            testname = "sanity_test";
        end

        test = pcie_tl_create_test(testname, pcie_if);
        test.run();

        #20;
        $finish;
    end
endmodule
