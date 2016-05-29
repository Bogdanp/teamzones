port module Update exposing (init, update, urlUpdate)

import Components.CurrentProfile as CP
import Components.Invite as Invite
import Components.Integrations as Integrations
import Components.Notifications as Notifications
import Components.Profile as Profile
import Components.Settings as Settings
import Dict exposing (Dict)
import Model exposing (..)
import Routes exposing (Sitemap(..), IntegrationsSitemap(..), SettingsSitemap(..))
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Types exposing (..)
import User exposing (isOffline)


init : Flags -> Sitemap -> ( Model, Cmd Msg )
init ({ now, suspended, company, user, team, timezones, integrationStates, viewportWidth } as flags) route =
    let
        currentUser =
            prepareUser user

        teamMembers =
            List.map prepareUser team

        ( integrations, _ ) =
            Integrations.init
                { fullRoute = route
                , subRoute = Nothing
                , currentUser = currentUser
                , integrationStates = integrationStates
                }

        ( settings, _ ) =
            Settings.init
                { deleteUser = DeleteUser
                , fullRoute = route
                , subRoute = Nothing
                , currentUser = currentUser
                , teamMembers = teamMembers
                }

        ( currentProfile, _ ) =
            CP.init currentUser timezones

        ( model, fx ) =
            urlUpdate route
                { now = now
                , suspended = suspended
                , company = company
                , user = currentUser
                , team = groupTeam now teamMembers
                , teamMembers = teamMembers
                , timezones = timezones
                , integrationStates = integrationStates
                , route = route
                , invite = Invite.init
                , profile =
                    { now = now
                    , user = currentUser
                    , currentUser = currentUser
                    }
                , integrations = integrations
                , settings = settings
                , currentProfile = currentProfile
                , notifications = Notifications.init
                , sidebarHidden = viewportWidth <= 375
                }
    in
        model ! [ fx ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ now, user, team, teamMembers, notifications } as model) =
    case msg of
        Tick now ->
            { model | now = now, team = groupTeam now teamMembers } ! []

        TimezoneChanged timezone ->
            -- FIXME: Prompt user to update timezone.
            model ! []

        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        Notified notification ->
            let
                ( xs, fx ) =
                    Notifications.append notification notifications
            in
                { model | notifications = xs } ! [ Cmd.map ToNotifications fx ]

        ToInvite msg ->
            let
                ( invite, fx ) =
                    Invite.update msg model.invite
            in
                { model | invite = invite } ! [ Cmd.map ToInvite fx ]

        ToProfile msg ->
            let
                ( profile, fx ) =
                    Profile.update msg model.profile
            in
                { model | profile = profile } ! [ Cmd.map ToProfile fx ]

        ToIntegrations msg ->
            let
                ( integrations, fx ) =
                    Integrations.update msg model.integrations
            in
                { model
                    | integrations = integrations
                    , integrationStates = integrations.integrationStates
                }
                    ! [ Cmd.map ToIntegrations fx ]

        ToSettings msg ->
            let
                ( settings, fx, pmsg ) =
                    Settings.update msg model.settings

                ( teamMembers, team ) =
                    case pmsg of
                        Just (DeleteUser email) ->
                            deleteUser email model.teamMembers model.team

                        Nothing ->
                            ( model.teamMembers, model.team )
            in
                { model | settings = settings, team = team, teamMembers = teamMembers }
                    ! [ Cmd.map ToSettings fx ]

        ToCurrentProfile (CP.ToParent (CP.RemoveAvatar)) ->
            let
                ( user', team', teamMembers' ) =
                    updateUser now update user team

                update u =
                    { u | avatar = Nothing, smallAvatar = Nothing }
            in
                { model | user = user', team = team', teamMembers = teamMembers' } ! []

        ToCurrentProfile (CP.ToParent (CP.UpdateCurrentUser profile)) ->
            let
                ( user', team', teamMembers' ) =
                    updateUser now update user team

                update u =
                    { u
                        | firstName = profile.firstName
                        , lastName = profile.lastName
                        , fullName = profile.firstName ++ " " ++ profile.lastName
                        , timezone = profile.timezone
                        , workdays = profile.workdays
                    }
            in
                { model | user = user', team = team', teamMembers = teamMembers' } ! []

        ToCurrentProfile msg ->
            let
                ( currentProfile, fx ) =
                    CP.update msg model.currentProfile
            in
                { model | currentProfile = currentProfile } ! [ Cmd.map ToCurrentProfile fx ]

        ToNotifications msg ->
            let
                ( notifications, fx ) =
                    Notifications.update msg model.notifications
            in
                { model | notifications = notifications } ! [ Cmd.map ToNotifications fx ]

        ToggleSidebar ->
            { model | sidebarHidden = not model.sidebarHidden } ! []


urlUpdate : Sitemap -> Model -> ( Model, Cmd Msg )
urlUpdate route ({ now, suspended, user, teamMembers, integrationStates } as m) =
    let
        model =
            { m | route = route }

        billingR =
            SettingsR (BillingR ())
    in
        if suspended && route /= billingR then
            model ! [ Routes.navigateTo billingR ]
        else
            case route of
                ProfileR email ->
                    case findUser teamMembers email of
                        Just profileUser ->
                            { model
                                | profile =
                                    { now = now
                                    , user = profileUser
                                    , currentUser = user
                                    }
                            }
                                ! []

                        Nothing ->
                            { model | route = NotFoundR } ! []

                IntegrationsR subRoute ->
                    let
                        ( integrations, fx ) =
                            Integrations.init
                                { fullRoute = route
                                , subRoute = Just subRoute
                                , currentUser = user
                                , integrationStates = integrationStates
                                }
                    in
                        { model | integrations = integrations }
                            ! [ Cmd.map ToIntegrations fx ]

                SettingsR subRoute ->
                    let
                        ( settings, fx ) =
                            Settings.init
                                { deleteUser = DeleteUser
                                , fullRoute = route
                                , subRoute = Just subRoute
                                , currentUser = user
                                , teamMembers = teamMembers
                                }
                    in
                        { model | settings = settings } ! [ Cmd.map ToSettings fx ]

                CurrentProfileR () ->
                    let
                        ( profile, fx ) =
                            CP.init model.user model.timezones
                    in
                        { model | currentProfile = profile } ! [ Cmd.map ToCurrentProfile fx ]

                _ ->
                    model ! []


findUser : List User -> String -> Maybe User
findUser teamMembers email =
    List.filter ((==) email << .email) teamMembers
        |> List.head


prepareUser : ContextUser -> User
prepareUser ctx =
    let
        role =
            if ctx.role == "main" then
                Main
            else if ctx.role == "manager" then
                Manager
            else
                Member

        maybeFromZero s =
            if s == "" then
                Nothing
            else
                Just s

        avatar =
            maybeFromZero ctx.avatar

        smallAvatar =
            maybeFromZero ctx.smallAvatar
    in
        { role = role
        , firstName = ctx.firstName
        , lastName = ctx.lastName
        , fullName = ctx.firstName ++ " " ++ ctx.lastName
        , email = ctx.email
        , avatar = avatar
        , smallAvatar = smallAvatar
        , timezone = ctx.timezone
        , workdays = ctx.workdays
        }


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
            ( order u, u.fullName )
    in
        List.sortBy sort xs
            |> List.reverse
            |> List.foldl group Dict.empty


updateUser : Timestamp -> (User -> User) -> User -> Team -> ( User, Team, List User )
updateUser now f user team =
    let
        user' =
            f user

        teamMembers =
            team
                |> Dict.toList
                |> List.concatMap (snd >> List.map update)

        team' =
            groupTeam now teamMembers

        update u =
            if u == user then
                user'
            else
                u
    in
        ( user', team', teamMembers )


deleteUser : String -> List User -> Team -> ( List User, Team )
deleteUser email teamMembers team =
    let
        remove ( k, xs ) =
            ( k, List.filter (\u -> u.email /= email) xs )

        team' =
            Dict.toList team
                |> List.map remove
                |> Dict.fromList
                |> Dict.filter (\_ xs -> not (List.isEmpty xs))

        teamMembers' =
            Dict.toList team
                |> List.concatMap snd
    in
        ( teamMembers', team' )
