module HexGridTests exposing (suite)

import Expect
import HexGrid exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "HexGrid"
        [ test "toPoint builds a point tuple" <|
            \_ ->
                Expect.equal (toPoint 1 2) ( 1, 2 )
        , test "axialToCube converts axial to cube coordinates" <|
            \_ ->
                Expect.equal (axialToCube ( 1, 2 )) ( 1, -3, 2 )
        , test "rotate Right rotates a point clockwise" <|
            \_ ->
                Expect.equal (rotate Right ( 1, 2 )) ( -2, 3 )
        , test "rotate Left rotates a point counter-clockwise" <|
            \_ ->
                Expect.equal (rotate Left ( 1, 2 )) ( 3, -1 )
        , test "contains returns True for center point in radius 5" <|
            \_ ->
                Expect.equal (contains ( 0, 0 ) (empty 5 ())) True
        , test "contains returns False for out-of-radius point" <|
            \_ ->
                Expect.equal (contains ( 6, 0 ) (empty 5 ())) False
        , test "neighbors returns six adjacent cells" <|
            \_ ->
                Expect.equal
                    (neighbors ( 0, 0 ))
                    [ toPoint 1 0, toPoint 1 -1, toPoint 0 -1, toPoint -1 0, toPoint -1 1, toPoint 0 1 ]
        , test "distance between adjacent cells is 1" <|
            \_ ->
                Expect.equal (distance ( 0, 0 ) ( 1, 0 )) 1
        , test "range 1 around origin contains 7 points" <|
            \_ ->
                Expect.equal (List.length (range 1 ( 0, 0 ))) 7
        , test "height for radius 5 is 11" <|
            \_ ->
                Expect.equal (height (empty 5 ())) 11
        , test "equal considers two empty grids equal" <|
            \_ ->
                Expect.equal (equal (empty 3 ()) (empty 3 ())) True
        ]
