port module Update exposing (init, update)

import Components.CurrentProfile as CP
import Components.Invite as Invite
import Dict exposing (Dict)
import Model exposing (..)
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Types exposing (..)


init : Flags -> ( Model, Cmd Msg )
init { path, now, company, user, team, timezones } =
    let
        currentUser =
            prepareUser user

        -- TODO: Only run the effects if the route matches current profile?
        ( currentProfile, currentProfileFx ) =
            CP.init currentUser timezones
    in
        ( { now = now
          , company = company
          , user = currentUser
          , team = prepareTeam team
          , timezones = timezones
          , route = Routes.match path
          , invite = Invite.init
          , currentProfile = currentProfile
          }
        , Cmd.batch
            [ Cmd.map ToCurrentProfile currentProfileFx
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ user, team } as model) =
    case msg of
        NoOp ->
            model ! []

        Tick now ->
            { model | now = now } ! []

        TimezoneChanged timezone ->
            -- FIXME: Prompt user to update timezone.
            model ! []

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
                                CP.init model.user model.timezones
                        in
                            { model' | currentProfile = profile } ! [ Cmd.map ToCurrentProfile fx ]

                    _ ->
                        model' ! []

        RouteTo route ->
            ( model
            , pushPath (Routes.route route)
            )

        ToInvite msg ->
            let
                ( invite, fx ) =
                    Invite.update msg model.invite
            in
                { model | invite = invite } ! [ Cmd.map ToInvite fx ]

        ToCurrentProfile (CP.ToParent CP.RemoveAvatar) ->
            let
                ( user', team' ) =
                    updateUser update user team

                update u =
                    { u | avatar = Nothing }
            in
                { model | user = user', team = team' } ! []

        ToCurrentProfile (CP.ToParent (CP.UpdateCurrentUser profile)) ->
            let
                ( user', team' ) =
                    updateUser update user team

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


groupTeam : List User -> Team
groupTeam xs =
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
    in
        List.sortBy .name xs
            |> List.foldl group Dict.empty


prepareTeam : List ContextUser -> Team
prepareTeam =
    List.map prepareUser
        >> groupTeam


updateUser : (User -> User) -> User -> Team -> ( User, Team )
updateUser f user team =
    let
        user' =
            f user

        team' =
            team
                |> Dict.toList
                |> List.concatMap (snd >> List.map update)
                |> groupTeam

        update u =
            if u == user then
                user'
            else
                u
    in
        ( user', team' )
