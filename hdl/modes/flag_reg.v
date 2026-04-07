module flag_reg
(
    input clk,
    input s_nrst,
    input s_set,
    output flag
);

reg reg_flag;
always@(posedge clk) begin
    if (~s_nrst) begin
        reg_flag <= 0;
    end else begin
        reg_flag <= reg_flag | s_set;
    end
end

assign flag = reg_flag;


endmodule
