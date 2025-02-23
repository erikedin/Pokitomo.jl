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
using Pokitomo

struct Hex
    t::Type
end

struct BytesFromHex end

readfield(h::Hex, s::String) = parse(h.t, replace(s, r"\s" => ""); base=16)
readfield(::Type{String}, s::String) = s
readfield(::BytesFromHex, s::String) = hex2bytes(s)

struct FieldVerification
    actualfield::Function
    parser
end

formatfields = Dict{String, FieldVerification}(
    "piece position" => FieldVerification(pi -> pi.pieceposition, Hex(UInt32)),
    "piece length" => FieldVerification(pi -> pi.piecelength, Hex(UInt32)),
    "piece type" => FieldVerification(pi -> pi.piecetype, Hex(UInt8)),
    "piece path length" => FieldVerification(pi -> pi.piecepathlength, Hex(UInt32)),
    "piece path" => FieldVerification(pi -> Pokitomo.Formats.piecepath(pi), String),
    "piece hash"  => FieldVerification(pi -> pi.piecehash, BytesFromHex()),
    "index size" => FieldVerification(idx -> idx.indexsize, Hex(UInt32)),
    "index hash" => FieldVerification(idx -> idx.indexhash, BytesFromHex()),
    "number of pieces" => FieldVerification(idx -> Pokitomo.Formats.numberofpieces(idx), Hex(UInt16)),
    "piece position in piece info 1" => FieldVerification(index -> index.pieceinfos[1].pieceposition, Hex(UInt32)),
    "piece length in piece info 1" => FieldVerification(index -> index.pieceinfos[1].piecelength, Hex(UInt32)),
    "piece type in piece info 1" => FieldVerification(index -> index.pieceinfos[1].piecetype, Hex(UInt8)),
    "piece path length in piece info 1" => FieldVerification(index -> index.pieceinfos[1].piecepathlength, Hex(UInt32)),
    "piece path in piece info 1" => FieldVerification(index -> Pokitomo.Formats.piecepath(index.pieceinfos[1]), String),
    "piece hash in piece info 1"  => FieldVerification(index -> index.pieceinfos[1].piecehash, BytesFromHex()),
    "piece position in piece info 2" => FieldVerification(index -> index.pieceinfos[2].pieceposition, Hex(UInt32)),
    "piece length in piece info 2" => FieldVerification(index -> index.pieceinfos[2].piecelength, Hex(UInt32)),
    "piece type in piece info 2" => FieldVerification(index -> index.pieceinfos[2].piecetype, Hex(UInt8)),
    "piece path length in piece info 2" => FieldVerification(index -> index.pieceinfos[2].piecepathlength, Hex(UInt32)),
    "piece path in piece info 2" => FieldVerification(index -> Pokitomo.Formats.piecepath(index.pieceinfos[2]), String),
    "piece hash in piece info 2"  => FieldVerification(index -> index.pieceinfos[2].piecehash, BytesFromHex()),
)

@given("the contents size is printed") do context
    blob = context[:blob]
    println("Size: $(length(blob))")
end


@when("reading a piece info") do context
    io = context[:io]

    pieceinfo = Pokitomo.Formats.PieceInfo(io)

    context[:object] = pieceinfo
end

@when("reading an index") do context
    io = context[:io]

    index = Pokitomo.Formats.Index(io)

    context[:object] = index
end

@when("writing a root chunk") do context
    pieces = context[:pieces]

    io = IOBuffer()

    chunk = Pokitomo.Formats.Chunk(pieces)
    write(io, chunk)

    # Clear the pieces list so that the next chunk written
    # will not include these. It should only include pieces added
    # after this write.
    context[:pieces] = Pokitomo.Formats.Piece[]

    context[:io] = io
end

@when("writing a chunk") do context
    pieces = context[:pieces]

    io = context[:io]

    chunk = Pokitomo.Formats.Chunk(io, pieces)
    write(io, chunk)

    # Clear the pieces list so that the next chunk written
    # will not include these. It should only include pieces added
    # after this write.
    context[:pieces] = Pokitomo.Formats.Piece[]

end

# The step reads a single piece of a file
@when("reading the piece at path \"{String}\"") do context, path
    io = context[:io]

    seekstart(io)
    actualdata = read(io, PokitomoFile, path)

    context[:data] = actualdata
end

@then("the file contents is \"{String}\"") do context, hexadecimaldata
    expecteddata = hex2bytes(hexadecimaldata)

    actualdata = context[:data]

    @expect actualdata == expecteddata
end

@then("the {String} has value {String}") do context, fieldname, stringvalue
    pieceinfo = context[:object]

    # FieldVerification describes what field to fetch from the object,
    # and how to interpret the stringvalue provided to this step.
    fieldverification = formatfields[fieldname]

    # Convert the stringvalue provided here to the expected type
    expected = readfield(fieldverification.parser, stringvalue)

    # Read the actual field from the object.
    actual = fieldverification.actualfield(pieceinfo)

    @expect expected == actual
end

@then("the index is a root index") do context
    index = context[:object]

    @expect Pokitomo.Formats.isrootindex(index)
end

@then("the actual index hash is printed") do context
    index = context[:object]

    actualhashinput = Pokitomo.Formats.indexhashinput(index)
    actualhash = Pokitomo.Formats.indexhash(index)
    hashstring = uppercase(bytes2hex(actualhash))

    println("Index: $(index)")
    println("Hash input: $(actualhashinput)")
    println("Input size: $(length(actualhashinput))")
    println("Index hash: $(hashstring)")
end

@then("the index is valid") do context
    index = context[:object]

    @expect Pokitomo.Formats.isvalid(index)
end

@then("the index is invalid") do context
    index = context[:object]

    @expect !Pokitomo.Formats.isvalid(index)
end