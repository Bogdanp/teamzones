module Icons exposing (chat, menu)

import Color exposing (Color)
import Svg exposing (Svg, svg)
import Svg.Attributes


chat : Color -> Int -> Svg msg
chat =
    icon "M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 9h12v2H6V9zm8 5H6v-2h8v2zm4-6H6V6h12v2z"


menu : Color -> Int -> Svg msg
menu =
    icon "M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z"


icon : String -> Color -> Int -> Svg msg
icon path color size =
    let
        stringSize =
            toString size

        stringColor =
            toRgbaString color
    in
        Svg.svg
            [ Svg.Attributes.width stringSize
            , Svg.Attributes.height stringSize
            , Svg.Attributes.viewBox "0 0 24 24"
            ]
            [ Svg.path
                [ Svg.Attributes.d path
                , Svg.Attributes.fill stringColor
                ]
                []
            ]


toRgbaString : Color -> String
toRgbaString color =
    let
        { red, green, blue, alpha } =
            Color.toRgb color
    in
        "rgba("
            ++ toString red
            ++ ","
            ++ toString green
            ++ ","
            ++ toString blue
            ++ ","
            ++ toString alpha
            ++ ")"
