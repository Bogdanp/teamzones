module Components.Settings exposing (Model, Msg, ParentMsg(..), init, update, view)

import Components.Page exposing (pageWithTabs)
import Components.Settings.Billing as Billing
import Components.Settings.Team as Team
import Html exposing (..)
import Html.App as Html
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), SettingsSitemap(..))
import Types exposing (User)


type ParentMsg
    = DeleteUser String


type Msg
    = RouteTo Sitemap
    | ToTeam Team.Msg


type alias Model =
    { fullRoute : Sitemap
    , subRoute : SettingsSitemap
    , teamMembers : List User
    , team : Team.Model
    }


init : Sitemap -> SettingsSitemap -> User -> List User -> Model
init fullRoute subRoute currentUser teamMembers =
    Model fullRoute subRoute teamMembers (Team.init currentUser teamMembers)


update : Msg -> Model -> ( Model, Cmd Msg, Maybe ParentMsg )
update msg ({ team } as model) =
    case msg of
        RouteTo route ->
            ( model, pushPath (Routes.route route), Nothing )

        ToTeam msg ->
            let
                ( team, fx, pmsg ) =
                    Team.update msg team

                parentMsg =
                    Maybe.map
                        (\pmsg ->
                            case pmsg of
                                Team.DeleteUser email ->
                                    DeleteUser email
                        )
                        pmsg
            in
                ( { model | team = team }, Cmd.map ToTeam fx, parentMsg )


view : Model -> Html Msg
view ({ fullRoute, subRoute, team } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( SettingsR (TeamR ()), "Team" )
        , ( SettingsR (BillingR ()), "Billing" )
        ]
        [ case subRoute of
            BillingR () ->
                Billing.view

            TeamR () ->
                Team.view team
                    |> Html.map ToTeam
        ]
