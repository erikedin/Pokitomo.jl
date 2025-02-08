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

Feature: PieceInfo format

    Scenario Outline: Reading piece info fields
        Given the contents in hexadecimal
            """
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash
            """
         When reading a piece info
         Then the <field> has value <value>

      Examples:
        | field               | value    |
        | piece position      | 03020100 |
        | piece length        | 07060504 |
        | piece type          | 00       |
        | piece path length   | 00000001 |
        | piece path          | /        |
        | piece hash          | A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A |


    Scenario Outline: Reading an index
        The buffer position is expected to be after the end of the index.
        That way, one can seek back 4 bytes and find the index size, from which we
        can read the rest.

        Given the contents in hexadecimal
            """
            # Piece info 1
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Pointer to previous index, the high bit indicates the root index
            FB11D1A79C558AC16FFD59B748F6393F5681FF0905D5F5E81431A2AC85A9C457 # SHA3-256 hash
            58 00 00 00     # Index size, including piece info 1 (46 + 42 = 88)
            """
          And that the buffer position is at the end
         When reading an index
         Then the <field> has value <value>
          And the index is a root index

      Examples:
            | field            | value       |
            | index size       | 00 00 00 58 |
            | number of pieces | 1           |
            | index hash       | FB11D1A79C558AC16FFD59B748F6393F5681FF0905D5F5E81431A2AC85A9C457 |
            | piece position in piece info 1     | 03 02 01 00 |
            | piece length in piece info 1       | 07060504 |
            | piece type in piece info 1         | 00       |
            | piece path length in piece info 1  | 00000001 |
            | piece path in piece info 1         | /        |
            | piece hash in piece info 1         | A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A |

    Scenario: The index can be validated using the SHA3 hash
        Given the contents in hexadecimal
            """
            # Piece info 1
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Pointer to previous index, the high bit indicates the root index
            FB11D1A79C558AC16FFD59B748F6393F5681FF0905D5F5E81431A2AC85A9C457 # SHA3-256 hash
            58 00 00 00     # Index size, including piece info 1 (46 + 42 = 88)
            """
          And that the buffer position is at the end
         When reading an index
         Then the index is valid

    Scenario: The index can be found to be invalid
        Given the contents in hexadecimal
            """
            # Piece info 1
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Pointer to previous index, the high bit indicates the root index
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash (invalid)
            58 00 00 00     # Index size, including piece info 1 (46 + 42 = 88)
            """
          And that the buffer position is at the end
         When reading an index
         Then the index is invalid

    @wip
    Scenario: Helper scenario to calculate the actual hash of an index
        Given the contents in hexadecimal
            """
            # Piece info 1
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Pointer to previous index, the high bit indicates the root index
            FB11D1A79C558AC16FFD59B748F6393F5681FF0905D5F5E81431A2AC85A9C457 # SHA3-256 hash
            58 00 00 00     # Index size, including piece info 1 (46 + 42 = 88)
            """
          And that the buffer position is at the end
         When reading an index
         Then the actual index hash is printed

    @wip
    Scenario: Helper scenario to print the below hexadecimal values in a Julia friendly format
        Given the contents in hexadecimal
            """
            # Piece info 1
            00 01 02 03     # Piece position
            04 05 06 07     # Piece length
            00              # Piece type
            01 00 00 00     # Piece path length
            2F              # / (piece path)
            A7FFC6F8BF1ED76651C14756A061D662F580FF4DE43B49FA82D80A4B80F8434A # SHA3-256 hash

            # Index
            01 00           # Number of pieces
            00 00 00 80     # Pointer to previous index, the high bit indicates the root index
            FB11D1A79C558AC16FFD59B748F6393F5681FF0905D5F5E81431A2AC85A9C457 # SHA3-256 hash
            58 00 00 00     # Index size, including piece info 1 (46 + 42 = 88)
            """
         Then the contents without the index hash is printed in Julia format