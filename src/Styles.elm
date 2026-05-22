module Styles exposing (boardSvg, eyeText, gameShell, pageRoot, pathText)

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
    , Hattr.style "min-height" "100vh"
    , Hattr.style "display" "flex"
    , Hattr.style "justify-content" "center"
    , Hattr.style "align-items" "center"
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


eyeText : List (Svg.Attribute msg)
eyeText =
    [ Sattr.stroke "white"
    , Sattr.fill "white"
    , Sattr.style "font-family: monospace; font-size: 18px;"
    ]


pathText : List (Svg.Attribute msg)
pathText =
    [ Sattr.stroke "black"
    , Sattr.fill "black"
    , Sattr.style "font-family: monospace; font-size: 24px;"
    ]
