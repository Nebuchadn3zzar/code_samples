#!/usr/bin/env python3

###############################################################################
# Description:
#    * Applies an edge detection operator to an input greyscale image,
#      producing a new greyscale image file with detected edges marked
#    * Steps:
#       * Compute intensity gradient of image by convolving 3x3 Laplacian
#         second derivative approximation kernel across each pixel of input
#         image
#       * Apply edge thinning using non-maximum suppression, to remove pixels
#         not considered to be part of an edge
#       * Apply edge tracking using double-threshold hysteresis, to filter out
#         spurious edges caused by noise and color variation
#    * Algorithm implementations are not the most optimal, concise, or
#      efficient, because it is written with the intent to be used as a
#      reference model and debugging aid for a Verilog module
#
# Examples:
#    * edge_detect.py foo.pgm foo_edges.pgm
#      Applies edge detection on 'foo.pgm', and then writes detected edges to
#      new file 'foo_edges.pgm'
#    * edge_detect.py foo.pgm foo_edges.pgm -v
#      Same as above, but with verbose logging enabled for debugging
#    * edge_detect.py --help
#      Prints description of this script and each of its arguments, then exits
#
# Limitations:
#    * Accepts input image in only 8-bit PGM (portable grey map) format
#    * Produces output image in only 8-bit PGM (portable grey map) format
#    * Currently omits commonly-employed Gaussian smoothing step
###############################################################################


# Modules
import argparse
import logging as log
import numpy as np
import os
import re
import sys
import time

# Constants
LOGGER_FMT = "%(levelname)s: %(message)s"
LAPLACIAN = np.array([[-1, -1, -1],
                      [-1, +8, -1],
                      [-1, -1, -1]])  # Second derivative approximation kernel
THRESH_HI = 80  # Threshold for strong edge pixels used in edge tracking step
THRESH_LO = 40  # Threshold for weak edge pixels used in edge tracking step
MAX_VAL = 255  # Maximum grey value in output image

class EdgeDetectLib:
    """
    Image edge detection library.
    """

    def __init__(self, logger):
        self.log = logger

    def convert_pgm_to_np_arr(self, in_img_name):
        """
        Open input file handle and convert image in PGM format to a NumPy
        array.
        """

        self.log.info("Opening input file handle and converting PGM image to "
                      "NumPy array...")

        # Open file handle
        in_fh = open(in_img_name, "rb")  # Read, binary

        # Extract strings from PGM header
        pgm_hdr_strings = []  # List of strings parsed from PGM header
        for line in in_fh:
            if re.search(r"^\s*#", line.decode()):  # Comment
                self.log.debug(f"Ignoring comment: {line.decode().rstrip()}")
            elif len(pgm_hdr_strings) < 4:  # More PGM header strings to parse
                pgm_hdr_strings += re.findall(r"\S+", line.decode())

            if len(pgm_hdr_strings) >= 4:  # Reached end of PGM header
                break  # Leave position of file handle at beginning of raster
        self.log.debug(f"PGM header strings: {pgm_hdr_strings}")
        if len(pgm_hdr_strings) != 4:  # Incorrect number of strings parsed
            msg = f"Unable to detect PGM header at beginning of input image " \
                  f"file '{in_img_name}'"
            raise Exception(msg)
        (magic_num, wd, ht, max_val) = pgm_hdr_strings

        # Check magic number identifying PGM file type
        if magic_num != "P5":
            msg = f"Expected string 0 in PGM header to be 2-byte magic " \
                  f"number 'P5' for binary (raw) grey map, but found " \
                  f"'{magic_num}'"
            raise Exception(msg)

        # Check width and height specifiers
        if wd.isdigit() and ht.isdigit():
            wd = int(wd)
            ht = int(ht)
        else:
            msg = f"Expected strings 1 and 2 in PGM header to be image " \
                  f"width and height, respectively, in ASCII decimal, but " \
                  f"found '{wd}' and '{ht}'"
            raise Exception(msg)

        # Check maximum grey value specifier
        if max_val.isdigit():
            max_val = int(max_val)
        else:
            msg = f"Expected string 3 in PGM header to be maximum grey " \
                  f"value in ASCII decimal, but found '{max_val}'"
            raise Exception(msg)

        self.log.debug(f"Parsed valid PGM header with magic number " \
                       f"'{magic_num}', width {wd}, height {ht}, and " \
                       f"maximum grey value {max_val}")

        # Treat remainder of file as PGM raster, splitting it according to
        # dimensions specified in header
        buf = in_fh.read()  # Read remainder of file into buffer
        if len(buf) == (wd * ht):  # Raster size matches expected
            self.log.info(f"Raster is of expected size {wd} * {ht} = " \
                          f"{wd * ht}")
        else:  # Raster size does not match expected
            self.log.warning(f"Expected raster of size {wd} * {ht} = " \
                             f"{wd * ht}, but actual size {len(buf)}")
        pos = 0
        raster = []
        for y in range(ht):
            row = []
            for x in range(wd):
                if pos < len(buf):  # Current position is within bounds
                    row.append(buf[pos])  # Store current byte
                else:  # Current position is out of bounds
                    self.log.warning(f"Substituting 0 for missing pixel at " \
                                     f"row {y}, column {x}")
                    row.append(0)  # Substitute value
                pos += 1
            raster.append(row)

        # Close file handle
        in_fh.close()

        # Convert PGM raster to NumPy array
        np_arr = np.array(raster)
        self.log.debug(f"Raster as NumPy array {np_arr.shape}:\n{np_arr}")
        return np_arr

    def convert_np_arr_to_pgm(self, np_arr, out_img_name):
        """
        Convert given NumPy array to an image in PGM format.
        """

        self.log.info("Opening output file handle and converting NumPy array "
                      "to PGM image...")

        # Open file handle
        if os.path.exists(out_img_name):  # Output file already exists
            self.log.warning(f"Overwriting existing file '{out_img_name}'")
        out_fh = open(out_img_name, "w")

        # Write PGM header
        out_fh.write(f"P5\n")  # Magic number for binary (raw) grey map
        out_fh.write(f"{np_arr.shape[1]}\n")  # Width
        out_fh.write(f"{np_arr.shape[0]}\n")  # Height
        out_fh.write(f"{MAX_VAL}\n")  # Maximum grey value

        # Convert NumPy array to PGM raster and write to output file
        for p in np.ndarray.flatten(np_arr):
            out_fh.write(chr(p))
        out_fh.write("\n")

        # Close file handle
        out_fh.close()

    def apply_conv_kernel(self, in_np_arr, conv_kernel_np, kernel_desc):
        """
        Apply given kernel (convolution matrix) to given NumPy array.
        """

        self.log.info(f"Applying {kernel_desc} kernel...")

        # Duplicate edge pixels to handle edges and corners of image
        arr_padded = np.pad(in_np_arr, (1, 1), "edge")
        self.log.debug(f"Edges padded {arr_padded.shape}:\n{arr_padded}")

        # Check dimensions of given kernel
        if conv_kernel_np.shape != (3, 3):
            msg = f"Currently only 3x3 kernels supported, but given kernel " \
                  f"is of shape {conv_kernel_np.shape()}"
            raise NotImplementedError(msg)

        # Convolve given kernel across each pixel of input image
        arr_conv = np.zeros(in_np_arr.shape, dtype=int)
        for y in range(in_np_arr.shape[0] - 2):  # Each row
            for x in range(in_np_arr.shape[1] - 2):  # Each column
                arr_conv[y][x] = np.sum(arr_padded[y:y+3, x:x+3] * conv_kernel_np)
        self.log.debug(f"Convolution applied {arr_conv.shape}:\n{arr_conv}")

        return arr_conv

    def apply_edge_thinning(self, in_np_arr):
        """
        Apply edge thinning using non-maximum suppression, to remove pixels not
        considered to be part of an edge.
        """

        self.log.info("Applying edge thinning using non-maximum " \
                      "suppression...")

        # Duplicate edge pixels to handle edges and corners of image
        arr_padded = np.pad(in_np_arr, (1, 1), "edge")
        self.log.debug(f"Edges padded {arr_padded.shape}:\n{arr_padded}")

        # For each pixel, preserve value only if edge strength is largest
        # compared to adjacent pixels in X or Y directions
        arr_thinned = np.zeros(in_np_arr.shape, dtype=int)
        for y in range(1, in_np_arr.shape[0] - 1):  # Each row
            for x in range(1, in_np_arr.shape[1] - 1):  # Each column
                center_pxl = arr_padded[y][x]

                # X axis
                strongest_x_pos = center_pxl >= max(arr_padded[y, x-1:x+2])
                strongest_x_neg = center_pxl <= min(arr_padded[y, x-1:x+2])

                # Y axis
                strongest_y_pos = center_pxl >= max(arr_padded[y-1:y+2, x])
                strongest_y_neg = center_pxl <= min(arr_padded[y-1:y+2, x])

                # Preserve (copy from input to output array) only if edge
                # strength largest compared to adjacent pixels
                if (strongest_x_pos or strongest_x_neg or
                    strongest_y_pos or strongest_y_neg):
                    arr_thinned[y][x] = in_np_arr[y][x]

        self.log.debug(f"Edges thinned {arr_thinned.shape}:\n{arr_thinned}")
        return arr_thinned

    def apply_edge_tracking(self, in_np_arr):
        """
        Apply edge tracking using double-threshold hysteresis, to filter out
        spurious edges caused by noise and color variation, preserving only:
           * Strong edge pixels
           * Weak edge pixels connected to at least one strong edge pixel
        """

        self.log.info("Applying edge tracking using double-threshold " \
                      "hysteresis...")

        # Duplicate edge pixels to handle edges and corners of image
        arr_padded = np.pad(in_np_arr, (1, 1), "edge")
        self.log.debug(f"Edges padded {arr_padded.shape}:\n{arr_padded}")

        # For each pixel, preserve value if pixel meets high threshold
        strong_pxls = np.zeros(in_np_arr.shape, dtype=int)
        for y in range(1, in_np_arr.shape[0] - 1):  # Each row
            for x in range(1, in_np_arr.shape[1] - 1):  # Each column
                center_pxl = arr_padded[y][x]

                if (center_pxl > THRESH_HI) or (center_pxl < -THRESH_HI):
                    strong_pxls[y][x] = in_np_arr[y][x]  # Strong edge
        self.log.debug(f"Strong pixels {strong_pxls.shape}:\n{strong_pxls}")

        # For each pixel, preserve value if pixel meets low threshold and is
        # connected to at least one strong edge pixel
        weak_pxls = np.zeros(in_np_arr.shape, dtype=int)
        for y in range(1, in_np_arr.shape[0] - 1):  # Each row
            for x in range(1, in_np_arr.shape[1] - 1):  # Each column
                center_pxl = arr_padded[y][x]

                if strong_pxls[y][x] > 0:  # Already preserved as strong pixel
                    continue  # Connected weak pixel determination unnecessary
                elif (center_pxl > THRESH_LO) or (center_pxl < -THRESH_LO):
                    # Determine whether weak pixel is connected to at least one
                    # strong edge pixel
                    if np.any(strong_pxls[y-1:y+2, x-1:x+2]):
                        weak_pxls[y][x] = in_np_arr[y][x]  # Connected weak edge
        self.log.debug(f"Weak pixels {weak_pxls.shape}:\n{weak_pxls}")

        arr_edge_trk = strong_pxls + weak_pxls  # Merge arrays
        self.log.debug(f"Edge tracking {arr_edge_trk.shape}:\n{arr_edge_trk}")
        return arr_edge_trk

    def rectify_and_clip(self, np_arr):
        """
        Rectify negative pixel values and clip at maximum value for output of
        final edge pixel map.
        """

        self.log.info("Rectifying negative pixel values and clipping at " \
                      "maximum value for output...")

        # Rectify negative values, in place
        np_arr = np.abs(np_arr)

        # Clip at maximum grey value, in place
        for y in range(np_arr.shape[0]):  # Each row
            for x in range(np_arr.shape[1]):  # Each column
                np_arr[y][x] = min(np_arr[y][x], MAX_VAL)

        self.log.debug(f"Rectified and clipped {np_arr.shape}:\n{np_arr}")
        return np_arr

def main(argv):
    # Configure argument parser
    desc_str = "Applies an edge detection operator to an input greyscale " \
               "image, producing a new greyscale image file with detected " \
               "edges marked"
    parser = argparse.ArgumentParser(description=desc_str)
    parser.add_argument(
        "in_img_name",  # Positional argument
        type=str,
        action="store",
        help="Path to input image to perform edge detection on",
    )
    parser.add_argument(
        "out_img_name",  # Positional argument
        type=str,
        action="store",
        help="Desired name of output image file with detected edges marked",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enables verbose logging to facilitate debugging",
    )

    # Parse arguments and configure logger
    args = parser.parse_args()
    log.basicConfig(
        format=LOGGER_FMT,
        level=(log.DEBUG if args.verbose else log.INFO),
    )
    log.info("Parsing arguments...")
    for (arg, val) in sorted(vars(args).items()):
        log.info("   * {}: {}".format(arg, val))

    # Print current time
    log.info(time.strftime("%a %Y-%m-%d %I:%M:%S %p"))

    # Instantiate image edge detection library class
    edge_detect_lib = EdgeDetectLib(log.getLogger())

    # Open input file handle and convert input image to NumPy array
    in_np_arr = edge_detect_lib.convert_pgm_to_np_arr(args.in_img_name)

    # Apply Laplacian second derivative approximation kernel
    arr_conv = edge_detect_lib.apply_conv_kernel(
        in_np_arr=in_np_arr,
        conv_kernel_np=LAPLACIAN,
        kernel_desc="Laplacian second derivative approximation",
    )

    # Apply edge thinning using non-maximum suppression, to remove pixels not
    # considered to be part of an edge
    arr_thinned = edge_detect_lib.apply_edge_thinning(arr_conv)

    # Apply edge tracking using double-threshold hysteresis, to filter out
    # spurious edges caused by noise and color variation
    arr_edge_trk = edge_detect_lib.apply_edge_tracking(arr_thinned)

    # Rectify negative pixel values and clip at maximum value for output of
    # final edge pixel map
    arr_rect_clipped = edge_detect_lib.rectify_and_clip(arr_edge_trk)

    # Convert output NumPy array to output image
    edge_detect_lib.convert_np_arr_to_pgm(arr_rect_clipped, args.out_img_name)

    # Exit
    log.info("Done.")
    sys.exit(0)  # Success

# Execute 'main()' function
if (__name__ == "__main__"):
    main(sys.argv)

