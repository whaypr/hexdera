module Backend exposing (Model, app)

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
            ( model, L.sendToFrontend clientId (WorldUpdated { activePoint = model.activePoint, obstacles = model.obstacles }) )

        ClientDisconnected _ _ ->
            ( model, Cmd.none )

        BNoOp ->
            ( model, Cmd.none )


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ _ msg model =
    case msg of
        PlayerMoved point ->
            if HexGrid.contains point model.grid && not (Set.member point model.obstacles) then
                let
                    nextModel =
                        { model | activePoint = point }
                in
                ( nextModel, L.broadcast (WorldUpdated { activePoint = nextModel.activePoint, obstacles = nextModel.obstacles }) )

            else
                ( model, Cmd.none )

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
            ( nextModel, L.broadcast (WorldUpdated { activePoint = nextModel.activePoint, obstacles = nextModel.obstacles }) )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ L.onConnect ClientConnected
        , L.onDisconnect ClientDisconnected
        ]
