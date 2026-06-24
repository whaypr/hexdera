module Types exposing (..)

import Dict exposing (Dict)
import HexGrid
import Lamdera as L
import Set
import Time exposing (Posix)


type alias FrontendModel =
    { grid : HexGrid.HexGrid ()
    , thisPlayer : HexGrid.Point
    , hoverPoint : HexGrid.Point
    , otherPlayers : List HexGrid.Point
    , obstacles : Set.Set HexGrid.Point
    , visibleTiles : Set.Set HexGrid.Point
    , cameraCenter : ( Float, Float )
    , moveCooldownRemaining : Float
    , lastTick : Maybe Posix
    }


type alias BackendModel =
    { grid : HexGrid.HexGrid ()
    , players : Dict L.ClientId HexGrid.Point
    , obstacles : Set.Set HexGrid.Point
    }


type FrontendMsg
    = ThisPlayerPosition HexGrid.Point
    | HoverPoint HexGrid.Point
    | ToggleObstacle HexGrid.Point
    | KeyPress String
    | Tick Posix
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
        { players : List HexGrid.Point
        , obstacles : Set.Set HexGrid.Point
        }
    | YourPosition HexGrid.Point
