module View where

import Signal exposing (Address)
import Html exposing (..)
import Html.Attributes exposing (..)

import Timestamp
import Types exposing (Model, Message)

import Components.CurrentUser as CurrentUser

top : Model -> Html
top model =
  div
    [ class "top-bar" ]
    [ div
        [ class "team-name" ]
        [ a [ href "/" ] [ text model.company.name ] ]
    , div
        [ class "clock" ]
        [ text <| Timestamp.format "HH:mm" model.now ]
    , div
        [ class "menu" ]
        []
    ]


sidebar : Address Message -> Model -> Html
sidebar messages model =
  div
    [ class "sidebar" ]
    [ CurrentUser.view model.user ]

content : Address Message -> Model -> Html
content messages model =
  div
    [ class "content" ]
    [ sidebar messages model ]

view : Address Message -> Model -> Html
view messages model =
  div
    [ class "app" ]
    [ top model
    , content messages model
    ]
