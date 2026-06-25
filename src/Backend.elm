module Backend exposing (Model, app)

import BackendHelpers as Help
import Config as Conf
import Dict
import Lamdera as L
import Set
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
    ( Conf.initialBackendModel, Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected _ clientId ->
            let
                spawn =
                    Help.spawnPoint model

                nextPlayer =
                    { name = Conf.defaultPlayerName, point = spawn }

                nextModel =
                    { model | players = Dict.insert clientId nextPlayer model.players }
            in
            ( nextModel
            , Cmd.batch
                [ L.sendToFrontend clientId (YourPosition spawn)
                , Help.broadcastWorldUpdate nextModel
                ]
            )

        ClientDisconnected _ clientId ->
            let
                nextModel =
                    { model | players = Dict.remove clientId model.players }
            in
            ( nextModel, Help.broadcastWorldUpdate nextModel )

        BNoOp ->
            ( model, Cmd.none )


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        SetPlayerName name ->
            case Dict.get clientId model.players of
                Nothing ->
                    ( model, Cmd.none )

                Just player ->
                    let
                        nextModel =
                            { model | players = Dict.insert clientId { player | name = name } model.players }
                    in
                    ( nextModel, Help.broadcastWorldUpdate nextModel )

        PlayerMoved point ->
            case Dict.get clientId model.players of
                Nothing ->
                    ( model, Cmd.none )

                Just player ->
                    let
                        updatedModel =
                            { model | players = Dict.insert clientId { player | point = point } model.players }
                    in
                    ( updatedModel
                    , Cmd.batch
                        [ L.sendToFrontend clientId (YourPosition point)
                        , Help.broadcastWorldUpdate updatedModel
                        ]
                    )

        ObstacleToggled point ->
            case Dict.get clientId model.players of
                Nothing ->
                    ( model, Cmd.none )

                Just _ ->
                    let
                        nextObstacles =
                            if Set.member point model.obstacles then
                                Set.remove point model.obstacles

                            else
                                Set.insert point model.obstacles

                        nextModel =
                            { model | obstacles = nextObstacles }
                    in
                    ( nextModel, Help.broadcastWorldUpdate nextModel )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ L.onConnect ClientConnected
        , L.onDisconnect ClientDisconnected
        ]
