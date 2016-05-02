module Components.Team where

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)

import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Team, User)
import Util exposing (initials)

view : Timestamp -> Team -> Html
view now team =
  let
    zones =
      Dict.toList team
        |> List.sortBy (fst >> snd)
        |> List.map (\((timezone, _), users) -> zone now timezone users)
  in
    div [ class "team" ] zones


zone : Timestamp -> Timezone -> List User -> Html
zone now timezone users =
  div
    [ class "zone" ]
    [ div
        [ class "header" ]
        [ h6 [] [ text timezone ]
        , h4 [] [ Util.time timezone now ]
        ]
    , ul [ class "users" ] (List.map user users)
    ]


user : User -> Html
user u =
  let
    avatar =
      case u.avatar of
        Nothing ->
          a
            [ class "initials", href "" ]
            [ text <| initials u.name ]

        Just uri ->
          a
            [ href "" ]
            [ img
                [ class "avatar", src uri ]
                [ ]
            ]
  in
    li [ class "user" ] [ avatar ]
