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

using Pokitomo.Formats: Chunk, Piece, isroot

struct PokitomoFile end

struct NoPieceFoundError <: Exception
    path::String
end

function findpiece(chunk::Chunk, path::String) :: Union{Nothing, Piece}
    pieceindex = findfirst(p -> p.path == path, chunk.pieces)
    ispiecefound = pieceindex !== nothing

    if ispiecefound
        chunk.pieces[pieceindex]
    else
        nothing
    end
end

function nextchunk(io::IO, chunk::Chunk) :: Chunk
    prevchunk = chunk.index.pointertoprev
    seek(io, prevchunk)
    Chunk(io)
end

function findpiece(io::IO, path::String) :: Piece
    seekend(io)
    chunk = Chunk(io)
    morechunksavailable = true

    while morechunksavailable
        piece = findpiece(chunk, path)
        if piece !== nothing
            return piece
        end
        morechunksavailable = !isroot(chunk)

        if morechunksavailable
            chunk = nextchunk(io, chunk)
        end
    end

    throw(NoPieceFoundError(path))
end

function Base.read(io::IO, ::Type{PokitomoFile}, path::String)
    piece = findpiece(io, path)
    piece.data
end

end # module Pokitomo
