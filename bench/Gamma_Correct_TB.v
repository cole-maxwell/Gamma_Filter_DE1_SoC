//==========================================================
//
// University of Massachusetts, Amherst
// Department of Electrical and Computer Engineering
//
// Created by Cole Maxwell on 01/07/2021
//
// Comments: Feel free to edit this testbench according to your needs
//
//==========================================================

// Define the time precision of the simulation
`timescale 1ns / 1ns

module Gamma_Correct_TB();

    // Generic parameters of the testbench
    localparam CLK_PERIOD = 10;

    // Generate clock signal
    reg clk;
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Declare 3 arrays to store the input data (8-bit
    // intensity values), and the expected results
    reg [7:0] signal[0:255];
    reg [7:0] expected_values[0:255];

    // Read the input data and expected results from the text files
    initial begin
        $readmemh("../../../tests/signal_in.txt", signal);
        $readmemh("../../../tests/expected_values.txt", expected_values);
    end

    // Testbench signal declaration
    integer signal_idx;
    reg start_testing, test_flag;

    // Signal declaration for Unit Under Test (UUT)
    // Input
    reg rst;
    reg  valid_in;
    wire valid_out;
    wire [7:0] signal_in; // iY
    wire [7:0] result; // result

    // Instantiate the gamma_filter module
    Gamma_Correct_Case_Statements UUT(
        .clk        (clk),
        .rst        (rst),
        .valid_in   (valid_in),
        .valid_out  (valid_out),
        .signal_in  (signal_in),
        .result     (result)
    );

    // Use a counter to index the values of the input signal
    always @(posedge clk) begin
        if(rst)
            signal_idx <= 0;
        else if(start_testing & valid_in & (signal_idx < 256))
            signal_idx <= signal_idx + 1;
    end

    // Send the values of the input signal to the gamma_filter module
    assign signal_in = rst ? 0 : signal[signal_idx];

    // Generate valid_in signal
    initial begin
        // Reset valid_in signal
        valid_in = 0;

        // Wait on starting_testing
        wait(start_testing);

        while(signal_idx < 256) begin
            // Assert to one the valid_in
            // signal for one clock cycle
            valid_in = 1;
            #(CLK_PERIOD);
            valid_in = 0;

            // Introduce a delay between each valid_in
            // cycle to mimic the real transmission
            #(CLK_PERIOD*4);
        end
    end

    // Stimulus process
    initial begin
        // Signal initialization
        rst           = 1;
        start_testing = 0;
        test_flag     = 1;

        // After 100 ns deassert the reset signal
        #(CLK_PERIOD*10);
        rst = 0;

        // Initiate testing
        start_testing = 1;

        // Synch on the rising edge of the clock
        #(CLK_PERIOD/2);

        // Compare all the outcomes of the FIR module with the expected values and if
        // a mismatch occurs print out to the console a message to inform the user
        while(signal_idx < 256) begin
            if(valid_out & result != expected_values[signal_idx]) begin
                $display("----FAIL: index: %d, actual output: %8b, expected: %b", signal_idx, result, expected_values[signal_idx]);
                test_flag = 0;
            end else begin
                $display("PASS: index: %d, actual output: %8b, expected: %b", signal_idx, result, expected_values[signal_idx]);
            end
            // Add a delay cycle to the while-loop
            #(CLK_PERIOD);
        end

        // Reset FIR module
        rst           = 1;
        start_testing = 0;

        // Print out a message about the total result of the simulation
        if(test_flag)
            $display("\nSUCCESS: the UUT passed ALL the test cases");
        else
            $display("\nFAIL: at least one outcome of the UUT did not match with the expected one");
    end

endmodule // Gamma_Correct_TB