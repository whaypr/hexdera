module FrontendHelpers exposing (..)

import Config as Conf
import HexGrid
import Set exposing (Set)
import Time exposing (Posix)
import Types exposing (..)


isNamed : FrontendModel -> Bool
isNamed model =
    model.playerNameConfirmed && not (String.isEmpty (String.trim model.thisPlayer.name))


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


visibleTilesAround : HexGrid.Point -> HexGrid.HexGrid () -> Set HexGrid.Point
visibleTilesAround center grid =
    HexGrid.range Conf.visibleRadius center
        |> List.filter (\point -> HexGrid.contains point grid)
        |> Set.fromList


translatePoint : HexGrid.Point -> HexGrid.Point -> HexGrid.Point
translatePoint ( dx, dz ) ( x, z ) =
    ( x + dx, z + dz )


shiftVisibleTiles : HexGrid.HexGrid () -> HexGrid.Point -> Set.Set HexGrid.Point -> Set.Set HexGrid.Point
shiftVisibleTiles grid delta visibleTiles =
    Set.foldl
        (\point acc ->
            let
                nextPoint =
                    translatePoint delta point
            in
            if HexGrid.contains nextPoint grid then
                Set.insert nextPoint acc

            else
                acc
        )
        Set.empty
        visibleTiles


pointsInFogFor : FrontendModel -> Set.Set HexGrid.Point
pointsInFogFor model =
    HexGrid.fogOfWarWithin model.thisPlayer.point (Set.intersect model.walls model.visibleTiles) model.visibleTiles


withPointsInFog : FrontendModel -> FrontendModel
withPointsInFog model =
    { model | pointsInFog = pointsInFogFor model }


timeSinceLastTick : Posix -> Maybe Posix -> Float
timeSinceLastTick now lastTick =
    case lastTick of
        Nothing ->
            Conf.gameTickMillis

        Just previous ->
            toFloat (Time.posixToMillis now - Time.posixToMillis previous)
