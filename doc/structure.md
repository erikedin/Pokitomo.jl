# Structure
A Pokitomo file contains a number of chunks.
Each chunk contains one or more pieces of data, and ends with an index, telling the software where those pieces are located in the file.

# A Pokitomo file

```mermaid
block-beta
    block
        columns 1
        Chunk1["Chunk 1"]
        Chunk2["Chunk 2"]
        ...
        ChunkN["Chunk N"]
    end
```
## Chunk
Each chunk has one or more pieces. Each piece contains some data that the user stores.
Each chunk ends with an index that keeps track of where each piece is in the file.

```mermaid
block-beta
    block
        columns 1
        Piece1["Piece 1"]
        Piece2["Piece 2"]
        ...
        PieceN["Piece N"]
        Index
    end
```


## Piece
Just a blob of binary data. Position and length is stored in the index.

## Index
```mermaid
block-beta
    block
        columns 1
        Piece1Info["Piece 1 info"]
        Piece2Info["Piece 2 info"]
        ...
        PieceNInfo["Piece N info"]
        IndexHash["Index SHA3-256 hash"]
        IndexSize["Index size: 4 bytes"]
    end
```

The index hash depends on:
- Each piece hash
- Each piece position
- Each piece length
- Each piece type

## Piece info
```mermaid
block-beta
    block
        columns 1
        PiecePosition["Piece position"]
        PieceLength["Piece length"]
        PieceType["Piece type"]
        PieceHash["Piece SHA3-256 hash"]
    end
```

Piece type is one of:
- Binary blob
- Key-value pairs

The piece hash is the SHA3-256 hash of the binary data in the piece.

## Multiple chunks in a file
```mermaid
block-beta
    block
        columns 1
        block
            columns 1
            Piece1["Piece 1"]
            Index1["Index 1"]
        end
        block
            columns 1
            Piece2["Piece 1"]
            Index2["Index 2"]
        end
    end
```

A sidenote is that each piece is indexed in its own chunk. That is, there are two "Piece 1" in the above file,
because each is index 1 in their own chunk.

# Examples
## A minimal file

```mermaid
block-beta
    block
        block
            columns 1
            Piece1["Piece 1"]
            Index
        end
    end
```

## The same minimal file with all pieces written out
```mermaid
block-beta
    block
        block
            columns 1
            Piece1["Piece 1"]
            PiecePosition["Piece 1 position"]
            PieceLength["Piece 1 length"]
            PieceType["Piece 1 type"]
            PieceHash["Piece 1 SHA3-256 hash"]
            IndexHash["Index SHA3-256 hash"]
            IndexSize["Index size: 4 bytes"]
        end
    end
```

## A Pokitomo file with two chunks
```mermaid
block-beta
    block
        columns 1
        block
            columns 1
            Piece11["Piece 1"]
            Piece12["Piece 2"]
            ...
            Piece1N["Piece N"]
            Index1["Index 1"]
        end
        block
            columns 1
            Piece21["Piece 1"]
            Piece22["Piece 2"]
            ....["..."]
            Piece2N["Piece N"]
            Index2["Index 2"]
        end
    end
```
