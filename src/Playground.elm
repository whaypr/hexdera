module Playground exposing (..)

import Browser
import Dict
import HexGrid exposing (Direction(..), HexGrid(..))
import Html exposing (Html, div)
import Html.Attributes as Hattr exposing (..)
import Html.Events as Hevent
import Html.Lazy exposing (lazy)
import Json.Decode as JD
import Set exposing (Set)
import String
import Svg exposing (Svg, g, polygon)
import Svg.Attributes as Sattr exposing (fill, points, stroke, x, y)
import Svg.Events as Sevent exposing (onClick, onMouseOver)


toString : a -> String
toString value =
    Debug.toString value


type alias Demo =
    { name : String
    , grid : HexGrid ()
    , activePoint : HexGrid.Point
    , hoverPoint : HexGrid.Point
    , obstacles : Set HexGrid.Point
    , maxSteps : Int

    -- , tilePath : Set.Set HexCoord
    -- , moveTiles : Set.Set HexCoord -- Tiles highlight user can move to
    }


initDemo : String -> Demo
initDemo name =
    { name = name
    , grid = HexGrid.empty 5 ()
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
    , maxSteps = 4
    }


type alias Model =
    Dict.Dict String Demo


init : Model
init =
    List.map (\demo -> ( demo.name, demo ))
        [ initDemo "lineDemo"
        ]
        |> Dict.fromList


type Msg
    = NoOp
    | ActivePoint Demo HexGrid.Point
    | HoverPoint Demo HexGrid.Point
    | SetMaxSteps Demo Int
    | InsertObstacle Demo HexGrid.Point
    | RemoveObstacle Demo HexGrid.Point
    | KeyPressDemo String String


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

        ActivePoint prevDemo point ->
            let
                nextDemo =
                    { prevDemo | activePoint = point }
            in
            Dict.insert nextDemo.name nextDemo model

        HoverPoint prevDemo point ->
            let
                nextDemo =
                    { prevDemo | hoverPoint = point }
            in
            Dict.insert nextDemo.name nextDemo model

        SetMaxSteps prevDemo steps ->
            let
                nextDemo =
                    { prevDemo | maxSteps = steps }
            in
            Dict.insert nextDemo.name nextDemo model

        InsertObstacle prevDemo point ->
            let
                nextDemo =
                    { prevDemo | obstacles = Set.insert point prevDemo.obstacles }
            in
            Dict.insert nextDemo.name nextDemo model

        RemoveObstacle prevDemo point ->
            let
                nextDemo =
                    { prevDemo | obstacles = Set.remove point prevDemo.obstacles }
            in
            Dict.insert nextDemo.name nextDemo model

        KeyPressDemo demoName key ->
            let
                prevDemo =
                    forceGet demoName model

                ( x, z ) =
                    prevDemo.activePoint

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

                nextDemo =
                    if HexGrid.contains newPoint prevDemo.grid && not (Set.member newPoint prevDemo.obstacles) then
                        { prevDemo | activePoint = newPoint }

                    else
                        prevDemo
            in
            Dict.insert nextDemo.name nextDemo model


viewDistance : Demo -> Svg Msg
viewDistance model =
    let
        (HexGrid _ dict) =
            model.grid

        cornersToStr corners =
            corners
                |> List.map (\( x, y ) -> toString x ++ "," ++ toString y)
                |> String.join " "

        -- not flipped this time
        layout =
            HexGrid.mkFlatTop 30 30 (600 / 2) (570 / 2)

        pointsInLine =
            HexGrid.line model.activePoint model.hoverPoint
                |> Set.fromList

        renderPoint ( point, tile ) =
            let
                ( centerX, centerY ) =
                    HexGrid.hexToPixel layout point

                corners =
                    HexGrid.polygonCorners layout point
            in
            g
                [ onClick (ActivePoint model point)
                , onMouseOver (HoverPoint model point)
                ]
                [ polygon
                    [ points (cornersToStr <| corners)
                    , stroke "black"
                    , fill <|
                        if model.activePoint == point then
                            "green"

                        else if model.hoverPoint == point then
                            "#f1c40f"
                            -- gold

                        else if Set.member point model.obstacles then
                            "#c0392b"

                        else if Set.member point pointsInLine then
                            "#bdc3c7"
                            -- light grey

                        else
                            "white"
                    ]
                    []
                ]
    in
    Svg.svg
        []
        (List.map renderPoint (Dict.toList dict))


viewDistanceDemo : Demo -> Html Msg
viewDistanceDemo demo =
    div
        [ class "d-flex justify-content-center align-items-center"
        , Hattr.attribute "tabindex" "0"
        , Hevent.on "keydown" (JD.map (KeyPressDemo demo.name) (JD.field "key" JD.string))
        ]
        [ viewDistance demo
        ]


view : Model -> Svg Msg
view model =
    Html.div
        []
        [ lazy viewDistanceDemo (forceGet "lineDemo" model)

        -- , hr [] []
        ]


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
