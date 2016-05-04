module View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)
import Signal exposing (Address)

import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Model, Message(..), Company)
import Util exposing (hijack)

import Components.CurrentUser as CurrentUser
import Components.Invite as Invite
import Components.Settings as Settings
import Components.Team as Team


view : Address Message -> Model -> Html
view messages {now, company, user, team, route, invite} =
  let
    content =
      div
        [ class "content" ]
        [ sidebar, page]

    page =
      case route of
        HomeR () ->
          Team.view team now

        InviteR () ->
          Signal.forwardTo messages ToInvite
            |> Invite.view
            |> flip lazy invite

        SettingsR () ->
          Settings.view

    sidebar =
      div
        [ class "sidebar" ]
        [ CurrentUser.view user
        , ul [ class "menu" ] links
        ]

    links =
      if user.role == Types.Member then
        [ routeTo (HomeR ()) "Dashboard"
        , linkTo "/sign-out" "Sign out"
        ]
      else
        [ routeTo (HomeR ()) "Dashboard"
        , routeTo (InviteR ()) "Invite Teammates"
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
