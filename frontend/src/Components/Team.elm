module Components.Team exposing (view, viewList)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, showTimezone)
import Types exposing (AnchorTo, Workdays, Team, User)
import User exposing (isOffline, initials, initialsColor)
import Util exposing ((=>), (?>), on')


view : (Sitemap -> msg) -> Timestamp -> Team -> Html msg
view routeTo now team =
    let
        anchorTo =
            Util.anchorTo routeTo

        zone users timezone =
            div [ class "zone" ]
                [ div [ class "header" ]
                    [ h6 [] [ text (showTimezone timezone) ]
                    , h4 [] [ Util.time timezone now ]
                    ]
                , ul [] (List.map (user anchorTo now) users)
                ]
    in
        Dict.toList team
            |> List.sortBy (fst >> snd)
            |> List.map (\( ( timezone, _ ), users ) -> zone users timezone)
            |> div [ class "team" ]


viewList : (Sitemap -> msg) -> Timestamp -> List User -> Html msg
viewList routeTo now teamMembers =
    let
        anchorTo =
            Util.anchorTo routeTo
    in
        div [ class "team" ]
            [ div [ class "zone zone--fluid" ]
                [ ul [] (List.map (user anchorTo now) teamMembers)
                ]
            ]


initialsAvatar : AnchorTo msg -> User -> Html msg
initialsAvatar anchorTo { fullName, email } =
    let
        initials' =
            initials fullName
    in
        anchorTo (ProfileR email)
            [ class "initials"
            , style [ "background" => initialsColor initials' ]
            ]
            [ text initials' ]


pictureAvatar : AnchorTo msg -> User -> String -> Html msg
pictureAvatar anchorTo { email } avatar =
    anchorTo (ProfileR email)
        [ class "avatar"
        ]
        [ img [ src avatar ] [] ]


user : AnchorTo msg -> Timestamp -> User -> Html msg
user anchorTo now ({ fullName, smallAvatar } as user) =
    let
        picAvatar =
            pictureAvatar anchorTo user

        initAvatar =
            initialsAvatar anchorTo user

        avatar =
            Maybe.map picAvatar smallAvatar ?> initAvatar
    in
        li [ classList [ "offline" => isOffline now user ] ]
            [ avatar
            , div [ class "overlay" ] [ span [] [ text fullName ] ]
            ]
