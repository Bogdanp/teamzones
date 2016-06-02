module Components.Common exposing (heading)

import Html exposing (..)


heading : String -> Html msg
heading content =
    h4 [] [ text content ]
