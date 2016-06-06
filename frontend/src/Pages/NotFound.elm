module Pages.NotFound exposing (view)

import Components.Page exposing (page)
import Html exposing (..)


view : Html msg
view =
    page "Not Found"
        [ p []
            [ text "The page you are looking for could not be found." ]
        ]
