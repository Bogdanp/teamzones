port module Update exposing (init, update)

import Components.CurrentProfile as CP
import Components.Invite as Invite
import Components.Settings as Settings
import Dict exposing (Dict)
import Model exposing (..)
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), SettingsSitemap(..))
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Types exposing (..)
import User exposing (isOffline)


init : Flags -> ( Model, Cmd Msg )
init ({ path, now, company, user, team, timezones } as flags) =
    let
        route =
            Routes.match path

        currentUser =
            prepareUser user

        teamMembers =
            List.map prepareUser team

        ( currentProfile, _ ) =
            CP.init currentUser timezones

        ( model, fx ) =
            handleRoute
                { now = now
                , company = company
                , user = currentUser
                , team = groupTeam now teamMembers
                , teamMembers = teamMembers
                , timezones = timezones
                , route = route
                , invite = Invite.init
                , settings = Settings.init route (TeamR ()) currentUser teamMembers
                , currentProfile = currentProfile
                }
    in
        model ! [ fx ]


handleRoute : Model -> ( Model, Cmd Msg )
handleRoute ({ route, user, teamMembers } as model) =
    case route of
        SettingsR subRoute ->
            { model | settings = Settings.init route subRoute user teamMembers } ! []

        CurrentProfileR () ->
            let
                ( profile, fx ) =
                    CP.init model.user model.timezones
            in
                { model | currentProfile = profile } ! [ Cmd.map ToCurrentProfile fx ]

        _ ->
            model ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ now, user, team } as model) =
    case msg of
        Tick now ->
            { model | now = now } ! []

        TimezoneChanged timezone ->
            -- FIXME: Prompt user to update timezone.
            model ! []

        PathChanged path ->
            handleRoute { model | route = Routes.match path }

        RouteTo route ->
            model ! [ pushPath (Routes.route route) ]

        ToInvite msg ->
            let
                ( invite, fx ) =
                    Invite.update msg model.invite
            in
                { model | invite = invite } ! [ Cmd.map ToInvite fx ]

        ToSettings msg ->
            let
                ( settings, fx, pmsg ) =
                    Settings.update msg model.settings

                team =
                    case pmsg of
                        Just (Settings.DeleteUser email) ->
                            deleteUser email model.team

                        Nothing ->
                            model.team
            in
                { model | settings = settings, team = team } ! [ Cmd.map ToSettings fx ]

        -- (CP.RemoveAvatar) to satisfy elm-format
        ToCurrentProfile (CP.ToParent (CP.RemoveAvatar)) ->
            let
                ( user', team' ) =
                    updateUser now update user team

                update u =
                    { u | avatar = Nothing }
            in
                { model | user = user', team = team' } ! []

        ToCurrentProfile (CP.ToParent (CP.UpdateCurrentUser profile)) ->
            let
                ( user', team' ) =
                    updateUser now update user team

                update u =
                    { u
                        | name = profile.name
                        , timezone = profile.timezone
                        , workdays = profile.workdays
                    }
            in
                { model | user = user', team = team' } ! []

        ToCurrentProfile msg ->
            let
                ( currentProfile, fx ) =
                    CP.update msg model.currentProfile
            in
                { model | currentProfile = currentProfile } ! [ Cmd.map ToCurrentProfile fx ]


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


groupTeam : Timestamp -> List User -> Team
groupTeam now xs =
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
            Dict.update (key cu) (insert cu) team

        order u =
            if isOffline now u then
                1
            else
                0

        -- This sorts in reverse to account for the foldl
        sort u =
            ( order u, u.name )
    in
        List.sortBy sort xs
            |> List.reverse
            |> List.foldl group Dict.empty


updateUser : Timestamp -> (User -> User) -> User -> Team -> ( User, Team )
updateUser now f user team =
    let
        user' =
            f user

        team' =
            team
                |> Dict.toList
                |> List.concatMap (snd >> List.map update)
                |> groupTeam now

        update u =
            if u == user then
                user'
            else
                u
    in
        ( user', team' )


deleteUser : String -> Team -> Team
deleteUser email team =
    let
        remove ( k, xs ) =
            ( k, List.filter (\u -> u.email /= email) xs )
    in
        Dict.toList team
            |> List.map remove
            |> Dict.fromList
