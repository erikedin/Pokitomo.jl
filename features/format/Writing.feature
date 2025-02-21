# MIT License
#
# Copyright (c) 2025 Erik Edin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

Feature: Writing

    Scenario: Writing a root chunk with a single piece
        Given a piece with hexadecimal contents at path "/"
            """
            2A
            """
         When writing a root chunk
         Then the result in hexadecimal is
            """
            # Piece 1
            2A              # Decimal 42, the contents of the first and only piece

            # Piece info 1, belonging to the index
            00 00 00 00     # Piece position, starts at offset 0 in the file
            01 00 00 00     # Piece length is 1 byte
            00              # Piece type is 0: raw binary
            01 00 00 00     # Piece path length is 1: The path is /
            2F              # /: The piece path
            82283B4B030589A7AA0CA28B8E933AC0BD89738A0DF509806C864366DEEC31D7 # Hash of the byte 42

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Indicates that this is a root index
            3AD001EB69F41C4F164915AAB95B142060900060AFADCC010346C7A8D34442EC # Index hash
            58 00 00 00     # Index size, 46 bytes from piece info, 42 from the index
            """