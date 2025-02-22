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

module Pokitomo

include("Formats/Formats.jl")

export PokitomoFile

using Pokitomo.Formats: Chunk

struct PokitomoFile end

function Base.read(io::IO, ::Type{PokitomoFile}, path::String)
    # TODO: Implement more. For now, just read a single chunk.
    seekend(io)
    chunk = Chunk(io)
    # TODO: For now just read take the first piece that matches the path.
    # Later on, we'll need to read files that are split into more than one piece.
    pieceindex = findfirst(p -> p.path == path, chunk.pieces)
    if pieceindex === nothing
        throw(ArgumentError("No piece found a path $(path)"))
    end
    piece = chunk.pieces[pieceindex]
    piece.data
end

end # module Pokitomo
