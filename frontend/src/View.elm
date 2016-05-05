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
      [ toolbar company user.timezone now
      , div
          [ class "content" ]
          [ lazy (sidebar messages anchorTo) user
          , page
          ]
      ]


toolbar : Company -> Timezone -> Timestamp -> Html
toolbar company timezone now =
  div
    [ class "toolbar" ]
    [ div [ class "team-name" ] [ a [ href "/" ] [ text company.name ] ]
    , div [ class "clock" ] [ Util.time timezone now ]
    , div [ class "menu" ] []
    ]


sidebar : Address Message -> AnchorTo -> User -> Html
sidebar messages anchorTo user =
  let
    linkTo uri label =
      li [] [ a [ href uri ] [ text label ] ]

    routeTo route label =
      li [] [ anchorTo route label ]
  in
    div
      [ class "sidebar" ]
        [ CurrentUser.view user
        , ul
            [ class "menu" ]
            ( if user.role == Types.Member then
                [ routeTo (DashboardR ()) "Dashboard"
                , linkTo "/sign-out" "Sign out"
                ]
              else
                [ routeTo (DashboardR ()) "Dashboard"
                , routeTo (InviteR ()) "Invite Teammates"
                , routeTo (SettingsR ()) "Settings"
                , linkTo "/sign-out" "Sign out"
                ]
            )
        ]
