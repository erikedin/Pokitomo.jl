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

    Scenario: Writing a root chunk with two pieces
        Given a piece with hexadecimal contents at path "/a"
            """
            2A
            """
          And a piece with hexadecimal contents at path "/b"
            """
            2B
            """
         When writing a root chunk
         Then the result in hexadecimal is
            """
            # Piece 1
            2A              # Decimal 42, the contents of the first piece

            # Piece 2
            2B              # Decimal 43, the contents of the second piece

            # Piece info 1, belonging to the index
            00 00 00 00     # Piece position, starts at offset 0 in the file
            01 00 00 00     # Piece length is 1 byte
            00              # Piece type is 0: raw binary
            02 00 00 00     # Piece path length is 2
            2F 61           # /a: The piece path
            82283B4B030589A7AA0CA28B8E933AC0BD89738A0DF509806C864366DEEC31D7 # Hash of the byte 42

            # Piece info 2, belonging to the index
            01 00 00 00     # Piece position, starts at offset 1 in the file
            01 00 00 00     # Piece length is 1 byte
            00              # Piece type is 0: raw binary
            02 00 00 00     # Piece path length is 2
            2F 62           # /b: The piece path
            797D7BC8705BCD69863385ECFA78454D6DD6CAB3822A1A49D837A60E8845BC4A # Hash of the byte 43

            # Index
            02 00           # Number of pieces
            00 00 00 80     # Indicates that this is a root index
            CD0B18E2AE3F0291FB041435E83502C580CE443A1DF67D645179B0845E5C7966 # Index hash
            88 00 00 00     # Index size, 46 bytes from piece info, 42 from the index
            """

    Scenario Outline: Write three pieces and read them back
        Given a piece with hexadecimal contents at path "/a"
            """
            2A
            """
          And a piece with hexadecimal contents at path "/b"
            """
            2B
            """
          And a piece with hexadecimal contents at path "/c"
            """
            2C
            """
         When writing a root chunk
          And reading the piece at path "<path>"
         Then the file contents is "<data>"

        Examples:
            | path | data |
            |   /a | 2A   |
            |   /b | 2B   |
            |   /c | 2C   |

      Scenario Outline: Writing two chunks
        Given a piece with hexadecimal contents at path "/a"
            """
            2A
            """
          And writing a root chunk
          And a piece with hexadecimal contents at path "/b"
            """
            2B
            """
          And writing a chunk
         When reading the piece at path "<path>"
         Then the file contents is "<data>"

        Examples:
            | path | data |
            |   /a | 2A   |
            |   /b | 2B   |