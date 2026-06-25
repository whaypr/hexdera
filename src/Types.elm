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


type BlockKind
    = Wall
    | Hideout


type alias FrontendModel =
    { grid : HexGrid.HexGrid ()
    , thisPlayer : Player
    , playerNameConfirmed : Bool
    , selectedBlock : BlockKind
    , hoverPoint : HexGrid.Point
    , otherPlayers : List Player
    , walls : Set.Set HexGrid.Point
    , hideouts : Set.Set HexGrid.Point
    , visibleTiles : Set.Set HexGrid.Point
    , pointsInFog : Set.Set HexGrid.Point
    , cameraCenter : ( Float, Float )
    , moveCooldownRemaining : Float
    , lastTick : Maybe Posix
    }


type alias BackendModel =
    { grid : HexGrid.HexGrid ()
    , players : Dict L.ClientId Player
    , walls : Set.Set HexGrid.Point
    , hideouts : Set.Set HexGrid.Point
    }


type FrontendMsg
    = PlayerNameChanged String
    | ConfirmPlayerName
    | SelectBlock BlockKind
    | ThisPlayerPosition HexGrid.Point
    | HoverPoint HexGrid.Point
    | ToggleBlock HexGrid.Point
    | KeyPress String
    | Tick Posix
    | NoOp


type ToBackend
    = SetPlayerName String
    | PlayerMoved HexGrid.Point
    | BlockToggled BlockKind HexGrid.Point


type BackendMsg
    = ClientConnected L.SessionId L.ClientId
    | ClientDisconnected L.SessionId L.ClientId
    | BNoOp


type ToFrontend
    = WorldUpdated
        { players : List Player
        , walls : Set.Set HexGrid.Point
        , hideouts : Set.Set HexGrid.Point
        }
    | YourPosition HexGrid.Point
