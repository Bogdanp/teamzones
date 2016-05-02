module Update (init, update) where

import Dict
import Effects exposing (Effects)
import History
import Task

import Routes
import Timestamp exposing (Timestamp)
import Types exposing (..)


init : String -> Timestamp -> Company -> ContextUser -> (Model, Effects Message)
init path now company user =
  pure { now = now
       , company = company
       , user = convertUser user
       , team = Dict.empty
       , route = Routes.match path
       }


update : Message -> Model -> (Model, Effects Message)
update message model =
  case message of
    NoOp ->
      pure model

    Tick now ->
      pure { model | now = now }

    TimezoneChanged timezone ->
      -- FIXME: Prompt user to update timezone.
      pure model

    PathChanged path ->
      pure { model | route = Routes.match path }

    RouteTo route ->
      ( model
      , Routes.route route
          |> History.setPath
          |> Task.toMaybe
          |> Task.map (always NoOp)
          |> Effects.task
      )


pure : Model -> (Model, Effects Message)
pure = (flip (,) Effects.none)


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
