module Update (init, update) where

import Dict exposing (Dict)
import Effects exposing (Effects)
import History
import Task

import Model exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Types exposing (..)
import Util exposing (pure)

import Components.CurrentProfile as CurrentProfile
import Components.Invite as Invite


init : String
     -> Timestamp
     -> Company
     -> ContextUser
     -> List ContextUser
     -> (Model, Effects Message)
init path now company user team =
  pure { now = now
       , company = company
       , user = prepareUser user
       , team = prepareTeam team
       , route = Routes.match path
       , invite = Invite.init
       , currentProfile = CurrentProfile.init
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

    ToInvite message ->
      let
        (invite, fx) = Invite.update message model.invite
      in
        ( { model | invite = invite }
        , Effects.map ToInvite fx
        )

    ToCurrentProfile message ->
      let
        (currentProfile, fx) = CurrentProfile.update message model.currentProfile
      in
        ( { model | currentProfile = currentProfile }
        , Effects.map ToCurrentProfile fx
        )


prepareUser : ContextUser -> User
prepareUser u =
  let
    role r =
      case r of
        "main" -> Main
        "manager" -> Manager
        _ -> Member

    avatar a =
      if a == "" then
        Nothing
      else
        Just a
  in
    User (role u.role) u.name u.email (avatar u.avatar) u.timezone


prepareTeam : List ContextUser -> Team
prepareTeam xs =
  let
    key u =
      (u.timezone, Timestamp.offset u.timezone)

    insert u mxs =
      case mxs of
        Nothing ->
          Just [u]

        Just xs ->
          Just (u :: xs)

    group cu team =
      Dict.update (key cu) (insert <| prepareUser cu) team
  in
    List.foldl group Dict.empty xs
