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
    context[:blob] = bin
    context[:io] = io
end

@given("that the buffer position is at the end") do context
    io = context[:io]

    seekend(io)
end

@given("a piece with hexadecimal contents at path \"{String}\"") do context, path
    hexadecimal = context[:block_text]

    bin = parsecontents(hexadecimal)

    if !haskey(context, :pieces)
        context[:pieces] = Pokitomo.Formats.Piece[]
    end

    pieces = context[:pieces]
    push!(pieces, Pokitomo.Formats.Piece(bin, path))
    context[:pieces] = pieces
end

@then("the contents without the index hash is printed in Julia format") do context
    io = context[:io]

    bin = read(io)

    beforehash = bin[1:end-4-32]
    afterhash = bin[end-4+1:end]
    wohash = vcat(beforehash, afterhash)

    show(wohash)
end

function partitiontostring(collection, row, n)
    if row <= length(collection)
        a = collection[row]
        bytes2hex(a)
    else
        repeat(' ', 2*n)
    end
end

@then("the result in hexadecimal is") do context
    hexadecimal = context[:block_text]
    expectedbin = parsecontents(hexadecimal)

    io = context[:io]
    seekstart(io)

    actual = read(io)

    if actual != expectedbin
        # Pretty print the arrays for convenience
        println("Actual size  : $(length(actual))")
        println("Expected size: $(length(expectedbin))")
        println("Actual              Expected")

        n = 4

        actualpartition = collect(Iterators.partition(actual, n))
        expectedpartition = collect(Iterators.partition(expectedbin, n))

        row = 1
        while row <= length(actualpartition) || row <= length(expectedpartition)
            a = partitiontostring(actualpartition, row, n)
            b = partitiontostring(expectedpartition, row, n)

            println("$(a)    $(b)")

            row += 1
        end
    end

    @expect actual == expectedbin
end