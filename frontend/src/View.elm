module View exposing (view)

import Components.CurrentProfile as CurrentProfile
import Components.CurrentUser as CurrentUser
import Components.Invite as Invite
import Components.Settings as Settings
import Components.Team as Team
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)
import Model exposing (Model, Msg(..))
import Routes exposing (Sitemap(..), SettingsMap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Company, User, AnchorTo)
import Util exposing ((=>), on')


view : Model -> Html Msg
view ({ now, company, user, team, route, invite, settings, currentProfile } as model) =
    let
        page =
            case route of
                DashboardR () ->
                    Team.view team now

                InviteR () ->
                    lazy Invite.view invite
                        |> Html.map ToInvite

                SettingsR _ ->
                    lazy Settings.view settings
                        |> Html.map ToSettings

                CurrentProfileR () ->
                    lazy CurrentProfile.view currentProfile
                        |> Html.map ToCurrentProfile
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
                 ]
                    ++ links
                    ++ [ linkTo "/sign-out" "Sign out" ]
                )
            ]


anchorTo : AnchorTo Msg
anchorTo route attrs =
    a ([ on' "click" (RouteTo route), href (Routes.route route) ] ++ attrs)
