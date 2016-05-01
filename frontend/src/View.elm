module View where

import Signal exposing (Address)
import Html exposing (Html, div, h1, text)

import Timestamp
import Types exposing (Model, Message)

import Components.CurrentUser as CurrentUser

view : Address Message -> Model -> Html
view messages model =
  div [] [ h1 [] [ text model.company.name ] ]
