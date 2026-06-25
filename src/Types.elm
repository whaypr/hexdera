module Types exposing (..)

import Dict exposing (Dict)
import HexGrid
import Lamdera as L
import Set
import Time exposing (Posix)


type alias Player =
    { name : String
    , point : HexGrid.Point
    }


type alias FrontendModel =
    { grid : HexGrid.HexGrid ()
    , thisPlayer : Player
    , playerNameConfirmed : Bool
    , hoverPoint : HexGrid.Point
    , otherPlayers : List Player
    , obstacles : Set.Set HexGrid.Point
    , visibleTiles : Set.Set HexGrid.Point
    , pointsInFog : Set.Set HexGrid.Point
    , cameraCenter : ( Float, Float )
    , moveCooldownRemaining : Float
    , lastTick : Maybe Posix
    }


type alias BackendModel =
    { grid : HexGrid.HexGrid ()
    , players : Dict L.ClientId Player
    , obstacles : Set.Set HexGrid.Point
    }


type FrontendMsg
    = PlayerNameChanged String
    | ConfirmPlayerName
    | ThisPlayerPosition HexGrid.Point
    | HoverPoint HexGrid.Point
    | ToggleObstacle HexGrid.Point
    | KeyPress String
    | Tick Posix
    | NoOp


type ToBackend
    = SetPlayerName String
    | PlayerMoved HexGrid.Point
    | ObstacleToggled HexGrid.Point


type BackendMsg
    = ClientConnected L.SessionId L.ClientId
    | ClientDisconnected L.SessionId L.ClientId
    | BNoOp


type ToFrontend
    = WorldUpdated
        { players : List Player
        , obstacles : Set.Set HexGrid.Point
        }
    | YourPosition HexGrid.Point
