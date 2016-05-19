module Components.Integrations exposing (Model, Msg, init, update, view)

import Components.Integrations.GCalendar as GCalendar
import Components.Page exposing (pageWithTabs)
import Html exposing (..)
import Ports exposing (pushPath)
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Types exposing (User)


type Msg
    = RouteTo Sitemap


type alias Context =
    { fullRoute : Sitemap
    , subRoute : Maybe IntegrationsSitemap
    , currentUser : User
    }


type alias Model =
    { fullRoute : Sitemap
    , subRoute : IntegrationsSitemap
    , currentUser : User
    }


init : Context -> Model
init { fullRoute, subRoute, currentUser } =
    Model fullRoute (Maybe.withDefault (GCalendarR ()) subRoute) currentUser


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            ( model, pushPath (Routes.route route) )


view : Model -> Html Msg
view ({ fullRoute, subRoute } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ ( IntegrationsR (GCalendarR ()), "Google Calendar" )
        ]
        [ case subRoute of
            GCalendarR () ->
                GCalendar.view
        ]
