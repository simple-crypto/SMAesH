module MSKdata_holder_low_level
#(
    parameter d = 2,
    parameter BITS = 256,
    parameter RFRSH_RATE = 16 // MUST divide `BITS` parameter
)
(
    // Clock
    clk,
    // Data 
    shares_data_in,
    sh_data_out,
    // Randomness for refreshing
    rnd_rfrsh_in,
    // Control
    enable, 
    fetch_in
);

// Generation parameter
localparam NSTAGES = (BITS / RFRSH_RATE);

input clk;
input [d*RFRSH_RATE-1:0] shares_data_in;
output [d*BITS-1:0] sh_data_out;
input [(d-1)*RFRSH_RATE-1:0] rnd_rfrsh_in;
input [d-1:0] enable;
input fetch_in;

// Data to the output
wire [d*BITS-1:0] shares_to_out;
shares2shbus #(.d(d), .count(BITS))
encoder_output(
    .shares(shares_to_out),
    .shbus(sh_data_out)
);

// Generate a circular shift register holding the data.
wire [RFRSH_RATE-1:0] to_shares_pipeline [d-1:0];
wire [RFRSH_RATE-1:0] shares_pipeline_refreshed [d-1:0];
wire [RFRSH_RATE-1:0] out_shares_pipeline [d-1:0];

genvar i, j;
generate
for(i=0;i<d;i=i+1) begin: share_pipeline
    for(j=NSTAGES-1;j>=0;j=j-1) begin: serial_stage
        // Input/output data for this pipeline stage
        wire [RFRSH_RATE-1:0] stage_in, stage_out;
        // MSKreg to store the data
        MSKregEn #(.d(1), .count(RFRSH_RATE))
        reg_rfrsh_word(
            .clk(clk),
            .en(enable[i]),
            .in(stage_in),
            .out(stage_out)
        );
        if(j==NSTAGES-1) begin
            assign stage_in = to_shares_pipeline[i];
        end else begin
            assign stage_in = serial_stage[j+1].stage_out;
        end
        // Encode bus to output
        assign shares_to_out[i*BITS + j*RFRSH_RATE +: RFRSH_RATE] = stage_out;
    end
    assign out_shares_pipeline[i] = serial_stage[0].stage_out;
end
endgenerate

// Encoding at the input of the refresh logic
wire [RFRSH_RATE*d-1:0] shares_to_refresh_data; 
wire [RFRSH_RATE*d-1:0] sh_to_refresh_data;
shares2shbus #(.d(d), .count(RFRSH_RATE))
encoder_refresh(
    .shares(shares_to_refresh_data),
    .shbus(sh_to_refresh_data)
);

// Encoding at the output of the refresh logic
wire [RFRSH_RATE*d-1:0] sh_from_refresh_data;
wire [RFRSH_RATE*d-1:0] shares_from_refresh_data; 
shbus2shares #(.d(d), .count(RFRSH_RATE))
decoder_refresh(
    .shbus(sh_from_refresh_data),
    .shares(shares_from_refresh_data)
);

// Refresh logic
MSKrefresh_tree #(.d(d), .BITS(RFRSH_RATE))
logic_refresh(
    .sh_in(sh_to_refresh_data),
    .sh_out(sh_from_refresh_data),
    .rnd(rnd_rfrsh_in)
);


// Generate the assignation of share pipeline, and MUXes at the input of the pipeline
generate
for(i=0;i<d;i=i+1) begin: share_encoding
    // Bus encoding
    assign shares_to_refresh_data[i*RFRSH_RATE +: RFRSH_RATE] = out_shares_pipeline[i];
    assign shares_pipeline_refreshed[i] = shares_from_refresh_data[i*RFRSH_RATE +: RFRSH_RATE];
    // Mux at the input of the shift register
    MSKmux #(.d(1), .count(RFRSH_RATE))
    mux_fetch_in(
        .sel(fetch_in),
        .in_true(shares_data_in[i*RFRSH_RATE +: RFRSH_RATE]),
        .in_false(shares_pipeline_refreshed[i]),
        .out(to_shares_pipeline[i])
    );
end
endgenerate


endmodule
