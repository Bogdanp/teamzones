module View where

import Signal exposing (Address)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Json.Decode as Json

import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Model, Message(..), Company)
import Util

import Components.CurrentUser as CurrentUser
import Components.Team as Team

view : Address Message -> Model -> Html
view messages model =
  let
    content =
      div
        [ class "content" ]
        [ sidebar, Team.view model.now model.team ]

    sidebar =
      div
        [ class "sidebar" ]
        [ CurrentUser.view model.user
        , menu
        ]

    menu =
      ul
        [ class "menu" ]
        ( managerLinks ++ [ link "/sign-out" "Sign out" ])

    managerLinks =
      if model.user.role == Types.Member then
        []
      else
        [ routeTo (InviteR ()) "Invite Teammates"
        , routeTo (SettingsR ()) "Settings"
        ]

    link uri label =
      li [] [ a [ href uri ] [ text label ] ]

    routeTo route label =
      li [] [ a [ href <| Routes.route route
                , onWithOptions
                    "click"
                    { stopPropagation = True
                    , preventDefault = True
                    }
                    Json.value
                    (always <| Signal.message messages (RouteTo route))
                ] [ text label ] ]
  in
    div
      [ class "app" ]
      [ top model.company model.now model.user.timezone
      , content
      ]


top : Company -> Timestamp -> Timezone -> Html
top company now timezone =
  div
    [ class "top-bar" ]
    [ div [ class "team-name" ] [ a [ href "/" ] [ text company.name ] ]
    , div [ class "clock" ] [ Util.time timezone now ]
    , div [ class "menu" ] []
    ]
