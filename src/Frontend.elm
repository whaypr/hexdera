module Frontend exposing (Model, app)

import Browser.Dom
import Dict
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
        , subscriptions = \_ -> Sub.none
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


init : ( Model, Cmd Msg )
init =
    ( initialFrontendModel
      -- automatically focus the game
    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "game-shell")
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ThisPlayerPosition point ->
            ( { model | thisPlayer = point }
            , L.sendToBackend (PlayerMoved point)
            )

        HoverPoint point ->
            ( { model | hoverPoint = point }, Cmd.none )

        ToggleObstacle point ->
            let
                occupiedPlayers =
                    Set.insert model.thisPlayer (Set.fromList model.otherPlayers)

                pointsInFog =
                    HexGrid.fogOfWar model.thisPlayer model.obstacles model.grid
            in
            if Set.member point occupiedPlayers || Set.member point pointsInFog || HexGrid.distance model.thisPlayer point > placementRange then
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
                ( { model | thisPlayer = newPoint }
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
            ( { model | thisPlayer = point }, Cmd.none )


viewFogOfWar : Model -> Svg Msg
viewFogOfWar model =
    let
        viewportWidth =
            600

        viewportHeight =
            570

        viewportCenterX =
            toFloat viewportWidth / 2

        viewportCenterY =
            toFloat viewportHeight / 2

        hexSize =
            35

        baseLayout =
            HexGrid.mkFlatTop hexSize hexSize 0 0

        ( playerX, playerY ) =
            HexGrid.hexToPixel baseLayout model.thisPlayer

        (HexGrid.HexGrid _ dict) =
            model.grid

        otherPlayerPositions =
            Set.fromList model.otherPlayers

        cornersToStr corners =
            corners
                |> List.map (\( x, y ) -> String.fromFloat x ++ "," ++ String.fromFloat y)
                |> String.join " "

        layout =
            HexGrid.mkFlatTop hexSize hexSize (viewportCenterX - playerX) (viewportCenterY - playerY)

        pointsInFog =
            HexGrid.fogOfWar model.thisPlayer model.obstacles model.grid

        pointsInPath =
            HexGrid.line model.thisPlayer model.hoverPoint
                |> List.drop 1
                |> Set.fromList

        renderPoint ( point, tile ) =
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
            in
            Svg.g
                [ Sevent.onMouseOver (HoverPoint point)
                , Sevent.onClick (ToggleObstacle point)
                ]
                -- ground and environment
                [ Svg.polygon
                    [ Sattr.points (cornersToStr <| scaledCorners)
                    , Sattr.fill <|
                        if Set.member point model.obstacles && Set.member point pointsInFog then
                            "#c0392b"

                        else if Set.member point model.obstacles && model.hoverPoint == point && HexGrid.distance model.thisPlayer point <= placementRange then
                            "#c0392b"

                        else if Set.member point model.obstacles then
                            "#e74c3c"

                        else if Set.member point pointsInFog then
                            "#bdbdbd"

                        else if model.hoverPoint == point && HexGrid.distance model.thisPlayer point <= placementRange then
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

                  else if Set.member point otherPlayerPositions && not (Set.member point pointsInFog) then
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
                , Svg.text_
                    (Styles.eyeText
                        ++ [ Sattr.x (String.fromFloat <| centerX - 10)
                           , Sattr.y (String.fromFloat <| centerY + 5)
                           ]
                    )
                    [ Svg.text <|
                        if point == model.thisPlayer then
                            "👁"

                        else
                            ""
                    ]
                , Svg.text_
                    (Styles.pathText
                        ++ [ Sattr.x (String.fromFloat <| centerX - 8)
                           , Sattr.y (String.fromFloat <| centerY + 7)
                           ]
                    )
                    [ Svg.text <|
                        if Set.member point pointsInPath then
                            "×"

                        else
                            ""
                    ]
                ]
    in
    Svg.svg
        ([ Sattr.width (String.fromInt viewportWidth)
         , Sattr.height (String.fromInt viewportHeight)
         , Sattr.viewBox (String.join " " [ "0", "0", String.fromInt viewportWidth, String.fromInt viewportHeight ])
         ]
            ++ Styles.boardSvg
        )
        (List.map renderPoint (Dict.toList dict))


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
        ]


view : Model -> Html Msg
view model =
    Html.div
        Styles.pageRoot
        [ Hlazy.lazy viewFogOfWarDemo model

        -- , hr [] []
        ]
