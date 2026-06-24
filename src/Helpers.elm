module Helpers exposing (..)

import Config as Conf
import HexGrid
import Set exposing (Set)
import Time exposing (Posix)
import Types exposing (..)


cameraCenterForPoint : HexGrid.Point -> ( Float, Float )
cameraCenterForPoint point =
    let
        baseLayout =
            HexGrid.mkFlatTop Conf.hexSize Conf.hexSize 0 0
    in
    HexGrid.hexToPixel baseLayout point


approach : Float -> Float -> Float -> Float
approach current target delta =
    let
        stepRatio =
            min 1 (delta / Conf.cameraEaseMillis)
    in
    current + (target - current) * stepRatio


timeSinceLastTick : Posix -> Maybe Posix -> Float
timeSinceLastTick now lastTick =
    case lastTick of
        Nothing ->
            Conf.gameTickMillis

        Just previous ->
            toFloat (Time.posixToMillis now - Time.posixToMillis previous)
