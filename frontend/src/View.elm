module View where

import Signal exposing (Address)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)

import Timestamp exposing (Timestamp)
import Types exposing (Model, Message)

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
        [ sidebar
        , team
        ]

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
        [ link "/sign-out" "Sign out"
        ]

    link uri label =
      li [] [ a [ href uri ] [ text label ] ]
  in
    div
      [ class "app" ]
      [ top
      , content
      ]

time : Timestamp -> Html
time = Timestamp.format "hh:mmA" >> text
