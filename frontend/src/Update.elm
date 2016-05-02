module Update (init, update) where

import Dict
import Effects exposing (Effects)

import Timestamp exposing (Timestamp)
import Types exposing (..)

convertUser : ContextUser -> User
convertUser u =
  let
    role r =
      case r of
        0 -> Main
        1 -> Manager
        _ -> Member

    avatar a =
      if a == "" then
        Nothing
      else
        Just a
  in
    { role = role u.role
    , name = u.name
    , email = u.email
    , avatar = avatar u.avatar
    , timezone = u.timezone
    }

init : Timestamp -> Company -> ContextUser -> (Model, Effects Message)
init now company user =
  let
    model = { now = now
            , company = company
            , user = convertUser user
            , team = Dict.empty
            }
  in
    (model, Effects.none)


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    Tick now ->
      pure { model | now = now }

    TimezoneChanged timezone ->
      -- FIXME: Prompt user to update timezone.
      pure model


pure : Model -> (Model, Effects Message)
pure = (flip (,) Effects.none)
