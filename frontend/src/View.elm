module View exposing (view)

import Color
import Components.CurrentProfile as CurrentProfile
import Components.CurrentUser as CurrentUser
import Components.Integrations as Integrations
import Components.Invite as Invite
import Components.Meetings as Meetings
import Components.NotFound as NotFound
import Components.Notifications as Notifications
import Components.Profile as Profile
import Components.Settings as Settings
import Components.Team as Team
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onWithOptions, onClick)
import Html.Lazy exposing (lazy)
import Icons
import Json.Decode as Json exposing ((:=))
import Model exposing (Model, Msg(..))
import Routes exposing (Sitemap(..), IntegrationsSitemap(..), SettingsSitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Company, User, AnchorTo)
import Util exposing ((=>))


view : Model -> Html Msg
view ({ now, company, user, notifications } as model) =
    div [ class "wrapper" ]
        [ Notifications.view notifications
            |> Html.map ToNotifications
        , div [ class "app" ]
            [ toolbar company user.timezone now
            , div [ class "content" ]
                [ sidebar model
                , lazy page model
                ]
            ]
        ]


page : Model -> Html Msg
page ({ now, route, team, invite, profile, meetings, integrations, settings, currentProfile } as model) =
    case route of
        DashboardR () ->
            Team.view RouteTo team now

        InviteR () ->
            Invite.view invite
                |> Html.map ToInvite

        ProfileR _ ->
            Profile.view profile
                |> Html.map ToProfile

        MeetingsR () ->
            Meetings.view meetings
                |> Html.map ToMeetings

        IntegrationsR _ ->
            Integrations.view integrations
                |> Html.map ToIntegrations

        SettingsR _ ->
            Settings.view settings
                |> Html.map ToSettings

        CurrentProfileR () ->
            CurrentProfile.view currentProfile
                |> Html.map ToCurrentProfile

        NotFoundR ->
            NotFound.view


toolbar : Company -> Timezone -> Timestamp -> Html Msg
toolbar company timezone now =
    div [ class "toolbar" ]
        [ div [ class "team-name" ]
            [ a
                [ href "javascript:;"
                , class "sidebar-toggle"
                , onClick ToggleSidebar
                ]
                [ Icons.menu Color.black 20 ]
            , anchorTo (DashboardR ()) [ class "logo" ] [ text company.name ]
            ]
        , div [ class "clock" ] [ Util.time timezone now ]
        , div [ class "menu" ]
            [ ul []
                [ li []
                    [ a [ href "mailto:support@teamzones.io" ]
                        [ Icons.chat Color.black 20
                        ]
                    ]
                ]
            ]
        ]


sidebar : Model -> Html Msg
sidebar { user, sidebarHidden, sidebarTouching, sidebarOffsetX } =
    let
        linkTo uri label =
            li [] [ a [ href uri ] [ text label ] ]

        routeTo route label =
            li [] [ anchorTo route [] [ text label ] ]

        links =
            if user.role /= Types.Member then
                [ routeTo (InviteR ()) "Invite Teammates"
                , routeTo (SettingsR (TeamR ())) "Settings"
                ]
            else
                []

        touches =
            Json.at [ "touches", "0" ] ("pageX" := Json.float)

        on =
            flip onWithOptions
                { stopPropagation = True
                , preventDefault = False
                }

        onTouchStart =
            on "touchstart" (Json.map TouchSidebarStart touches)

        onTouchMove =
            on "touchmove" (Json.map TouchSidebarMove touches)

        onTouchEnd =
            on "touchend" (Json.succeed TouchSidebarEnd)
    in
        div
            [ classList
                [ "sidebar" => True
                , "animating" => sidebarTouching
                , "hidden" => sidebarHidden
                , "shown" => not sidebarHidden
                ]
            , onTouchStart
            , onTouchMove
            , onTouchEnd
            , style
                (if sidebarTouching then
                    [ "margin-left" => (toString sidebarOffsetX ++ "px") ]
                 else
                    []
                )
            ]
            [ CurrentUser.view anchorTo user
            , ul [ class "menu" ]
                ([ routeTo (DashboardR ()) "Dashboard"
                 , routeTo (MeetingsR ()) "Meetings"
                 , routeTo (CurrentProfileR ()) "Your Profile"
                 , routeTo (IntegrationsR (GCalendarR ())) "Integrations"
                 ]
                    ++ links
                    ++ [ linkTo "/sign-out" "Sign out" ]
                )
            ]


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
