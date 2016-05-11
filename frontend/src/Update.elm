port module Update exposing (init, update)

import Components.CurrentProfile as CurrentProfile exposing (ParentMessage(..))
import Components.Invite as Invite
import Dict exposing (Dict)
import Model exposing (..)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Types exposing (..)
import Util exposing (pure)


init : Flags -> ( Model, Cmd Message )
init { path, now, company, user, team } =
    let
        currentUser =
            prepareUser user

        -- TODO: Only run the effects if the route matches current profile?
        ( currentProfile, currentProfileFx ) =
            CurrentProfile.init currentUser
    in
        ( { now = now
          , company = company
          , user = currentUser
          , team = prepareTeam team
          , route = Routes.match path
          , invite = Invite.init
          , currentProfile = currentProfile
          }
        , Cmd.batch
            [ Cmd.map ToCurrentProfile currentProfileFx
            ]
        )


update : Message -> Model -> ( Model, Cmd Message )
update message ({ user, team } as model) =
    case message of
        NoOp ->
            pure model

        Tick now ->
            pure { model | now = now }

        TimezoneChanged timezone ->
            -- FIXME: Prompt user to update timezone.
            pure model

        PathChanged path ->
            let
                route =
                    Routes.match path

                model' =
                    { model | route = route }
            in
                case route of
                    CurrentProfileR () ->
                        let
                            ( profile, fx ) =
                                CurrentProfile.init model.user
                        in
                            ( { model' | currentProfile = profile }
                            , Cmd.map ToCurrentProfile fx
                            )

                    _ ->
                        pure model'

        RouteTo route ->
            ( model
            , setPath (Routes.route route)
            )

        ToInvite message ->
            let
                ( invite, fx ) =
                    Invite.update message model.invite
            in
                ( { model | invite = invite }
                , Cmd.map ToInvite fx
                )

        ToCurrentProfile (CurrentProfile.ToParent RemoveAvatar) ->
            let
                user' =
                    { user | avatar = Nothing }

                team' =
                    Dict.map (always <| List.map update) team

                update u =
                    if u == user then
                        user'
                    else
                        u
            in
                pure { model | user = user', team = team' }

        ToCurrentProfile message ->
            let
                ( currentProfile, fx ) =
                    CurrentProfile.update message model.currentProfile
            in
                ( { model | currentProfile = currentProfile }
                , Cmd.map ToCurrentProfile fx
                )


prepareUser : ContextUser -> User
prepareUser u =
    let
        role r =
            if r == "main" then
                Main
            else if r == "manager" then
                Manager
            else
                Member

        avatar a =
            if a == "" then
                Nothing
            else
                Just a
    in
        User (role u.role) u.name u.email (avatar u.avatar) u.timezone u.workdays


prepareTeam : List ContextUser -> Team
prepareTeam xs =
    let
        key u =
            ( u.timezone, Timestamp.offset u.timezone )

        insert u mxs =
            case mxs of
                Nothing ->
                    Just [ u ]

                Just xs ->
                    Just (u :: xs)

        group cu team =
            Dict.update (key cu) (insert <| prepareUser cu) team
    in
        List.foldl group Dict.empty xs


port setPath : String -> Cmd msg
