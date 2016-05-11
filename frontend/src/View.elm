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
import Routes exposing (Sitemap(..))
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (Company, User, AnchorTo)
import Util exposing ((=>), on')


view : Model -> Html Msg
view ({ now, company, user, team, route, invite, currentProfile } as model) =
    let
        anchorTo route attrs content =
            a
                ([ on' "click" (RouteTo route)
                 , Routes.route route |> href
                 , classList [ "active" => (route == model.route) ]
                 ]
                    ++ attrs
                )
                content

        page =
            case route of
                DashboardR () ->
                    Team.view team now

                InviteR () ->
                    lazy Invite.view invite
                        |> Html.map ToInvite

                SettingsR () ->
                    Settings.view

                CurrentProfileR () ->
                    lazy CurrentProfile.view currentProfile
                        |> Html.map ToCurrentProfile
    in
        div [ class "app" ]
            [ toolbar anchorTo company user.timezone now
            , div [ class "content" ]
                [ sidebar anchorTo user
                , page
                ]
            ]


toolbar : AnchorTo Msg -> Company -> Timezone -> Timestamp -> Html Msg
toolbar anchorTo company timezone now =
    div [ class "toolbar" ]
        [ div [ class "team-name" ] [ anchorTo (DashboardR ()) [] [ text company.name ] ]
        , div [ class "clock" ] [ Util.time timezone now ]
        , div [ class "menu" ] []
        ]


sidebar : AnchorTo Msg -> User -> Html Msg
sidebar anchorTo user =
    let
        linkTo uri label =
            li [] [ a [ href uri ] [ text label ] ]

        routeTo route label =
            li [] [ anchorTo route [] [ text label ] ]

        links =
            if user.role /= Types.Member then
                [ routeTo (InviteR ()) "Invite Teammates"
                , routeTo (SettingsR ()) "Settings"
                ]
            else
                []
    in
        div [ class "sidebar" ]
            [ CurrentUser.view anchorTo user
            , ul [ class "menu" ]
                ([ routeTo (DashboardR ()) "Dashboard" ]
                    ++ links
                    ++ [ linkTo "/sign-out" "Sign out" ]
                )
            ]
