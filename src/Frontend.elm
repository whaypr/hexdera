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
                { title = "Lamdera hex grid multiplayer"
                , body = [ view model ]
                }
        , subscriptions = \_ -> Sub.none
        , onUrlChange = \_ -> NoOp
        , onUrlRequest = \_ -> NoOp
        }


init : ( Model, Cmd FrontendMsg )
init =
    ( initialFrontendModel
    , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "game-shell")
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
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


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
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


viewFogOfWar : Model -> Svg FrontendMsg
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
            60

        baseLayout =
            HexGrid.mkFlatTop hexSize hexSize 0 0

        ( playerX, playerY ) =
            HexGrid.hexToPixel baseLayout model.thisPlayer

        (HexGrid.HexGrid _ dict) =
            model.grid

        playerPositions =
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
                [ Svg.polygon
                    [ Sattr.points (cornersToStr <| scaledCorners)
                    , Sattr.fill <|
                        if point == model.thisPlayer then
                            "green"

                        else if model.hoverPoint == point && Set.member point model.obstacles then
                            "#c0392b"

                        else if Set.member point model.obstacles then
                            "#e74c3c"

                        else if model.hoverPoint == point then
                            "#f1c40f"

                        else if Set.member point pointsInFog then
                            "#bdbdbd"

                        else if Set.member point playerPositions then
                            "#8e44ad"

                        else
                            "white"
                    ]
                    []
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


viewFogOfWarDemo : Model -> Html FrontendMsg
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


view : Model -> Html FrontendMsg
view model =
    Html.div
        Styles.pageRoot
        [ Hlazy.lazy viewFogOfWarDemo model

        -- , hr [] []
        ]
