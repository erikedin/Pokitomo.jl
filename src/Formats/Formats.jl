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

end # module Formats