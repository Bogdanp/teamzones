module Components.Page exposing (page, pageWithTabs)

import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap)
import Util exposing ((=>), on')


page : String -> List (Html msg) -> Html msg
page title content =
    div [ class "page" ]
        [ div [ class "page-header" ] [ h1 [] [ text title ] ]
        , div [ class "page-content" ] content
        ]


pageWithTabs : (Sitemap -> msg) -> Sitemap -> List ( Sitemap, String ) -> List (Html msg) -> Html msg
pageWithTabs f route tabs content =
    div [ class "page" ]
        [ div [ class "page-header" ]
            [ ul [ class "tabs" ] (List.map (tab f route) tabs) ]
        , div [ class "page-content" ] content
        ]


tab : (Sitemap -> msg) -> Sitemap -> ( Sitemap, String ) -> Html msg
tab f currentRoute ( route, label ) =
    li [ classList [ "active" => (currentRoute == route) ] ]
        [ a [ on' "click" (f route), href (Routes.route route) ]
            [ text label ]
        ]
