module Components.CurrentUser exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (showTimezone)
import Types exposing (User, AnchorTo)
import Util exposing ((=>), initials, initialsColor)


view : AnchorTo msg -> User -> Html msg
view anchorTo user =
    div [ class "current-user" ]
        [ avatar anchorTo user
        , h3 [] [ text user.name ]
        , h6 [] [ text (showTimezone user.timezone) ]
        ]


avatar : AnchorTo msg -> User -> Html msg
avatar anchorTo user =
    let
        initials' =
            initials user.name

        avatar' =
            case user.avatar of
                Nothing ->
                    anchorTo (CurrentProfileR ())
                        [ class "initials"
                        , style [ "background" => initialsColor initials' ]
                        ]
                        [ text initials' ]

                Just uri ->
                    anchorTo (CurrentProfileR ())
                        []
                        [ img
                            [ src uri
                            , title user.name
                            , alt initials'
                            ]
                            []
                        ]
    in
        div [ class "avatar" ] [ avatar' ]
