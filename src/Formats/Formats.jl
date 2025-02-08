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

module Formats

struct PieceInfo
    pieceposition::UInt32
    piecelength::UInt32
    piecetype::UInt8
    piecepathlength::UInt32
    piecepath::String
    piecehash::Vector{UInt8}
end

function deserializestring(io::IO, n::Int) :: String
    data = read(io, n)
    newio = IOBuffer(data)
    read(newio, String)
end

const SHA3_256_LENGTH = 32

function PieceInfo(io::IO)
    pieceposition = read(io, UInt32)
    piecelength = read(io, UInt32)
    piecetype = read(io, UInt8)
    piecepathlength = read(io, UInt32)
    piecepath = deserializestring(io, convert(Int, piecepathlength))
    piecehash = read(io, SHA3_256_LENGTH)
    PieceInfo(pieceposition, piecelength, piecetype, piecepathlength, piecepath, piecehash)
end

struct Index
    pieceinfos::Vector{PieceInfo}
    pointertoprev::UInt32
    indexhash::Vector{UInt8}
    indexsize::UInt32
end

const INDEX_POSTAMBLE_SIZE = sizeof(UInt16) + sizeof(UInt32) + SHA3_256_LENGTH + sizeof(UInt32)

function Index(io::IO)
    startposition = position(io)
    seek(io, startposition - INDEX_POSTAMBLE_SIZE)

    numberpieces = read(io, UInt16)
    pointertoprev = read(io, UInt32)
    indexhash = read(io, SHA3_256_LENGTH)
    indexsize = read(io, UInt32)

    # Seek back to the beginning of the PieceInfo fields
    seek(io, startposition - indexsize)

    # Read `numberpieces` PieceInfo structs.
    pieceinfos = PieceInfo[]
    foreach(1:numberpieces) do _i
        pieceinfo = PieceInfo(io)
        push!(pieceinfos, pieceinfo)
    end

    Index(pieceinfos, pointertoprev, indexhash, indexsize)
end

isrootindex(index::Index) = true
numberofpieces(index::Index) = length(index.pieceinfos)

end # module Formats