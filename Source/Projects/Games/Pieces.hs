unit Pieces
{
    const byte ShapeCount = 7;
    const byte RotationCount = 4;
    const byte PieceSize = 4;

    // Define the shapes and their rotations (4x4 grids stored in flat arrays)
    byte[ShapeCount * RotationCount * PieceSize * PieceSize] shapes = {
        // I piece
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 1, 1,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 1, 1,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        // J piece
        1, 0, 0, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 1, 0,
        0, 0, 1, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        0, 1, 0, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
    
        // L piece
        0, 0, 1, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 1, 0,
        1, 0, 0, 0,
        0, 0, 0, 0,
    
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        // O piece
        0, 1, 1, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 1, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 1, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 1, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        // S piece
        0, 1, 1, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 1, 0,
        0, 0, 0, 0,
    
        0, 0, 0, 0,
        0, 1, 1, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
    
        1, 0, 0, 0,
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        // T piece
        0, 1, 0, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        // Z piece
        1, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    
        0, 0, 1, 0,
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    
        0, 0, 0, 0,
        1, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
    
        0, 1, 0, 0,
        1, 1, 0, 0,
        1, 0, 0, 0,
        0, 0, 0, 0
    };
    
    byte currentShape;
    byte currentRotation;
    byte currentX;
    byte currentY;

    Initialize()
    {
        currentShape = RandomShape();
        currentRotation = 0;
        currentX = GameGrid.Width / 2 - 2;
        currentY = 0;
    }

    Rotate()
    {
        currentRotation = (currentRotation + 1) % RotationCount;
    }

    byte[PieceSize * PieceSize] GetCurrentShape()
    {
        byte startIdx = (currentShape * RotationCount + currentRotation) * PieceSize * PieceSize;
        byte[PieceSize * PieceSize] shape;
        for (byte i = 0; i < PieceSize * PieceSize; i++)
        {
            shape[i] = shapes[startIdx + i];
        }
        return shape;
    }

    bool IsValidPosition(byte x, byte y, byte[] shape)
    {
        for (byte i = 0; i < PieceSize; i++)
        {
            for (byte j = 0; j < PieceSize; j++)
            {
                if (shape[i + j * PieceSize] != 0)
                {
                    byte newX = x + i;
                    byte newY = y + j;
                    if (newX < 0 || newX >= GameGrid.Width || newY < 0 || newY >= GameGrid.Height || GameGrid.GetCell(newX, newY))
                    {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    PlaceCurrentShape()
    {
        byte[] shape = GetCurrentShape();
        for (byte i = 0; i < PieceSize; i++)
        {
            for (byte j = 0; j < PieceSize; j++)
            {
                if (shape[i + j * PieceSize] != 0)
                {
                    GameGrid.SetCell(currentX + i, currentY + j, true);
                }
            }
        }
    }

    byte RandomShape()
    {
        // Implement a simple random number generator or use a predefined sequence for testing
        return ((Time.Millis).GetByte(0) % ShapeCount);
    }
}

