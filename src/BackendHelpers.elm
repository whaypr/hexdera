module BackendHelpers exposing (..)

import Dict
import HexGrid
import Lamdera as L
import Set
import Types exposing (..)


worldUpdateForClient : L.ClientId -> BackendModel -> ToFrontend
worldUpdateForClient clientId model =
    WorldUpdated
        { players =
            Dict.toList model.players
                |> List.filter (\( otherClientId, _ ) -> otherClientId /= clientId)
                |> List.map Tuple.second
        , obstacles = model.obstacles
        }


broadcastWorldUpdate : BackendModel -> Cmd BackendMsg
broadcastWorldUpdate model =
    Dict.foldl
        (\clientId _ commands ->
            Cmd.batch
                [ commands
                , L.sendToFrontend clientId (worldUpdateForClient clientId model)
                ]
        )
        Cmd.none
        model.players


occupiedPositions : BackendModel -> Set.Set HexGrid.Point
occupiedPositions model =
    Dict.values model.players
        |> List.map .point
        |> Set.fromList


spawnPoint : BackendModel -> HexGrid.Point
spawnPoint model =
    let
        candidates =
            HexGrid.foldl (\point _ acc -> point :: acc) [] model.grid
                |> List.sortBy (HexGrid.distance ( 0, 0 ))

        blockedPositions =
            occupiedPositions model

        isFree point =
            not (Set.member point model.obstacles)
                && not (Set.member point blockedPositions)
    in
    candidates
        |> List.filter isFree
        |> List.head
        |> Maybe.withDefault ( 0, 0 )
