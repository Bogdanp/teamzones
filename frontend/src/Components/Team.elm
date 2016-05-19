module Components.Team exposing (view)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Timestamp exposing (Timestamp, Timezone, showTimezone)
import Types exposing (Workdays, Team, User)
import Util exposing ((=>), initials, initialsColor)
import User exposing (isOffline)


view : Team -> Timestamp -> Html msg
view team now =
    Dict.toList team
        |> List.sortBy (fst >> snd)
        |> List.map (\( ( timezone, _ ), users ) -> zone users timezone now)
        |> div [ class "team" ]


zone : List User -> Timezone -> Timestamp -> Html msg
zone users timezone now =
    div [ class "zone" ]
        [ div [ class "header" ]
            [ h6 [] [ text (showTimezone timezone) ]
            , h4 [] [ Util.time timezone now ]
            ]
        , ul [] (List.map (user now) users)
        ]


user : Timestamp -> User -> Html msg
user now u =
    let
        avatar =
            Maybe.map pictureAvatar u.smallAvatar
                |> Maybe.withDefault (initialsAvatar <| initials u.name)
    in
        li [ classList [ "offline" => isOffline now u ] ]
            [ avatar
            , div [ class "overlay" ] [ span [] [ text u.name ] ]
            ]


initialsAvatar : String -> Html msg
initialsAvatar initials =
    a
        [ href ""
        , class "initials"
        , style [ "background" => initialsColor initials ]
        ]
        [ text initials ]


pictureAvatar : String -> Html msg
pictureAvatar uri =
    a
        [ href ""
        , class "avatar"
        ]
        [ img [ src uri ] [] ]
