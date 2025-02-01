# Structure
A Pokitomo file contains a number of chunks.
Each chunk contains one or more pieces of data, and ends with an index, telling the software where those pieces are located in the file.

## Piece
## Index
## Chunk
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

