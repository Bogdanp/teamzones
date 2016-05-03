module View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Json.Decode as Json
import Signal exposing (Address)

import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Model, Message(..), Company)
import Util exposing (hijack)

import Components.CurrentUser as CurrentUser
import Components.Team as Team


view : Address Message -> Model -> Html
view messages {now, company, user, team, route} =
  let
    content =
      div
        [ class "content" ]
        [ sidebar
        , Team.view now team
        ]

    sidebar =
      div
        [ class "sidebar" ]
        [ CurrentUser.view user
        , menu
        ]

    menu =
      ul
        [ class "menu" ]
        links

    links =
      if user.role == Types.Member then
        [ linkTo "/sign-out" "Sign out"
        ]
      else
        [ routeTo (InviteR ()) "Invite Teammates"
        , routeTo (SettingsR ()) "Settings"
        , linkTo "/sign-out" "Sign out"
        ]

    linkTo uri label =
      li [] [ a [ href uri ] [ text label ] ]

    routeTo route label =
      li [] [ a [ href <| Routes.route route
                , hijack "click" <| Signal.message messages (RouteTo route)
                ]
                [ text label ]
            ]
  in
    div
      [ class "app" ]
      [ toolbar company user.timezone now
      , content
      ]


toolbar : Company -> Timezone -> Timestamp -> Html
toolbar company timezone now =
  div
    [ class "toolbar" ]
    [ div [ class "team-name" ] [ a [ href "/" ] [ text company.name ] ]
    , div [ class "clock" ] [ Util.time timezone now ]
    , div [ class "menu" ] []
    ]
