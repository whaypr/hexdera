module Styles exposing (..)

import Html
import Html.Attributes as Hattr
import Svg
import Svg.Attributes as Sattr


pageRoot : List (Html.Attribute msg)
pageRoot =
    [ Hattr.style "min-height" "100vh"
    , Hattr.style "width" "100%"
    , Hattr.style "display" "flex"
    , Hattr.style "justify-content" "center"
    , Hattr.style "align-items" "center"
    , Hattr.style "padding" "24px"
    , Hattr.style "box-sizing" "border-box"
    , Hattr.style "overflow" "hidden"
    , Hattr.style "background" "radial-gradient(circle at top, rgba(255, 255, 255, 0.18), transparent 38%), linear-gradient(160deg, #0f172a 0%, #16324f 45%, #0b1020 100%)"
    , Hattr.style "color" "#f8fafc"
    , Hattr.style "font-size" "18px"
    ]


gameShell : List (Html.Attribute msg)
gameShell =
    [ Hattr.style "width" "100%"
    , Hattr.style "display" "flex"
    , Hattr.style "justify-content" "center"
    , Hattr.style "align-items" "stretch"
    , Hattr.style "gap" "24px"
    , Hattr.style "flex-wrap" "wrap"
    , Hattr.style "outline" "none"
    ]


boardSvg : List (Svg.Attribute msg)
boardSvg =
    [ Sattr.style """
        display: block;
        border-radius: 20px;
        overflow: hidden;
        border: 2px solid rgba(255, 255, 255, 0.12);
        background: #000000;
        box-shadow: 0 24px 60px rgba(2, 6, 23, 0.35), 0 2px 8px rgba(15, 23, 42, 0.2);
        """
    ]


hudPanel : List (Html.Attribute msg)
hudPanel =
    [ Hattr.style "min-width" "220px"
    , Hattr.style "padding" "18px 20px"
    , Hattr.style "border-radius" "20px"
    , Hattr.style "border" "1px solid rgba(255, 255, 255, 0.12)"
    , Hattr.style "background" "rgba(2, 6, 23, 0.48)"
    , Hattr.style "backdrop-filter" "blur(12px)"
    , Hattr.style "box-shadow" "0 24px 60px rgba(2, 6, 23, 0.25)"
    , Hattr.style "display" "flex"
    , Hattr.style "flex-direction" "column"
    , Hattr.style "justify-content" "flex-start"
    , Hattr.style "gap" "12px"
    ]


hudLabel : List (Html.Attribute msg)
hudLabel =
    [ Hattr.style "margin" "0"
    , Hattr.style "text-transform" "uppercase"
    , Hattr.style "letter-spacing" "0.12em"
    , Hattr.style "font-size" "12px"
    , Hattr.style "color" "rgba(248, 250, 252, 0.7)"
    ]


hudValue : List (Html.Attribute msg)
hudValue =
    [ Hattr.style "margin" "0"
    , Hattr.style "font-size" "20px"
    , Hattr.style "font-weight" "500"
    , Hattr.style "line-height" "1.1"
    , Hattr.style "color" "#f8fafc"
    ]


    ]


    ]


playerNameTag : List (Svg.Attribute msg)
playerNameTag =
    [ Sattr.fill "#f8fafc"
    , Sattr.stroke "rgba(2, 6, 23, 0.92)"
    , Sattr.style "font-family: Georgia, serif; font-size: 12px; font-weight: 700; letter-spacing: 0.03em; paint-order: stroke fill;"
    , Sattr.textAnchor "middle"
    ]
