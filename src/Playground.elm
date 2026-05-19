module Playground exposing (..)

import Browser
import Dict
import Html exposing (Html)
import Html.Attributes as Hattr
import Html.Events as Hevent
import Html.Lazy as Hlazy
import Json.Decode as JD
import Set exposing (Set)
import String
import Svg exposing (Svg)
import Svg.Attributes as Sattr
import Svg.Events as Sevent

import HexGrid exposing (HexGrid)


toString : a -> String
toString value =
    Debug.toString value


type alias Model =
    { grid : HexGrid ()
    , activePoint : HexGrid.Point
    , hoverPoint : HexGrid.Point
    , obstacles : Set HexGrid.Point
    }


init : Model
init =
    { grid = HexGrid.empty 5 ()
    , activePoint = ( 0, 0 )
    , hoverPoint = ( -1, -4 )
    , obstacles =
        Set.fromList
            [ ( -5, 4 )
            , ( -4, 3 )
            , ( -3, 2 )
            , ( -2, 1 )
            , ( -1, 1 )
            , ( -1, 2 )
            , ( 0, 2 )
            , ( 1, 2 )
            , ( 2, 1 )
            , ( 2, 0 )
            , ( 2, -1 )
            , ( 1, -1 )
            , ( 2, -2 )
            , ( -1, -1 )
            , ( 0, -2 )
            , ( 1, -3 )
            , ( 3, -4 )
            , ( 4, -4 )
            , ( 4, -3 )
            , ( -4, 0 )
            , ( -3, 0 )
            , ( 0, 3 )
            ]
    }


type Msg
    = NoOp
    | ActivePoint Model HexGrid.Point
    | HoverPoint Model HexGrid.Point
    | InsertObstacle Model HexGrid.Point
    | RemoveObstacle Model HexGrid.Point
    | KeyPress String
forceGet : comparable -> Dict.Dict comparable v -> v
forceGet key dict =
    case Dict.get key dict of
        Just v ->
            v

        Nothing ->
            Debug.todo "Impossible"


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        ActivePoint prevModel point ->
            let
                nextModel =
                    { prevModel | activePoint = point }
            in
            nextModel

        HoverPoint prevModel point ->
            let
                nextModel =
                    { prevModel | hoverPoint = point }
            in
            nextModel

        InsertObstacle prevModel point ->
            let
                nextModel =
                    { prevModel | obstacles = Set.insert point prevModel.obstacles }
            in
            nextModel

        RemoveObstacle prevModel point ->
            let
                nextModel =
                    { prevModel | obstacles = Set.remove point prevModel.obstacles }
            in
            nextModel

        KeyPress key ->
            let
                prevModel =
                    model

                ( x, z ) =
                    prevModel.activePoint

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

                nextModel =
                    if HexGrid.contains newPoint prevModel.grid && not (Set.member newPoint prevModel.obstacles) then
                        { prevModel | activePoint = newPoint }

                    else
                        prevModel
            in
            nextModel


viewFogOfWar : Model -> Svg Msg
viewFogOfWar model =
    let
        (HexGrid.HexGrid _ dict) =
            model.grid

        cornersToStr corners =
            corners
                |> List.map (\( x, y ) -> toString x ++ "," ++ toString y)
                |> String.join " "

        layout =
            HexGrid.mkFlatTop 30 30 (600 / 2) (570 / 2)

        pointsInFog =
            HexGrid.fogOfWar model.activePoint model.obstacles model.grid

        pointsInPath =
            HexGrid.line model.activePoint model.hoverPoint
                |> List.drop 1
                |> Set.fromList

        renderPoint ( point, tile ) =
            let
                ( centerX, centerY ) =
                    HexGrid.hexToPixel layout point

                corners =
                    HexGrid.polygonCorners layout point
            in
            Svg.g
                [ Sevent.onMouseOver (HoverPoint model point)
                , Sevent.onClick <|
                    if Set.member point model.obstacles then
                        RemoveObstacle model point

                    else
                        InsertObstacle model point
                ]
                [ Svg.polygon
                    [ Sattr.points (cornersToStr <| corners)
                    , Sattr.fill <|
                        if model.hoverPoint == point && Set.member point model.obstacles then
                            "#c0392b"

                        else if Set.member point model.obstacles then
                            "#e74c3c"

                        else if point == model.activePoint then
                            "green"

                        else if model.hoverPoint == point then
                            "#f1c40f"

                        else if Set.member point pointsInFog then
                            "#bdc3c7"

                        else
                            "white"
                    ]
                    []
                , Svg.text_
                    [ Sattr.stroke "white"
                    , Sattr.fill "white"
                    , Sattr.x (toString <| centerX - 10)
                    , Sattr.y (toString <| centerY + 5)
                    , Sattr.style "font-family: monospace; font-size: 18px;"
                    ]
                    [ Svg.text <|
                        if point == model.activePoint then
                            "👁"

                        else
                            ""
                    ]
                , Svg.text_
                    [ Sattr.stroke "black"
                    , Sattr.fill "black"
                    , Sattr.x (toString <| centerX - 8)
                    , Sattr.y (toString <| centerY + 7)
                    , Sattr.style "font-family: monospace; font-size: 24px;"
                    ]
                    [ Svg.text <|
                        if Set.member point pointsInPath then
                            "×"

                        else
                            ""
                    ]
                ]
    in
    Svg.svg
        []
        (List.map renderPoint (Dict.toList dict))


viewFogOfWarDemo : Model -> Html Msg
viewFogOfWarDemo model =
    Html.div
        [ Hattr.class "d-flex justify-content-center align-items-center"
        , Hattr.attribute "tabindex" "0"
        , Hevent.on "keydown" (JD.map KeyPress (JD.field "key" JD.string))
        ]
        [ viewFogOfWar model
        ]


view : Model -> Svg.Svg Msg
view model =
    Html.div
        []
        [ Hlazy.lazy viewFogOfWarDemo model

        -- , hr [] []
        ]


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
