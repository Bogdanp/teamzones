module Update (init, update) where

import Dict
import Effects exposing (Effects)

import Timestamp exposing (Timestamp)
import Types exposing (..)

init : Timestamp -> Company -> User -> (Model, Effects Message)
init now company user =
  let
    model = { now = now
            , company = company
            , user = user
            , team = Dict.empty
            }
  in
    (model, Effects.none)


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    Tick now ->
      pure { model | now = now }


pure : Model -> (Model, Effects Message)
pure = (flip (,) Effects.none)
