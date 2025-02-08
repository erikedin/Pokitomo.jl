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

using Behavior

removecomment(s::AbstractString) = replace(s, r"#.*" => "")
removewhitespace(s::AbstractString) = replace(s, r"\s" => "")

# Parse binary contents as hexadecimal values
# Example:
#    01 23 45 # Comment
#    6789
# should be the binary values
#    0x01 0x23 0x45 0x67 0x89
function parsecontents(s::String) :: Vector{UInt8}
    # Step 0: Split the string into lines
    lines = split(s, "\n")

    # Step 1: Remove comments: strip everything following the first hash on each line
    # '12 34 # Comment' => '12 34 '
    #
    # Step 2: Also remove whitespace
    # '12 34 ' => '1234'
    stripped = [(l |> removecomment |> removewhitespace)
                for l in lines]

    # Step 3: Concatenate all lines
    hexadecimal = join(stripped)

    # Step 4: Convert from hexadecimal
    hex2bytes(hexadecimal)
end

@given("the contents in hexadecimal") do context
    hexadecimal = context[:block_text]

    bin = parsecontents(hexadecimal)

    io = IOBuffer(bin)
    context[:io] = io
end

@given("that the buffer position is at the end") do context
    io = context[:io]

    seekend(io)
end