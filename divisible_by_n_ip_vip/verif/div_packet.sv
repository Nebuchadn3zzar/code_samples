///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Sequence item classes for streaming divisibility checker module
///////////////////////////////////////////////////////////////////////////////


// Base sequence item that should cover an even distribution of possible values
// that can fit within bitstreams of length `MAX_STREAM_LEN
class div_packet extends uvm_sequence_item;
    // Fields
    rand int unsigned                num_bits;
    rand logic [`MAX_STREAM_LEN-1:0] data;
    logic                            divisible;
    rand int unsigned                modulo;

    `uvm_object_utils_begin(div_packet);  // Utility operations such as copy, compare, pack, etc.
        `uvm_field_int(num_bits,  UVM_DEFAULT | UVM_NOCOMPARE);  // Exclude from comparisons
        `uvm_field_int(data,      UVM_DEFAULT | UVM_NOCOMPARE);  // Exclude from comparisons
        `uvm_field_int(divisible, UVM_DEFAULT);                  // Include in all utility operations
    `uvm_object_utils_end;

    // Constraints
    constraint num_bits_c {
        num_bits inside {[0:`MAX_STREAM_LEN]};
    }
    constraint modulo_c {
        modulo == (data % `DIV_BY);
    }

    function void post_randomize();
        // Prevent 'num_bits' from biasing effective values of 'data' away from its upper range,
        // resulting in incomplete coverage of 'div_packet.data'
        int unsigned min_bits = $clog2(data);

        // If necessary, increase length to be just enough to contain value of 'data'
        num_bits = (num_bits < min_bits) ? min_bits : num_bits;
    endfunction : post_randomize

    function new(string name="div_packet");
        super.new(name);
    endfunction : new
endclass : div_packet

// Sequence item that produces stimulus whose values are mostly evenly divisible by N, rather than
// evenly distributed
class div_packet_mostly_divisible extends div_packet;
    `uvm_object_utils(div_packet_mostly_divisible);  // Register object with factory

    // Constraints
    constraint mostly_divisible_c {
        modulo dist {0             :/ 80,   // Evenly divisible by N
                     [1:`DIV_BY-1] :/ 20};  // Not evenly divisible by N
    }

    function new(string name="div_packet_mostly_divisible");
        super.new(name);
    endfunction : new
endclass : div_packet_mostly_divisible

