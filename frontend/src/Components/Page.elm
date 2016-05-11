module Components.Page exposing (page)

import Html exposing (..)
import Html.Attributes exposing (..)


page : String -> List (Html msg) -> Html msg
page title content =
    div [ class "page" ]
        [ div [ class "page-header" ] [ h1 [] [ text title ] ]
        , div [ class "page-content" ] content
        ]
