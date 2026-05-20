module Types exposing (..)

import Lamdera as L
import Set

import HexGrid


type alias FrontendModel =
    { grid : HexGrid.HexGrid ()
    , activePoint : HexGrid.Point
    , hoverPoint : HexGrid.Point
    , obstacles : Set.Set HexGrid.Point
    }


type alias BackendModel =
    { grid : HexGrid.HexGrid ()
    , activePoint : HexGrid.Point
    , obstacles : Set.Set HexGrid.Point
    }


type FrontendMsg
    = ActivePoint HexGrid.Point
    | HoverPoint HexGrid.Point
    | ToggleObstacle HexGrid.Point
    | KeyPress String
    | NoOp


type ToBackend
    = PlayerMoved HexGrid.Point
    | ObstacleToggled HexGrid.Point


type BackendMsg
    = ClientConnected L.SessionId L.ClientId
    | ClientDisconnected L.SessionId L.ClientId
    | BNoOp


type ToFrontend
    = WorldUpdated
        { activePoint : HexGrid.Point
        , obstacles : Set.Set HexGrid.Point
        }


initialGrid : HexGrid.HexGrid ()
initialGrid =
    HexGrid.empty 5 ()


initialObstacles : Set.Set HexGrid.Point
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


initialFrontendModel : FrontendModel
initialFrontendModel =
    { grid = initialGrid
    , activePoint = ( 0, 0 )
    , hoverPoint = ( -1, -4 )
    , obstacles = initialObstacles
    }


initialBackendModel : BackendModel
initialBackendModel =
    { grid = initialGrid
    , activePoint = ( 0, 0 )
    , obstacles = initialObstacles
    }
