module View where

import Signal exposing (Address)
import Html exposing (Html, text)

import Timestamp
import Types exposing (Model, Message)

view : Address Message -> Model -> Html
view messages model =
  text <| Timestamp.format model.now "HH:mm"
