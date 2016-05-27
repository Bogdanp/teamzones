module Components.Team exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, showTimezone)
import Types exposing (Workdays, Team, User)
import Util exposing ((=>), initials, initialsColor, on')
import User exposing (isOffline)


view : (Sitemap -> msg) -> Team -> Timestamp -> Html msg
view routeTo team now =
    let
        zone users timezone =
            div [ class "zone" ]
                [ div [ class "header" ]
                    [ h6 [] [ text (showTimezone timezone) ]
                    , h4 [] [ Util.time timezone now ]
                    ]
                , ul [] (List.map user users)
                ]

        user u =
            let
                avatar =
                    Maybe.map (pictureAvatar u) u.smallAvatar
                        |> Maybe.withDefault (initialsAvatar u)
            in
                li [ classList [ "offline" => isOffline now u ] ]
                    [ avatar
                    , div [ class "overlay" ] [ span [] [ text u.fullName ] ]
                    ]

        anchorTo route attrs =
            a ([ on' "click" (routeTo route), href (Routes.toString route) ] ++ attrs)

        initialsAvatar user =
            let
                initials' =
                    initials user.fullName
            in
                anchorTo (ProfileR user.email)
                    [ class "initials"
                    , style [ "background" => initialsColor initials' ]
                    ]
                    [ text initials' ]

        pictureAvatar user avatar =
            anchorTo (ProfileR user.email)
                [ class "avatar"
                ]
                [ img [ src avatar ] [] ]
    in
        Dict.toList team
            |> List.sortBy (fst >> snd)
            |> List.map (\( ( timezone, _ ), users ) -> zone users timezone)
            |> div [ class "team" ]
