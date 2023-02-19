///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Static `defines for streaming divisibility checker UVM testbench
///////////////////////////////////////////////////////////////////////////////


// Maximum length of bitstream to test
`define MAX_STREAM_LEN 32

// Number of hexadecimal digits required to print longest bitstream value
`define HEX_DGTS ((`MAX_STREAM_LEN + 3) / 4)

