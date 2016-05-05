module View where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)
import Signal exposing (Address)

import Model exposing (Model, Message(..))
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Company, User)
import Util exposing (on')

import Components.CurrentUser as CurrentUser
import Components.Invite as Invite
import Components.Settings as Settings
import Components.Team as Team


type alias AnchorTo
  = Sitemap -> String -> Html


view : Address Message -> Model -> Html
view messages {now, company, user, team, route, invite} =
  let
    anchorTo route label =
      a [ Signal.message messages (RouteTo route) |> on' "click"
        , Routes.route route |> href
        ]
        [ text label ]

    page =
      case route of
        DashboardR () ->
          Team.view team now

        InviteR () ->
          Signal.forwardTo messages ToInvite
            |> Invite.view
            |> flip lazy invite

        SettingsR () ->
          Settings.view
  in
    div
      [ class "app" ]
      [ toolbar anchorTo company user.timezone now
      , div
          [ class "content" ]
          [ sidebar anchorTo user
          , page
          ]
      ]


toolbar : AnchorTo -> Company -> Timezone -> Timestamp -> Html
toolbar anchorTo company timezone now =
  div
    [ class "toolbar" ]
    [ div [ class "team-name" ] [ anchorTo (DashboardR ()) company.name ]
    , div [ class "clock" ] [ Util.time timezone now ]
    , div [ class "menu" ] []
    ]


sidebar : AnchorTo -> User -> Html
sidebar anchorTo user =
  let
    linkTo uri label =
      li [] [ a [ href uri ] [ text label ] ]

    routeTo route label =
      li [] [ anchorTo route label ]

    links =
      if user.role /= Types.Member then
        [ routeTo (InviteR ()) "Invite Teammates"
        , routeTo (SettingsR ()) "Settings"
        ]
      else
        [ ]
  in
    div
      [ class "sidebar" ]
        [ CurrentUser.view user
        , ul
            [ class "menu" ]
            ( [ routeTo (DashboardR ()) "Dashboard" ]
                ++ links
                ++ [ linkTo "/sign-out" "Sign out" ]
            )
        ]
