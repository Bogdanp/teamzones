module Components.CurrentUser exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (showTimezone)
import Types exposing (User, AnchorTo)
import User exposing (initials, initialsColor)
import Util exposing ((=>))


view : AnchorTo msg -> User -> Html msg
view anchorTo user =
    div [ class "user-profile" ]
        [ avatar anchorTo user
        , h3 [] [ text user.fullName ]
        , h6 [] [ text (showTimezone user.timezone) ]
        ]


avatar : AnchorTo msg -> User -> Html msg
avatar anchorTo user =
    let
        initials' =
            initials user.fullName

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
                            , title user.fullName
                            , alt initials'
                            ]
                            []
                        ]
    in
        div [ class "avatar" ] [ avatar' ]
