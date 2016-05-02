module View where

import Signal exposing (Address)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Json.Decode as Json

import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp)
import Types exposing (Model, Message(..))

import Components.CurrentUser as CurrentUser

view : Address Message -> Model -> Html
view messages model =
  let
    top =
      div
        [ class "top-bar" ]
        [ div [ class "team-name" ] [ a [ href "/" ] [ text model.company.name ] ]
        , div [ class "clock" ] [ time model.now ]
        , div [ class "menu" ] []
        ]

    content =
      div
        [ class "content" ]
        [ sidebar, team ]

    team =
      div
        [ class "team" ]
        []

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
        [ routeTo (InviteR ()) "Invite Teammate"
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
      [ top
      , content
      ]

time : Timestamp -> Html
time = Timestamp.format "hh:mmA" >> text
