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

using SHA

struct Piece
    data::Vector{UInt8}
    path::String
end

struct PieceInfo
    pieceposition::UInt32
    piecelength::UInt32
    piecetype::UInt8
    piecepathlength::UInt32
    piecepath::Vector{UInt8}
    piecehash::Vector{UInt8}
end

piecepath(p::PieceInfo) = String(p.piecepath)

function Piece(io::IO, pieceinfo::PieceInfo)
    position = pieceinfo.pieceposition
    seek(io, position)

    n = pieceinfo.piecelength
    data = read(io, n)

    Piece(data, piecepath(pieceinfo))
end

const SHA3_256_LENGTH = 32

function serializestring(path::String) :: Vector{UInt8}
    io = IOBuffer()
    write(io, path)
    seekstart(io)
    read(io)
end

function PieceInfo(p::Piece, pieceposition::UInt32)
    piecelength = UInt32(length(p.data))

    # TODO: Piece type is raw binary, the only supported type for now
    piecetype = UInt8(0)

    piecepathlength = UInt32(length(p.path))
    piecepathbinary = serializestring(p.path)

    piecehash = SHA.sha3_256(p.data)

    PieceInfo(pieceposition,
              piecelength,
              piecetype,
              piecepathlength,
              piecepathbinary,
              piecehash)
end

function PieceInfo(io::IO)
    pieceposition = read(io, UInt32)
    piecelength = read(io, UInt32)
    piecetype = read(io, UInt8)
    piecepathlength = read(io, UInt32)
    piecepath = read(io, piecepathlength)
    piecehash = read(io, SHA3_256_LENGTH)
    PieceInfo(pieceposition, piecelength, piecetype, piecepathlength, piecepath, piecehash)
end

function Base.write(io::IO, p::PieceInfo)
    write(io, p.pieceposition)
    write(io, p.piecelength)
    write(io, p.piecetype)
    write(io, p.piecepathlength)
    write(io, p.piecepath)
    write(io, p.piecehash)
end

function pieceinfosize(p::PieceInfo) :: UInt32
    FIXED_PART = (
        4 +     # Piece position
        4 +     # Piece length
        1 +     # Piece type
        4 +     # Piece path length
        32      # Piece hash
    )

    FIXED_PART + p.piecepathlength
end

function pieceinfossize(pieceinfos::Vector{PieceInfo}) :: UInt32
    sum([pieceinfosize(p) for p in pieceinfos])
end

struct Index
    pieceinfos::Vector{PieceInfo}
    pointertoprev::UInt32
    indexhash::Vector{UInt8}
    indexsize::UInt32
end

# This size is the fixed size part of the index. It is everything following the pieceinfos.
const INDEX_POSTAMBLE_SIZE = sizeof(UInt16) + sizeof(UInt32) + SHA3_256_LENGTH + sizeof(UInt32)

function Index(pieces::Vector{Piece})
    pieceinfos = PieceInfo[]
    currentposition = 0
    for p in pieces
        pinfo = PieceInfo(p, UInt32(currentposition))
        push!(pieceinfos, pinfo)

        currentposition += length(p.data)
    end

    # TODO: Only root index for now
    previndex = UInt32(0x80000000)

    indexsize = UInt32(pieceinfossize(pieceinfos) + INDEX_POSTAMBLE_SIZE)

    hash = indexhash(pieceinfos, previndex, indexsize)

    Index(pieceinfos, previndex, hash, indexsize)
end

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

function Base.write(io::IO, index::Index)
    foreach(index.pieceinfos) do p
        write(io, p)
    end
    write(io, UInt16(numberofpieces(index)))
    write(io, index.pointertoprev)
    write(io, index.indexhash)
    write(io, index.indexsize)
end

_r(v::T) where {T <: Unsigned} = reinterpret(NTuple{sizeof(T), UInt8}, v)

function pieceinfohashinput(p::PieceInfo) :: Vector{UInt8}
    UInt8[
        _r(p.pieceposition)...,
        _r(p.piecelength)...,
        _r(p.piecetype)...,
        _r(p.piecepathlength)...,
        p.piecepath...,
        p.piecehash...,
    ]
end

function indexhashinput(pieceinfos::Vector{PieceInfo}, pointertoprev::UInt32, indexsize::UInt32) :: Vector{UInt8}
    bin = UInt8[]
    foreach(pieceinfos) do p
        append!(bin, pieceinfohashinput(p))
    end

    # Convert numberofpieces to UInt16, which is its representation on disk
    numberpieces = convert(UInt16, length(pieceinfos))
    append!(bin, _r(numberpieces))
    append!(bin, _r(pointertoprev))
    append!(bin, _r(indexsize))

    bin
end

function indexhashinput(index::Index) :: Vector{UInt8}
    indexhashinput(index.pieceinfos, index.pointertoprev, index.indexsize)
end

function indexhash(index::Index) :: Vector{UInt8}
    hashinput = indexhashinput(index)
    SHA.sha3_256(hashinput)
end

function indexhash(pieceinfos::Vector{PieceInfo}, pointertoprev::UInt32, indexsize::UInt32) :: Vector{UInt8}
    hashinput = indexhashinput(pieceinfos, pointertoprev, indexsize)
    SHA.sha3_256(hashinput)
end

function isvalid(index::Index) :: Bool
    suppliedhash = index.indexhash
    calculatedhash = indexhash(index)

    suppliedhash == calculatedhash
end

#
# Chunks
#

struct Chunk
    pieces::Vector{Piece}
    index::Index
end

function Chunk(pieces::Vector{Piece})
    index = Index(pieces)
    Chunk(pieces, index)
end

function Chunk(io::IO)
    index = Index(io)
    pieces = [Piece(io, pieceinfo)
              for pieceinfo in index.pieceinfos]

    Chunk(pieces, index)
end

function Base.write(io::IO, chunk::Chunk)
    foreach(chunk.pieces) do piece
        write(io, piece.data)
    end
    write(io, chunk.index)
end

end # module Formats