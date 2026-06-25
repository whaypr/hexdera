module Config exposing (..)

import Dict
import HexGrid
import Set exposing (Set)
import Types exposing (..)


defaultPlayerName : String
defaultPlayerName =
    ""


gridSize : Int
gridSize =
    30


hexSize : Float
hexSize =
    35


viewportWidth : Int
viewportWidth =
    600


viewportHeight : Int
viewportHeight =
    570


visibleRadius : Int
visibleRadius =
    ceiling (max (toFloat viewportWidth / (3 * hexSize)) (toFloat viewportHeight / (2 * sqrt 3 * hexSize))) - 1


cameraEaseMillis : Float
cameraEaseMillis =
    300


movementCooldownMillis : Float
movementCooldownMillis =
    200


gameTickMillis : Float
gameTickMillis =
    16


placementRange : Int
placementRange =
    2


initialGrid : HexGrid.HexGrid ()
initialGrid =
    HexGrid.empty gridSize ()


initialObstacles : Set HexGrid.Point
initialObstacles =
    Set.fromList
        [ ( -5, 4 )
        , ( -4, 3 )
        , ( -3, 2 )
        , ( -2, 1 )
        , ( -1, 1 )
        , ( -1, 2 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 1 )
        , ( 2, 0 )
        , ( 2, -1 )
        , ( 1, -1 )
        , ( 2, -2 )
        , ( -1, -1 )
        , ( 0, -2 )
        , ( 1, -3 )
        , ( 3, -4 )
        , ( 4, -4 )
        , ( 4, -3 )
        , ( -4, 0 )
        , ( -3, 0 )
        , ( 0, 3 )
        ]


initialFrontendModel : (HexGrid.Point -> HexGrid.HexGrid () -> Set HexGrid.Point) -> FrontendModel
initialFrontendModel visibleTilesFunc =
    { grid = initialGrid
    , thisPlayer = { name = "", point = ( 0, 0 ) }
    , playerNameConfirmed = False
    , hoverPoint = ( -1, -4 )
    , otherPlayers = []
    , obstacles = initialObstacles
    , visibleTiles = visibleTilesFunc ( 0, 0 ) initialGrid
    , pointsInFog = Set.empty
    , cameraCenter = ( 0, 0 )
    , moveCooldownRemaining = 0
    , lastTick = Nothing
    }


initialBackendModel : BackendModel
initialBackendModel =
    { grid = initialGrid
    , players = Dict.empty
    , obstacles = initialObstacles
    }
