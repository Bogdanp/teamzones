module View exposing (view)

import Components.CurrentProfile as CurrentProfile
import Components.CurrentUser as CurrentUser
import Components.Invite as Invite
import Components.Integrations as Integrations
import Components.NotFound as NotFound
import Components.Profile as Profile
import Components.Settings as Settings
import Components.Team as Team
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Model exposing (Model, Msg(..))
import Routes exposing (Sitemap(..), IntegrationsSitemap(..), SettingsSitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Company, User, AnchorTo)
import Util exposing ((=>), on')


view : Model -> Html Msg
view ({ now, company, user, team, route, invite, integrations, settings, currentProfile } as model) =
    let
        page =
            case route of
                DashboardR () ->
                    Team.view RouteTo team now

                InviteR () ->
                    Invite.view invite
                        |> Html.map ToInvite

                ProfileR _ ->
                    Profile.view

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
    in
        div [ class "app" ]
            [ toolbar company user.timezone now
            , div [ class "content" ]
                [ sidebar user
                , page
                ]
            ]


toolbar : Company -> Timezone -> Timestamp -> Html Msg
toolbar company timezone now =
    div [ class "toolbar" ]
        [ div [ class "team-name" ] [ anchorTo (DashboardR ()) [] [ text company.name ] ]
        , div [ class "clock" ] [ Util.time timezone now ]
        , div [ class "menu" ] []
        ]


sidebar : User -> Html Msg
sidebar user =
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
    in
        div [ class "sidebar" ]
            [ CurrentUser.view anchorTo user
            , ul [ class "menu" ]
                ([ routeTo (DashboardR ()) "Dashboard"
                 , routeTo (CurrentProfileR ()) "Your Profile"
                 , routeTo (IntegrationsR (GCalendarR ())) "Integrations"
                 ]
                    ++ links
                    ++ [ linkTo "/sign-out" "Sign out" ]
                )
            ]


anchorTo : AnchorTo Msg
anchorTo route attrs =
    a ([ on' "click" (RouteTo route), href (Routes.route route) ] ++ attrs)
