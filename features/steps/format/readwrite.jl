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
using Pokitomo.Formats
using Random

const MAX_RANDOM_PIECE_SIZE = 1024*16

function randompiece(rng::AbstractRNG) :: Formats.Piece
    n = rand(rng, UInt) % MAX_RANDOM_PIECE_SIZE
    data = rand(rng, UInt8, n)
    Formats.Piece(data, "/")
end

@given("a PRNG seed {Int}") do context, seed
    context[:rng] = MersenneTwister(seed)
end

@given("{Int} repetitions of this scenario") do context, repetitions
    context[:repetitions] = repetitions
end

@given("a random piece of binary data") do context
    n = context[:repetitions]
    rng = context[:rng]

    pieces = [randompiece(rng) for _i = 1:n]
    context[:pieces] = pieces
end

@when("a file is written with the binary data") do context
    n = context[:repetitions]
    pieces = context[:pieces]

    writepiece = piece -> begin
        io = IOBuffer()
        chunk = Formats.Chunk([piece])
        write(io, chunk)
        io
    end

    ios = [writepiece(p) for p in pieces]
    context[:ios] = ios
end

@when("the file is read again") do context
    ios = context[:ios]

    readfile = io -> begin
        seekstart(io)
        read(io, PokitomoFile, "/")
    end

    rereads = [readfile(io) for io in ios]
    context[:rereads] = rereads
end

@then("the read binary data matches what was written") do context
    pieces = context[:pieces]
    rereads = context[:rereads]
    n = context[:repetitions]

    # Pre-condition: We wrote the same number of pieces
    # that we read back
    @expect length(pieces) == n
    @expect length(rereads) == n

    for (expectedpiece, actualdata) in zip(pieces, rereads)
        @expect expectedpiece.data == actualdata
    end
end