module Backend exposing (Model, app)

import Dict
import Lamdera as L
import Set

import HexGrid
import Types exposing (..)


type alias Model =
    BackendModel


app =
    L.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( initialBackendModel, Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected _ clientId ->
            let
                spawn =
                    spawnPoint model

                nextModel =
                    { model | players = Dict.insert clientId spawn model.players }
            in
            ( nextModel
            , Cmd.batch
                [ L.sendToFrontend clientId (YourPosition spawn)
                , L.broadcast (worldUpdate nextModel)
                ]
            )

        ClientDisconnected _ clientId ->
            let
                nextModel =
                    { model | players = Dict.remove clientId model.players }
            in
            ( nextModel, L.broadcast (worldUpdate nextModel) )

        BNoOp ->
            ( model, Cmd.none )


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        PlayerMoved point ->
            let
                updatedModel =
                    { model | players = Dict.insert clientId point model.players }
            in
            ( updatedModel
            , Cmd.batch
                [ L.sendToFrontend clientId (YourPosition point)
                , L.broadcast (worldUpdate updatedModel)
                ]
            )

        ObstacleToggled point ->
            let
                nextObstacles =
                    if Set.member point model.obstacles then
                        Set.remove point model.obstacles

                    else
                        Set.insert point model.obstacles

                nextModel =
                    { model | obstacles = nextObstacles }
            in
            ( nextModel, L.broadcast (worldUpdate nextModel) )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ L.onConnect ClientConnected
        , L.onDisconnect ClientDisconnected
        ]


playerPositions : Model -> List HexGrid.Point
playerPositions model =
    Dict.values model.players


worldUpdate : Model -> ToFrontend
worldUpdate model =
    WorldUpdated
        { players = playerPositions model
        , obstacles = model.obstacles
        }


occupiedPositions : Model -> Set.Set HexGrid.Point
occupiedPositions model =
    Dict.values model.players
        |> Set.fromList


spawnPoint : Model -> HexGrid.Point
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
