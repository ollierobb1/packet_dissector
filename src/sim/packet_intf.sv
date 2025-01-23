interface packet_intf (
    input logic clk
);

    logic valid;
    logic [63:0] data;
    logic [7:0] byte_enable;
    logic sop;
    logic eop;

    modport source (
        output valid, 
        output data, 
        output byte_enable, 
        output sop, 
        output eop, 
        import task write(), 
        import task clear()
    );

    modport sink (
        input valid, 
        input data, 
        input byte_enable, 
        input sop, 
        input eop
    );

    task automatic delay_cc(int cycles = 1);
        repeat (cycles) @(posedge(clk));
    endtask

    task automatic write(byte _data[]);
        const int bytes_in_word = 64/8;

        int _bytes_left = _data.size() % 8; // Calculate how many bytes in the final word to keep
        logic [7:0] _byte_enable = (_bytes_left == 0) ? '1 : ((1 << _bytes_left) - 1) << (8 - _bytes_left);

        int _words_to_send = (_data.size() + 7) / 8;
        int _words_sent = 0;

        $display("word to send and size %d %d", _words_to_send, _data.size());

        delay_cc();

        valid <= 1;
        byte_enable <= '1;

        fork
            begin
                sop <= 1;
                delay_cc();
                sop <= 0;
            end
            begin
                while (_words_sent < _words_to_send) begin
                    data = 0;
                    // Write current word
                    for (int curr_byte = 0; curr_byte < bytes_in_word; curr_byte++) begin
                        int index = _words_sent * bytes_in_word + curr_byte; // Calculate the index in _data
                        if (index < _data.size()) begin
                            // Assign the byte into the correct position in the 64-bit word
                            data[(bytes_in_word - 1 - curr_byte) * 8 +: 8] = _data[index];
                        end
                    end

                    if (_words_sent == _words_to_send - 1) begin
                       eop <= 1;
                       byte_enable <= _byte_enable; 
                    end
                    
                    _words_sent++;
                    delay_cc();
                end
            end
        join

        clear();
    endtask

    task clear();
        valid <= 0;
        data <= 0;
        byte_enable <= 0;
        sop <= 0;
        eop <= 0;
    endtask
endinterface