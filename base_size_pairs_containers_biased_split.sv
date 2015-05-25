////////////////////////////////////////////////////////////////////////////////
// Will Chen
// 2015-05-20
// Version 0.3
//
// Description:
//    * A fairly generic class that generates a list of non-overlapping (base address, size) pairs to be used to
//      sparsely populate a block of memory
//    * Creates "containers" in which the actual pairs reside, at some offset within the containers
//      [Container   (Pair----------------)  ]
//      ^---Offset---^
//    * Pairs can possibly end up with size 0; if this is undesirable, increase the lower bound on 'pair_sizes[i]' in
//      the 'sizes_offsets_c' constraint from 0 to 1
//    * Examples:
//       * Even split:            {[C0-------------------][C1-------------------][C2-------------------]}
//       * Somewhat uneven split: {[C0---------------][C1---------------------------][C2---------------]}
//       * Very uneven split:     [[C0-][C1-----][C2---------------------------------------------------]}
//
// Knobs of interest:
//    * log2_locs (class parameter): Log (base 2) of number of memory locations within block of memory
//    * num_containers:              Number of containers within block of memory
//    * max_container_size weights:  For tuning the distribution (over multiple seeds) amongst almost-even, somewhat
//                                   uneven, and very uneven splits
//
// Output:
//    * pair_addrs[]: Base address of each pair
//    * pair_sizes[]: Size of each pair
//
// Limitations:
//    * Does not currently have knobs for enforcing minimum and maximum addresses (for instance, to force containers
//      to reside within only a specific area of the block of memory)
//    * Could probably call "pair" a more descriptive name
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns


// List of base address and size pairs
class base_size_pair_list #(int unsigned log2_locs = 32);  // Log (base 2) of number of memory locations
   localparam HEX_DGTS = (log2_locs + 3) / 4;  // Number of hexadecimal digits required to print an address

   logic [log2_locs-1:0] MEM_LOCS = (2**log2_locs - 1);  // Number of memory locations
   rand logic [ log2_locs   -1:0] num_containers;        // Number of containers within memory space [0:MEM_LOCS]
   rand logic [ log2_locs   -1:0] even_split_size;       // Size that would result in an even split amongst containers
   rand logic [(log2_locs*2)-1:0] even_split_plus_15pc;  // Size that is 15% of the way between even split and MEM_LOCS
   rand logic [(log2_locs*2)-1:0] even_split_plus_30pc;  // Size that is 30% of the way between even split and MEM_LOCS
   rand logic [ log2_locs   -1:0] max_container_size;    // Largest permitted container size for this sim

   rand logic [(log2_locs*2)-1:0] container_sizes[];   // Size of each container (width doubled for 'sum()')
   rand logic [ log2_locs   -1:0] pair_sizes[];        // Size of each pair within its container
   rand logic [ log2_locs   -1:0] pair_offsets[];      // Where each pair is within its container
   logic      [ log2_locs   -1:0] container_addrs[$];  // Not random, since computed post-randomisation
   logic      [ log2_locs   -1:0] pair_addrs[$];       // Not random, since computed post-randomisation

   string hex_fmt_str = $sformatf("0x%%0%0dh", HEX_DGTS);  // Format string for printing addresses in hexadecimal

   // Constraints
   constraint num_containers_c {
      num_containers inside {[1:20]};
      container_sizes.size() == num_containers;
      pair_sizes.size()      == num_containers;
      pair_offsets.size()    == num_containers;
   }
   constraint split_sizes_c {
      // Compute the container sizes that are 15% and 30% of the way between an even split and the size of the memory
      solve num_containers  before even_split_size;
      solve even_split_size before even_split_plus_15pc;
      solve even_split_size before even_split_plus_30pc;
      even_split_size      == MEM_LOCS / num_containers;
      even_split_plus_15pc == even_split_size + (((MEM_LOCS - even_split_size) * 15) / 100);
      even_split_plus_30pc == even_split_size + (((MEM_LOCS - even_split_size) * 30) / 100);
   }
   constraint max_container_size_c {
      // Bias maximum container size toward a somewhat uneven split, to decrease chances of a small handful of
      // containers hogging most of the memory space, and thus most other containers ending up being tiny (often ending
      // up with the minimum size of 1 when MEM_LOCS is small); given the behaviour of VCS's constraint solver, this
      // approach is much more effective than attempting to directly tune the distribution of container sizes, and
      // should still yield decent coverage over many random seeds
      max_container_size dist {[even_split_size      : even_split_plus_15pc - 1] :/ 30,   // Within 15% of even split
                               [even_split_plus_15pc : even_split_plus_30pc - 1] :/ 60,   // Somewhat uneven
                               [even_split_plus_30pc : MEM_LOCS                ] :/ 10};  // Likely very uneven
   }
   constraint sizes_offsets_c {
      container_sizes.sum() == MEM_LOCS;  // Let containers occupy entire memory space
      foreach (container_sizes[i]) {
         container_sizes[i] inside {[1:max_container_size]};       // Keep container sizes under chosen maximum
         pair_sizes[i]      inside {[0:container_sizes[i]]};       // Each pair must fit within its container
         pair_offsets[i] <= (container_sizes[i] - pair_sizes[i]);  // Offset must not place pair outside of its container
      }
   }

   function void post_randomize();
      // Compute addresses from sizes and offsets
      foreach (container_sizes[i]) begin
         if (i == 0) begin
            container_addrs.push_back(0);
            pair_addrs.push_back(pair_offsets[i]);
         end
         else begin
            container_addrs.push_back(container_addrs[i-1] + container_sizes[i-1]);
            pair_addrs.push_back(container_addrs[i] + pair_offsets[i]);
         end
      end
   endfunction : post_randomize

   // Prints information that may be useful for debugging
   function void print_debug_info();
      $display("[DEBUG] MEM_LOCS %s, num_containers %0d, even split size %s",
               $sformatf(hex_fmt_str, MEM_LOCS), num_containers, $sformatf(hex_fmt_str, even_split_size));
      $display("[DEBUG] even_split_plus_15pc %s, even_split_plus_30pc %s, max_container_size %s",
               $sformatf(hex_fmt_str, even_split_plus_15pc), $sformatf(hex_fmt_str, even_split_plus_30pc),
               $sformatf(hex_fmt_str, max_container_size));
   endfunction : print_debug_info

   // Prints entire list of containers, including those with pairs of size 0
   function void print_containers();
      $display("Containers, including those with pairs of size 0:");
      foreach (container_addrs[i]) begin
         $display("   %05d: container addr %s, size %s, pair addr %s, size %s, offset %s", i,
                  $sformatf(hex_fmt_str, container_addrs[i]), $sformatf(hex_fmt_str, container_sizes[i]),
                  $sformatf(hex_fmt_str, pair_addrs[i]),      $sformatf(hex_fmt_str, pair_sizes[i]),
                  $sformatf(hex_fmt_str, pair_offsets[i]));
      end
   endfunction : print_containers

   // Prints all pairs of non-zero size
   function void print_pairs();
      int pair_count = 0;

      $display("Pairs of non-zero size:");
      foreach (pair_addrs[i]) begin
         if (pair_sizes[i]) begin
            $display("   %05d: pair addr %s, size %s",
                     pair_count++, $sformatf(hex_fmt_str, pair_addrs[i]), $sformatf(hex_fmt_str, pair_sizes[i]));
         end
      end
   endfunction : print_pairs
endclass : base_size_pair_list

module foo();
   base_size_pair_list #(32) p = new();

   initial begin
      p.randomize();
      p.print_debug_info();
      p.print_containers();
      p.print_pairs();
   end
endmodule : foo

