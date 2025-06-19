`timescale 1ns / 1ps

// Field Macros
`define oper_type IR[31:27]
`define rdst      IR[26:22]
`define rsrc1     IR[21:17]
`define imm_mode  IR[16]
`define rsrc2     IR[15:11]
`define isrc      IR[15:0]

// Opcodes
`define mov        5'b00001
`define add        5'b00010
`define mul        5'b00100
`define storereg   5'b01101
`define senddout   5'b01111

module top(
  input clk,
  input sys_rst,
  input [15:0] din,
  output reg [15:0] dout
);

  reg [31:0] inst_mem [15:0];
  reg [15:0] data_mem [15:0];
  reg [15:0] GPR [31:0];
  reg [15:0] SGPR;
  reg [31:0] mul_res;
  reg [31:0] IR;

  integer PC = 0;
  reg [2:0] count = 0;

  reg senddout_flag = 0;
  reg [15:0] senddout_addr = 0;

  // Instruction Loader + Initialization
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1)
      GPR[i] = 0;
    for (i = 0; i < 16; i = i + 1)
      data_mem[i] = 0;

    $readmemb("inst_data.mem", inst_mem);
    for (i = 0; i < 5; i = i + 1)
      $display("Instruction %0d: %b", i, inst_mem[i]);
  end

  // Decoder
  task decode_inst();
  begin
    case (`oper_type)
      `mov: begin
        if (`imm_mode)
          GPR[`rdst] = `isrc;
        else
          GPR[`rdst] = GPR[`rsrc1];
        $display("MOV: GPR[%0d] = %h", `rdst, GPR[`rdst]);
      end

      `add: begin
        if (`imm_mode)
          GPR[`rdst] = GPR[`rsrc1] + `isrc;
        else
          GPR[`rdst] = GPR[`rsrc1] + GPR[`rsrc2];
        $display("ADD: GPR[%0d] = %h", `rdst, GPR[`rdst]);
      end

      `mul: begin
        if (`imm_mode)
          mul_res = GPR[`rsrc1] * `isrc;
        else
          mul_res = GPR[`rsrc1] * GPR[`rsrc2];
        GPR[`rdst] = mul_res[15:0];
        SGPR = mul_res[31:16];
        $display("MUL: GPR[%0d] = %h | SGPR = %h", `rdst, GPR[`rdst], SGPR);
      end

      `storereg: begin
        data_mem[`isrc] = GPR[`rsrc1];
        $display("STORE: data_mem[%0d] = %h", `isrc, GPR[`rsrc1]);
      end

      `senddout: begin
        senddout_flag = 1;
        senddout_addr = `isrc;
      end

      default: $display("Unknown instruction at PC = %0d", PC);
    endcase
  end
  endtask

  // Main instruction loop
  always @(posedge clk) begin
    if (sys_rst) begin
      PC <= 0;
      count <= 0;
      IR <= 0;
      dout <= 0;
    end else begin
      if (count < 4)
        count <= count + 1;
      else begin
        count <= 0;
        IR <= inst_mem[PC];
        $display("Time = %0t | PC = %0d | IR = %b", $time, PC, IR);
        decode_inst();
        PC <= PC + 1;
        if (PC > 4) begin
            $display("Program finished.");
         $finish;
end

      end
    end
  end

  // Registering dout on clock edge
  always @(posedge clk) begin
    if (senddout_flag) begin
      dout <= data_mem[senddout_addr];
      $display("SENDDOUT (registered): dout = %h from data_mem[%0d]", dout, senddout_addr);
      senddout_flag <= 0;
    end
  end

endmodule
