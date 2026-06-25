module Frontend exposing (Model, app)

import Browser.Dom
import Config as Conf
import Dict
import FrontendHelpers as Help
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
                |> Help.withPointsInFog
    in
    ( { initialModel | cameraCenter = Help.cameraCenterForPoint initialModel.thisPlayer.point }
    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "player-name-input")
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayerNameChanged name ->
            ( { model
                | thisPlayer = { name = name, point = model.thisPlayer.point }
              }
            , Cmd.none
            )

        ConfirmPlayerName ->
            let
                confirmedName =
                    String.trim model.thisPlayer.name
            in
            if String.isEmpty confirmedName then
                ( model, Cmd.none )

            else
                ( { model
                    | thisPlayer = { name = confirmedName, point = model.thisPlayer.point }
                    , playerNameConfirmed = True
                  }
                , Cmd.batch
                    [ L.sendToBackend (SetPlayerName confirmedName)
                    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "game-shell")
                    ]
                )

        NoOp ->
            ( model, Cmd.none )

        ThisPlayerPosition point ->
            ( { model
                | thisPlayer = { name = model.thisPlayer.name, point = point }
                , visibleTiles = Help.visibleTilesAround point model.grid
              }
                |> Help.withPointsInFog
            , L.sendToBackend (PlayerMoved point)
            )

        Tick now ->
            let
                delta =
                    Help.timeSinceLastTick now model.lastTick

                ( currentX, currentY ) =
                    model.cameraCenter

                ( targetX, targetY ) =
                    Help.cameraCenterForPoint model.thisPlayer.point

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
                    Set.insert model.thisPlayer.point (Set.fromList (List.map .point model.otherPlayers))

                isFogged =
                    Set.member point model.pointsInFog
            in
            if Set.member point occupiedPlayers || isFogged || HexGrid.distance model.thisPlayer.point point > Conf.placementRange then
                ( model, Cmd.none )

            else
                let
                    nextObstacles =
                        if Set.member point model.obstacles then
                            Set.remove point model.obstacles

                        else
                            Set.insert point model.obstacles

                    nextModel =
                        { model | obstacles = nextObstacles }
                            |> Help.withPointsInFog
                in
                ( nextModel
                , L.sendToBackend (ObstacleToggled point)
                )

        KeyPress key ->
            if model.moveCooldownRemaining > 0 then
                ( model, Cmd.none )

            else
                let
                    ( x, z ) =
                        model.thisPlayer.point

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
                        && not (Set.member newPoint (Set.fromList (List.map .point model.otherPlayers)))
                then
                    ( { model
                        | thisPlayer = { name = model.thisPlayer.name, point = newPoint }
                        , visibleTiles = Help.shiftVisibleTiles model.grid ( dx, dz ) model.visibleTiles
                        , moveCooldownRemaining = Conf.movementCooldownMillis
                      }
                        |> Help.withPointsInFog
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
                |> Help.withPointsInFog
            , Cmd.none
            )

        YourPosition point ->
            ( { model
                | thisPlayer = { name = model.thisPlayer.name, point = point }
                , visibleTiles = Help.visibleTilesAround point model.grid
              }
                |> Help.withPointsInFog
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    Html.div
        Styles.pageRoot
        [ Hlazy.lazy viewGame model
        , viewNamePrompt model
        ]


viewNamePrompt : Model -> Html Msg
viewNamePrompt model =
    if Help.isNamed model then
        Html.text ""

    else
        Html.div
            [ Hattr.style "position" "fixed"
            , Hattr.style "inset" "0"
            , Hattr.style "display" "grid"
            , Hattr.style "place-items" "center"
            , Hattr.style "background" "rgba(2, 6, 23, 0.54)"
            , Hattr.style "backdrop-filter" "blur(10px)"
            , Hattr.style "z-index" "20"
            ]
            [ Html.div
                [ Hattr.style "width" "min(92vw, 360px)"
                , Hattr.style "padding" "22px"
                , Hattr.style "border-radius" "18px"
                , Hattr.style "border" "1px solid rgba(255, 255, 255, 0.14)"
                , Hattr.style "background" "rgba(15, 23, 42, 0.92)"
                , Hattr.style "box-shadow" "0 30px 70px rgba(2, 6, 23, 0.45)"
                , Hattr.style "display" "flex"
                , Hattr.style "flex-direction" "column"
                , Hattr.style "gap" "14px"
                ]
                [ Html.h2
                    [ Hattr.style "margin" "0"
                    , Hattr.style "font-size" "20px"
                    , Hattr.style "font-weight" "700"
                    , Hattr.style "color" "#f8fafc"
                    ]
                    [ Html.text "Choose your name" ]
                , Html.input
                    [ Hattr.id "player-name-input"
                    , Hattr.type_ "text"
                    , Hattr.attribute "maxlength" (String.fromInt Conf.maxNameLength)
                    , Hattr.value model.thisPlayer.name
                    , Hattr.placeholder "Enter a name"
                    , Hevent.onInput PlayerNameChanged
                    , Hattr.style "padding" "12px 14px"
                    , Hattr.style "border-radius" "12px"
                    , Hattr.style "border" "1px solid rgba(255, 255, 255, 0.16)"
                    , Hattr.style "background" "rgba(15, 23, 42, 0.72)"
                    , Hattr.style "color" "#f8fafc"
                    , Hattr.style "font-size" "16px"
                    , Hattr.style "outline" "none"
                    ]
                    []
                , Html.button
                    [ Hevent.onClick ConfirmPlayerName
                    , Hattr.style "padding" "11px 14px"
                    , Hattr.style "border" "0"
                    , Hattr.style "border-radius" "12px"
                    , Hattr.style "background" "linear-gradient(135deg, #22c55e, #16a34a)"
                    , Hattr.style "color" "white"
                    , Hattr.style "font-size" "15px"
                    , Hattr.style "font-weight" "700"
                    , Hattr.style "cursor" "pointer"
                    ]
                    [ Html.text "Enter the game" ]
                ]
            ]


viewGame : Model -> Html Msg
viewGame model =
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
            [ Html.h3 Styles.hudLabel [ Html.text "Name" ]
            , Html.p Styles.hudValue
                [ Html.text model.thisPlayer.name ]
            , Html.h3 Styles.hudLabel [ Html.text "Coordinates" ]
            , Html.p Styles.hudValue
                [ Html.text
                    ("(" ++ String.fromInt (Tuple.first model.thisPlayer.point) ++ ", " ++ String.fromInt (Tuple.second model.thisPlayer.point) ++ ")")
                ]
            ]
        ]


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
            Set.fromList (List.map .point model.otherPlayers)

        otherPlayerNames =
            Dict.fromList (List.map (\player -> ( player.point, player.name )) model.otherPlayers)

        cornersToStr corners =
            corners
                |> List.map (\( x, y ) -> String.fromFloat x ++ "," ++ String.fromFloat y)
                |> String.join " "

        layout =
            HexGrid.mkFlatTop Conf.hexSize Conf.hexSize (viewportCenterX - cameraX) (viewportCenterY - cameraY)

        renderPoint point =
            let
                ( centerX, centerY ) =
                    HexGrid.hexToPixel layout point

                corners =
                    HexGrid.polygonCorners layout point

                scaledCorners =
                    corners
                        |> List.map (\( x, y ) -> ( centerX + (x - centerX) * Conf.gapScale, centerY + (y - centerY) * Conf.gapScale ))

                isFogged =
                    Set.member point model.pointsInFog
            in
            Svg.g
                [ Sevent.onMouseOver (HoverPoint point)
                , Sevent.onClick (ToggleObstacle point)
                ]
                -- ground and environment
                [ Svg.polygon
                    [ Sattr.points (cornersToStr scaledCorners)
                    , Sattr.fill <|
                        if Set.member point model.obstacles && isFogged then
                            "#c0392b"

                        else if Set.member point model.obstacles && model.hoverPoint == point && HexGrid.distance model.thisPlayer.point point <= Conf.placementRange then
                            "#c0392b"

                        else if Set.member point model.obstacles then
                            "#e74c3c"

                        else if isFogged then
                            "#bdbdbd"

                        else if model.hoverPoint == point && HexGrid.distance model.thisPlayer.point point <= Conf.placementRange then
                            "#f1c40f"

                        else
                            "white"
                    ]
                    []

                -- players
                , if point == model.thisPlayer.point then
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
                    Svg.g []
                        [ Svg.circle
                            [ Sattr.cx (String.fromFloat centerX)
                            , Sattr.cy (String.fromFloat centerY)
                            , Sattr.r "15"
                            , Sattr.fill "#8e44ad"
                            , Sattr.strokeWidth "0"
                            ]
                            []
                        , Svg.text_
                            (Styles.playerNameTag
                                ++ [ Sattr.x (String.fromFloat centerX)
                                   , Sattr.y (String.fromFloat (centerY - 24))
                                   ]
                            )
                            [ Svg.text (Maybe.withDefault "" (Dict.get point otherPlayerNames)) ]
                        ]

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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every Conf.gameTickMillis Tick
