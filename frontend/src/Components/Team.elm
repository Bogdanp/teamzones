module Components.Team exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Team, User)
import Util exposing ((=>), initials, initialsColor)


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
            [ h6 [] [ text timezone ]
            , h4 [] [ Util.time timezone now ]
            ]
        , ul [] (List.map user users)
        ]


user : User -> Html msg
user u =
    let
        initials' =
            initials u.name

        avatar =
            case u.avatar of
                Nothing ->
                    a
                        [ href ""
                        , class "initials"
                        , style [ "background" => initialsColor initials' ]
                        ]
                        [ text initials' ]

                Just uri ->
                    a
                        [ href ""
                        , class "avatar"
                        ]
                        [ img [ src uri ] [] ]
    in
        li [] [ avatar ]
