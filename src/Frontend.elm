module Frontend exposing (Model, app)

import Browser.Dom
import Config as Conf
import Helpers as Help
import HexGrid
import Html exposing (Html)
import Html.Attributes as Hattr
import Html.Events as Hevent
import Html.Lazy as Hlazy
import Json.Decode as JD
import Lamdera as L
import Set
import String
import Styles
import Svg exposing (Svg)
import Svg.Attributes as Sattr
import Svg.Events as Sevent
import Task
import Time
import Types exposing (..)


type alias Model =
    FrontendModel


type alias Msg =
    FrontendMsg


{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.frontend is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    L.frontend
        { init = \_ _ -> init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "Hexdera"
                , body = [ view model ]
                }
        , subscriptions = subscriptions
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


init : ( Model, Cmd Msg )
init =
    let
        initialModel =
            Conf.initialFrontendModel Help.visibleTilesAround
    in
    ( { initialModel | cameraCenter = Help.cameraCenterForPoint initialModel.thisPlayer }
    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "game-shell")
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ThisPlayerPosition point ->
            ( { model
                | thisPlayer = point
                , visibleTiles = Help.visibleTilesAround point model.grid
              }
            , L.sendToBackend (PlayerMoved point)
            )

        Tick now ->
            let
                delta =
                    Help.timeSinceLastTick now model.lastTick

                ( currentX, currentY ) =
                    model.cameraCenter

                ( targetX, targetY ) =
                    Help.cameraCenterForPoint model.thisPlayer

                nextCameraCenter =
                    ( Help.approach currentX targetX delta
                    , Help.approach currentY targetY delta
                    )

                nextMoveCooldownRemaining =
                    max 0 (model.moveCooldownRemaining - delta)
            in
            ( { model
                | cameraCenter = nextCameraCenter
                , moveCooldownRemaining = nextMoveCooldownRemaining
                , lastTick = Just now
              }
            , Cmd.none
            )

        HoverPoint point ->
            ( { model | hoverPoint = point }, Cmd.none )

        ToggleObstacle point ->
            let
                occupiedPlayers =
                    Set.insert model.thisPlayer (Set.fromList model.otherPlayers)

                pointsInFog =
                    HexGrid.fogOfWarWithin model.thisPlayer (Set.intersect model.obstacles model.visibleTiles) model.visibleTiles

                isFogged =
                    Set.member point pointsInFog
            in
            if Set.member point occupiedPlayers || isFogged || HexGrid.distance model.thisPlayer point > Conf.placementRange then
                ( model, Cmd.none )

            else
                let
                    nextObstacles =
                        if Set.member point model.obstacles then
                            Set.remove point model.obstacles

                        else
                            Set.insert point model.obstacles
                in
                ( { model | obstacles = nextObstacles }
                , L.sendToBackend (ObstacleToggled point)
                )

        KeyPress key ->
            if model.moveCooldownRemaining > 0 then
                ( model, Cmd.none )

            else
                let
                    ( x, z ) =
                        model.thisPlayer

                    ( dx, dz ) =
                        case key of
                            "q" ->
                                ( -1, 0 )

                            "w" ->
                                ( 0, -1 )

                            "e" ->
                                ( 1, -1 )

                            "a" ->
                                ( -1, 1 )

                            "s" ->
                                ( 0, 1 )

                            "d" ->
                                ( 1, 0 )

                            _ ->
                                ( 0, 0 )

                    newPoint =
                        ( x + dx, z + dz )
                in
                if
                    HexGrid.contains newPoint model.grid
                        && not (Set.member newPoint model.obstacles)
                        && not (Set.member newPoint (Set.fromList model.otherPlayers))
                then
                    ( { model
                        | thisPlayer = newPoint
                        , visibleTiles = Help.shiftVisibleTiles model.grid ( dx, dz ) model.visibleTiles
                        , moveCooldownRemaining = Conf.movementCooldownMillis
                      }
                    , L.sendToBackend (PlayerMoved newPoint)
                    )

                else
                    ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
updateFromBackend msg model =
    case msg of
        WorldUpdated world ->
            ( { model
                | otherPlayers = world.players
                , obstacles = world.obstacles
              }
            , Cmd.none
            )

        YourPosition point ->
            ( { model
                | thisPlayer = point
                , visibleTiles = Help.visibleTilesAround point model.grid
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every Conf.gameTickMillis Tick


viewFogOfWar : Model -> Svg Msg
viewFogOfWar model =
    let
        viewportCenterX =
            toFloat Conf.viewportWidth / 2

        viewportCenterY =
            toFloat Conf.viewportHeight / 2

        ( cameraX, cameraY ) =
            model.cameraCenter

        otherPlayerPositions =
            Set.fromList model.otherPlayers

        cornersToStr corners =
            corners
                |> List.map (\( x, y ) -> String.fromFloat x ++ "," ++ String.fromFloat y)
                |> String.join " "

        layout =
            HexGrid.mkFlatTop Conf.hexSize Conf.hexSize (viewportCenterX - cameraX) (viewportCenterY - cameraY)

        pointsInFog =
            HexGrid.fogOfWarWithin model.thisPlayer (Set.intersect model.obstacles model.visibleTiles) model.visibleTiles

        renderPoint point =
            let
                ( centerX, centerY ) =
                    HexGrid.hexToPixel layout point

                gapScale =
                    0.996

                corners =
                    HexGrid.polygonCorners layout point

                scaledCorners =
                    corners
                        |> List.map (\( x, y ) -> ( centerX + (x - centerX) * gapScale, centerY + (y - centerY) * gapScale ))

                isFogged =
                    Set.member point pointsInFog
            in
            Svg.g
                [ Sevent.onMouseOver (HoverPoint point)
                , Sevent.onClick (ToggleObstacle point)
                ]
                -- ground and environment
                [ Svg.polygon
                    [ Sattr.points (cornersToStr <| scaledCorners)
                    , Sattr.fill <|
                        if Set.member point model.obstacles && isFogged then
                            "#c0392b"

                        else if Set.member point model.obstacles && model.hoverPoint == point && HexGrid.distance model.thisPlayer point <= Conf.placementRange then
                            "#c0392b"

                        else if Set.member point model.obstacles then
                            "#e74c3c"

                        else if isFogged then
                            "#bdbdbd"

                        else if model.hoverPoint == point && HexGrid.distance model.thisPlayer point <= Conf.placementRange then
                            "#f1c40f"

                        else
                            "white"
                    ]
                    []

                -- players
                , if point == model.thisPlayer then
                    Svg.circle
                        [ Sattr.cx (String.fromFloat centerX)
                        , Sattr.cy (String.fromFloat centerY)
                        , Sattr.r "18"
                        , Sattr.fill "#16a34a"
                        , Sattr.stroke "rgba(255, 255, 255, 0.55)"
                        , Sattr.strokeWidth "4"
                        ]
                        []

                  else if Set.member point otherPlayerPositions && not isFogged then
                    Svg.circle
                        [ Sattr.cx (String.fromFloat centerX)
                        , Sattr.cy (String.fromFloat centerY)
                        , Sattr.r "15"
                        , Sattr.fill "#8e44ad"
                        , Sattr.strokeWidth "0"
                        ]
                        []

                  else
                    Svg.text_ [] []
                ]
    in
    Svg.svg
        ([ Sattr.width (String.fromInt Conf.viewportWidth)
         , Sattr.height (String.fromInt Conf.viewportHeight)
         , Sattr.viewBox (String.join " " [ "0", "0", String.fromInt Conf.viewportWidth, String.fromInt Conf.viewportHeight ])
         ]
            ++ Styles.boardSvg
        )
        (List.map renderPoint (Set.toList model.visibleTiles))


viewFogOfWarDemo : Model -> Html Msg
viewFogOfWarDemo model =
    Html.div
        (Styles.gameShell
            ++ [ Hattr.id "game-shell"
               , Hattr.attribute "tabindex" "0"
               , Hevent.on "keydown" (JD.map KeyPress (JD.field "key" JD.string))
               ]
        )
        [ viewFogOfWar model
        , Html.div
            Styles.hudPanel
            [ Html.h3 Styles.hudLabel [ Html.text "Player" ]
            , Html.p Styles.hudValue
                [ Html.text
                    ("(" ++ String.fromInt (Tuple.first model.thisPlayer) ++ ", " ++ String.fromInt (Tuple.second model.thisPlayer) ++ ")")
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    Html.div
        Styles.pageRoot
        [ Hlazy.lazy viewFogOfWarDemo model

        -- , hr [] []
        ]
