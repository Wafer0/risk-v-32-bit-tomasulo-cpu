// issue_queue.sv
// Issue Queue (Optional)
// Specific queue for ordering if not using centralized RS

module issue_queue (
    input logic clk,
    input logic rst,
    input logic flush,
    output logic empty
);

    assign empty = 1'b1;

endmodule
